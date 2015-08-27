{View, SelectListView} = require 'atom-space-pen-views'
{values} = require 'underscore'

MailListView = require './mailbox-maillist-view.coffee'

module.exports =
class MailboxView extends View
  @content: ->
    @div class: 'mailbox-view', outlet: 'mailbox', =>
      @div class: 'mailbox-title', =>
        @span class: 'mailbox-title', outlet: 'mailboxTitle'
        @span " ("
        @span class: 'mailbox-message-count', outlet: 'mailboxMessageCount'
        @span ")"
      @div class: 'mail-list-view-container', outlet: 'mailListViewContainer', =>
        @subview 'mailListView', new MailListView
      @div class: 'mailbox-toolbar'

  initialize: (state)->
    {@mailboxEditor, mailboxPath} = state

    @mailboxEditor.onDidStartGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidProgressGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidEndGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidSelectMailbox @didSelectMailbox

    @mailboxEditor.openMailbox()

    # u nless mailboxPath
    #   mailboxPath = @mailboxEditor.getInboxPath()
    #
    # @mailboxEditor.openMailbox(mailboxPath).then (mailbox) =>
    #   @mailbox = mailbox


  didSelectMailbox: (path, info) =>
    #@mailboxPath = path
    #@mailListView.setItems @mailbox.getMessages()
    #@mailListView.setMailbox @mailbox
    @mailboxTitle.text(path)
    @messageCount.text(info.exists)

  selectMailbox: (path) ->
    @mailboxEditor.selectMailbox(path)
