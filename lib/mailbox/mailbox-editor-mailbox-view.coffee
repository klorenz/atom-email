{View, SelectListView} = require 'atom-space-pen-views'
{values} = require 'underscore'

MailListView = require './mailbox-maillist-view.coffee'

module.exports =
class MailboxView extends View
  @content: ->
    @div class: 'mailbox-view', outlet: 'mailbox', =>
      @header =>
        @button class: 'btn', outlet: 'mailboxTitle'
        @span class: 'mailbox-message-count', outlet: 'messageCount'

        # @span class: 'btn-group', =>
        #   @span class: 'caption', 'Filter'
        #   @button class: 'btn', outlet: 'filterFrom', 'From'
        #   @button class: 'btn', outlet: 'filterSubject', 'Subject'
        #   @button class: 'btn', outlet: 'filterSentDate', 'Date'
        #
        # @span class: 'btn-group', =>
        #   @span class: 'caption', 'Sort'
        #   @span class: 'btn', outlet: 'sortFrom', 'From'
        #   @span class: 'btn', outlet: 'sortSubject', 'Subject'
        #   @span class: 'btn', outlet: 'sortSentDate', 'Date'
        #   @span " "
        #   @span class: 'btn', outlet: 'sortAsc', 'Asc'
        #   @span class: 'btn', outlet: 'sortDesc', 'Desc'

      @section class: 'mail-list-view-container', outlet: 'mailListViewContainer', =>
        @subview 'mailListView', new MailListView

  initialize: (state)->
    {@mailboxEditor, mailboxPath, @sortType, @sortBy, @filter} = state

    @sortType = 'desc' unless @sortType
    @sortBy   = 'sentDate' unless @sortBy

    @mailboxEditor.onDidStartGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidProgressGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidEndGetMessages (messages) =>
      @mailListView.setItems values messages

    @mailboxEditor.onDidSelectMailbox ({path, info}) =>
      @mailboxTitle.text(path)
      @messageCount.text(info.exists)

    @mailListView.onDidSelectItem (item) =>
      @mailboxEditor.displayMessage(item)

    @mailboxEditor.openMailbox()


  selectMailbox: (path) ->
    @mailboxEditor.selectMailbox(path)
