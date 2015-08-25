{Emitter, CompositeDisposable} = require 'atom'
Q = require 'q'

# model
class MailboxEditor

  constructor: (@options={}) ->

    # promise for logged in imap connection
    @mailtool = require '../mail-tool'

    # @mailbox = @mailtool.openMailbox @options
    # @mailbox.selectFolder(@options.path).then =>
    #   @mailbox.getMessages
    #     onNextMessages: (msgs) =>

    # imap = @mailtool.getImapConnection(@options)
    # @imap = Q.Promise (resolve) =>
    #   imap.login().then => resolve(imap)

    # promise for lost of folders
    #@folders = @getMailboxFolders()

    # promise for path of current folder
    # @selectedFolder = Q.Promise (resolve) =>
    #   if @options.path
    #     resolve @options.path
    #   else
    #     @folders.then() (folders) =>
    #       debugger
    #       console.log folders
    #
    # @messages = {}
    #

  # selectFolder: (folder) ->
  #   @selectedFolder = Q(folder)
  #
  # getMailboxFolders: () ->
  #   Q.Promise (resolve) =>
  #     @imap.then (imap) =>
  #       imap.listWellKnownFolders().then (folderInfo) =>
  #         resolve(folderInfo)
  #
  # listMessages: () ->
  #   Q.Promise (resolve) =>
  #     @selectedFolder.then (folder) =>
  #       if folder of @messages
  #         resolve(@messages[folder].messages)
  #       else
  #         @imap.then (imap) =>
  #           imap.listMessages(path: folder).then (messages) =>
  #             lastUid = 0
  #             for msg in messages
  #               lastUid = msg.uid if msg.uid > lastUid
  #             @messages[folder] = {messages, lastUid}
  #
  #             resolve(@messages[folder].messages)
  #
  # updateMessageList: ->
  #   @withImap (imap) =>
  #     imap.listMessages(@path)
  #

  ###
  Section: Event Subscriptions
  ###

  # Essential: Calls your callback, if mailbox contents (mails) have been updated
  #
  # * `callback` {Function}
  #   * parameter ...
  #
  #  Returns a {Disposable} on which `.dispose()` can be called to unsubscribe
  onDidUpdateMailboxContents: (callback) ->
    @emitter.on 'did-update-mailbox-contents', callback

module.exports = {MailboxEditor}
