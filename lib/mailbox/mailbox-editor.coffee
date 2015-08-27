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
    @suscriptions = new CompositeDisposable

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
    @imap.login().then (mailbox) =>
      @subscriptions.add mailbox.onDidStartGetMessages (messages, options) =>
        @emitter.emit 'did-start-get-messages', messages, options
      @subscriptions.add mailbox.onDidProgressGetMessages (messages, options) =>
        @emitter.emit 'did-progress-get-messages', messages, options
      @subscriptions.add mailbox.onDidEndGetMessages (messages, options) =>
        @emitter.emit 'did-end-get-messages', messages, options
      @subscriptions.add mailbox.onError (error) =>
        atom.notifications.addEror error
      @subscriptions.add mailbox.onDidSelectMailbox (path, info) =>
        @emitter.emit 'did-select-mailbox', path, info

      @emitter.emit 'did-select-mailbox', mailbox.path, mailbox.info

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

module.exports = {MailboxEditor}
