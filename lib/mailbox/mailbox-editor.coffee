{Emitter, CompositeDisposable} = require 'atom'
Q = require 'q'
{makeLabel} = require '../utils.coffee'
{extend} = require 'underscore'
CSON = require 'season'


makeAddrString = (value) ->
  return value if typeof value is "string"

  makeAddr = (o) ->
    if o.name
      return "#{o.name} <#{o.address}>"
    else
      return o.address

  if value instanceof Array
    (makeAddr(o) for o in value).join(", ")
  else
    makeAddr value

# Public: Mailbox editor
#
#
class MailboxEditor
# Public:

  constructor: (@options={}) ->
    # promise for logged in imap connection
    @mailtool = require '../mail-tool'
    @imap = @mailtool.getImapConnection @options
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @mailbox = null
    @message = null  # active message
    @messages = null  # active message
    @actionScope = 'one'
    @filterType = 'regex-i'
    @readTimeout = 4000
    @prefer = ['html', 'text']

    @imap.onDidUpdateMailboxes (mailboxes) =>
      @emitter.emit 'did-update-mailboxes', mailboxes

    @imap.getMailboxes().then (mailboxes) =>
      @emitter.emit 'did-update-mailboxes', mailboxes

    addCommand = (cmd, callback) =>
      console.log "add command", cmd, callback
      @subscriptions.add atom.commands.add "mailbox-editor", cmd, callback

    addFlagCommands = (name, valName=null) =>
      valName = name unless valName
      setFlag = {}
      setFlag[valName] = true
      unsetFlag = {}
      unsetFlag[valName] = false

      addCommand "message:mark-as-#{name}",        => @setFlags setFlag
      addCommand "message:mark-as-not-#{name}",    => @setFlags unsetFlag
      addCommand "message:mark-as-un#{name}",      => @setFlags unsetFlag

      addCommand "all-filtered-messages:mark-as-#{name}", =>
        @setFlags setFlag, filtered: true
      addCommand "all-filtered-messages:mark-as-not-deleted", =>
        @setFlags unsetFlag, filtered: false
      addCommand "all-filtered-messages:mark-as-undeleted", =>
        @setFlags unsetFlag, filtered: false

    addFlagCommands "seen"
    addFlagCommands "read", "seen"
    addFlagCommands "deleted"
    addFlagCommands "flagged"
    addFlagCommands "starred", "flagged"
    addFlagCommands "important", "flagged"

    addCommand "message:star", => @setFlags {flagged: true}
    addCommand "message:unstar", => @setFlags {flagged: false}
    addCommand "all-filtered-messages:star", => @setFlags {flagged: true}
    addCommand "all-filtered-messages:unstar", => @setFlags {flagged: false}

    addCommand "mailbox:write-new-mail",   => @newMail()
    addCommand "mailbox:expunge",       =>
      atom.notifications.addWarning "Not Implemented yet :("
    addCommand "message:reply",     => @reply()
    addCommand "message:reply-all", => @replyAll()
    addCommand "message:forward",   => @forward()
    addCommand "message:forward-as-attachment", =>
      atom.notifications.addWarning "Not Implemented yet :("
      #@forwardAsAttachment()

    addCommand "all-filtered-messages:reply", =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:reply-all", =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:forward",   =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:mark-as-read",   =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:mark-as-seen",   =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:mark-as-junk",   =>
      atom.notifications.addInfo "Not Implemented yet :("
    addCommand "all-filtered-messages:mark-as-non-junk",   =>
      atom.notifications.addInfo "Not Implemented yet :("

    @setSortType('descending')
    @setSortField('sent')

  setActionScope: (actionScope) ->
    if actionScope != @actionScope
      @actionScope = actionScope
      @emitter.emit 'did-change-action-scope', @actionScope

  getActionScope: -> @actionScope

  toggleActionScope: ->
    actionScope = if @actionScope == 'one' then 'one' else 'many'
    @setActionScope actionScope

  setSortType: (@sortType) ->
    @emitter.emit 'did-change-sort-type', @sortType

  setSortField: (@sortField) ->
    @emitter.emit 'did-change-sort-field', @sortField

  getSortField: -> @sortField

  getSortType: -> @sortType

  setFilter: (@filter) ->

  setFilterType: (@filterType) ->
    @emitter.emit 'did-change-filter-type', @filterType

  getFilterType: -> @filterType


  # Essential: Opens a mailbox using underlying imap connection
  #
  # path - path of mailbox
  #
  # Examples
  #
  #    mailboxEditor.openMailbox("INBOX").then (mailbox) =>
  #       # connect to mailbox events
  #
  # Returns a promise to a mailbox object.
  openMailbox: (path) ->
    configName = @imap.options.configName
    debugger

    @imap.getMailbox()
    .then (mailbox) =>
      @mailbox = mailbox
      mailbox.onDidStartGetMessages (messages, options) =>
        @emitter.emit 'did-start-get-messages', messages, options

      mailbox.onDidProgressGetMessages (messages, options) =>
        {fetchedMessages} = options

        if fetchedMessages
          # for msg in fetchedMessages
          #   msg.filterKey = "#{msg.date} #{msg.from} #{msg.subject}"
          @emitter.emit 'did-progress-get-messages', messages, options

      mailbox.onDidEndGetMessages (messages, options) =>
        @emitter.emit 'did-end-get-messages', messages, options

      mailbox.onError (error) =>
        p = path or ""

        if error
          atom.notifications.addError "Error in communcation with mailbox #{configName}/#{p}",
            detail: "#{error}", stack: error.stack, dismissable: true
        else
          console.log "try to reconnect"
          @mailbox = null

          @openMailbox path

      mailbox.onDidSelectMailbox (path, info) =>
        mailbox.updateMessages()
        @emitter.emit 'did-select-mailbox', {path, info}

      mailbox.selectMailbox(path)

      #@emitter.emit 'did-select-mailbox', mailbox.path, mailbox.info
    .fail (error) =>
      atom.notifications.addError "Error opening mailbox #{configName}",
        detail: "#{error}", stack: error.stack, dismissable: true

  selectMessage: (message) ->
    if @currentSeenTimeout?
      clearTimeout @currentSeenTimeout
      @currentSeenTimeout = null

    for preferred in @prefer
      neededParts = message.getBodyPartsForType preferred
      break if neededParts.length

    @getMessageBodyParts(message, neededParts).then (parts) =>
      message.updateBodyParts(parts)
      @message = message
      @emitter.emit 'did-select-message', @message



    # @currentTimeout = setTimeout =>
    #   @mailbox.setFlags(message.uid, seen: true).then =>
    #     message.flags.seen = true
    #     @emitter.emit 'did-update-message', message
    #   .reject (error) =>
    #     atom.notifications.addError "Error setting seen state",
    #       detail: "#{error}", stack: error.stack, dismissable: true
    # , @readTimeout

  setFlags: (flags, {filtered}={}) ->
    if filtered
      uids = (m.uid for m in @messages)
      needUpdate = @messages
    else
      uids = [@message.uid]
      needUpdate = [@message]

    @mailbox.setFlags(uids, flags).then =>
      for m in needUpdate
        extend m.flag, flags
      @emitter.emit 'did-update-messages', needUpdate
    .catch (error) =>
      atom.notifications.addError "Error setting flags "+CSON.stringify(flags),
        detail: "#{error}", stack: error.stack, dismissable: true

  selectMessages: (@messages) ->
    @emitter.emit 'did-select-messages', @messages

  showMailboxSelector: ->
    @emitter.emit 'did-request-show-mailbox-selector', null

  getMessageBodyParts: (message, parts=null)  ->
    @mailbox.getMessageBodyParts message, parts

  getMailboxes: ->
    @imap.getMailboxes()

  selectMailbox: (path) ->
    @mailbox.selectMailbox(path)
    # @setActiveMessage()

  reply: ({filtered}={}) ->
    message.reply {@mailbox}, (error, options) =>
      @openMessageEditor options

  replyAll: (message=@message) ->
    message.replyAll {@mailbox}, (error, options) =>
      @openMessageEditor options

  forward: (message=@message, options={}) ->
    message.forward extend(options, {@mailbox}), (error, options) =>
      @openMessageEditor options

  forwardAsAttachment: (message=@message, options={}) ->
    message.forwardAsAttachment extend(options, {@mailbox}), (error, options) =>
      @openMessageEditor options

  newMail: (options={}) ->
    @openMessageEditor options

  openMessageEditor: (options) ->
    now = new Date().toISOString().replace(/\..*$/, '').replace(/T/, " ")
    {composed} = options

    if composed.subject
      title = options.subject
    else if composed.to
      title = "Mail to #{composed.to}"
    else
      title = "Compose Mail"

    title += " (#{now})"

    atom.workspace.open(title)
    .then (texteditor) =>
      content = ""
      i = 2
      for n,v of composed
        continue if n is 'content'
        continue if n is 'attachment'
        content += makeLabel(n, 8) + ": ${#{i}:" + makeAddrString(v) + "}\n"
        i += 1

      # if is vim, switch to insert mode
      if vim = atom.packages.getActivePackage('vim-mode')
        vim.mainModule.getEditorState(texteditor).activateInsertMode()

      if 'to' not of composed
        content += "To      : ${#{i}}\n"
        i += 1

      if 'cc' not of composed
        content += "Cc      : ${#{i}}"

      if 'subject' not of composed
        content += "Subject : ${#{i}}\n"
        i += 1

      composedContent = composed.content ? ''

      content += "\n\n${0:${1:<tab> for next field or <esc> for exiting snippet}}\n#{composedContent}"

      snippets = atom.packages.getActivePackage('snippets').mainModule
      snippets.insert content, texteditor

    .catch (error) =>
      atom.notifications.addError "Error Editing Mail", detail: "#{error}\n\n"+JSON.stringify(options), stack: error.stack, dismissable: true

  ###
  Section: Event Subscriptions
  ###

  # Essential: Calls your callback, if mailbox is selected
  #
  # * `callback` {Function}
  #   * `path` - path of selected mailbox
  #   * `info` - info of selected Mailbox
  #
  # Returns a {Disposable}
  onDidSelectMailbox: (callback) ->
    @emitter.on 'did-select-mailbox', callback

  onDidStartGetMessages: (callback) ->
    @emitter.on 'did-start-get-messages', callback

  onDidProgressGetMessages: (callback) ->
    @emitter.on 'did-progress-get-messages', callback

  onDidEndGetMessages: (callback) ->
    @emitter.on 'did-end-get-messages', callback

  onDidSelectMessage: (callback) ->
    @emitter.on 'did-select-message', callback

  onDidSelectMessages: (callback) ->
    @emitter.on 'did-select-message', callback

  onDidRequestShowMailboxSelector: (callback) ->
    @emitter.on 'did-request-show-mailbox-selector', callback

  onDidGetMailboxes: (callback) ->
    @emitter.on 'did-get-mailboxes', callback

  onDidChangeActionScope: (callback) ->
    @emitter.on 'did-change-action-scope', callback

  onDidChangeSortType: (callback) ->
    @emitter.on 'did-change-sort-type', callback

  onDidChangeSortField: (callback) ->
    @emitter.on 'did-change-sort-field', callback

  onDidChangeFilterType: (callback) ->
    @emitter.on 'did-change-filter-type', callback

  onDidUpdateMessages: (callback) ->
    @emitter.on 'did-update-messages', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  destroy: ->
    debugger
    console.log "mailbox editor destroy"
    @emitter.emit 'did-destroy', this
    if @mailbox?
      @mailbox.close()

module.exports = {MailboxEditor}
