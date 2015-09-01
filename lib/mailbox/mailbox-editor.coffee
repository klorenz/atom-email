{Emitter, CompositeDisposable} = require 'atom'
Q = require 'q'

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

    @setSortType('descending')
    @setSortBy('sentDate')

  setSortType: (@sortType) ->
    @emitter.emit 'did-change-sort-type', @sortType

  setSortBy: (@sortBy) ->
    @emitter.emit 'did-change-sort-by', @sortBy

  getSortBy: -> @sortBy
  getSortType: -> @sortType



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

    @imap.getMailbox()
    .then (mailbox) =>
      @mailbox = mailbox
      mailbox.onDidStartGetMessages (messages, options) =>
        @emitter.emit 'did-start-get-messages', messages, options
      mailbox.onDidProgressGetMessages (messages, options) =>
        {fetchedMessages} = options
        for msg in fetchedMessages
          msg.filterKey = "#{msg.date} #{msg.from} #{msg.subject}"
        @emitter.emit 'did-progress-get-messages', messages, options
      mailbox.onDidEndGetMessages (messages, options) =>
        @emitter.emit 'did-end-get-messages', messages, options
      mailbox.onError (error) =>
        p = path or ""

        if error
          atom.notifications.addError "Error in communcation with mailbox #{configName}/#{p}",
            detail: "#{error}", stack: error.stack, dismissable: true
        else
          atom.notifications.addError "Error in communcation with mailbox #{configName}/#{p}",
            detail: "Maybe close this mailbox and reopen", dismissable: true

        # reconnect?


      mailbox.onDidSelectMailbox (path, info) =>
        @emitter.emit 'did-select-mailbox', {path, info}

      mailbox.selectMailbox(path).then =>
        mailbox.getAllMessages()

      #@emitter.emit 'did-select-mailbox', mailbox.path, mailbox.info
    .fail (error) =>
      atom.notifications.addError "Error opening mailbox #{configName}",
        detail: "#{error}", stack: error.stack, dismissable: true

  displayMessage: (item) ->
    #@mailbox.getMessageBody(item.uid).then (messages) =>
    @emitter.emit 'did-request-display-message', item

  getMessageBodyParts: (message, parts=null)  ->
    @mailbox.getMessageBodyParts message, parts

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

  onDidRequestDisplayMessage: (callback) ->
    @emitter.on 'did-request-display-message', callback

module.exports = {MailboxEditor}
