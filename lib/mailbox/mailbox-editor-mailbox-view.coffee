{View, SelectListView} = require 'atom-space-pen-views'
{values} = require 'underscore'

MailListView = require './mailbox-maillist-view.coffee'

module.exports =
class MailboxView extends View
  @content: ->
    @div class: 'mailbox-view', outlet: 'mailbox', =>
      @header =>
        @button class: 'btn', outlet: 'mailboxTitle'
        @span class: 'mailbox-stats', =>
          @span class: 'mailbox-filtered-count', outlet: 'filteredCount', '0'
          @span "/"
          @span class: 'mailbox-message-count', outlet: 'messageCount', '0'

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
    @sortBy   = 'sent' unless @sortBy

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
      @mailboxEditor.selectMessage(item)

    @mailListView.onDidPopulateList ({items, count}) =>
      @filteredCount.removeClass('filter-overflow')
      @filteredCount.attr('title', '# of hits')

      if count < items.length
        @filteredCount.addClass('filter-overflow')
        @filteredCount.attr('title', 'too many hits')

      @filteredCount.text(count)
      @mailboxEditor.selectMessages items

    @mailboxEditor.openMailbox()

    @mailboxTitle.on 'click', =>
      @mailboxEditor.showMailboxSelector()


  selectMailbox: (path) ->
    @mailboxEditor.selectMailbox(path)
