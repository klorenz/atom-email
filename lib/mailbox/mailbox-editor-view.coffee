{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
{values} = require 'underscore'

#  MailboxView = require './mailbox-editor-mailbox-view.coffee'
MailboxListView = require './mailbox-mailbox-listview.coffee'
MailView = require './mailbox-editor-mail-view.coffee'
MailListView = require './mailbox-maillist-view.coffee'

module.exports =
class MailboxEditorView extends View

  @content: ->
    @div class: 'mailbox-editor-container', =>
      # @div class: 'mail-view-container', outlet: 'mailViewContainer', =>
      #
      # @div class: 'mailbox-editor-view-resizer tool-panel', 'data-show-on': 'bottom', =>
      #   @div class: 'mailbox-editor-view-resize-handle', outlet: 'resizeHandleBR'
      #
      #   @div class: 'mailbox-editor-toolbar', outlet: 'mailToolBar', =>
      #     # @span class: "tool-group tool-group-mail-new", =>
      #     #   @span class: "btn-group", =>
      #     #     @button class: "btn email-icon-new-mail", outlet: 'btnNewMail', title: "Write Mail"
      #
      #     # @span class: "tool-group tool-group-mail-view", =>
      #     #   @span class: "btn-group", =>
      #     #     @button class: "btn email-icon-show-header", outlet: 'btnToggleHeader', title: "Show Header"
      #     #
      #     #   @span class: "btn-group btn-group-view-source", =>
      #     #      @button class: "btn email-icon-view-source", outlet: 'btnViewSource', title: "View Source"
      #
      #     @span class: "tool-group tool-group-actions", =>
      #       # @span class: "btn-group btn-group-action-scope", =>
      #       #   @button class: "btn email-icon-one", outlet: 'btnScopeOne', title: "For this mail", =>
      #       #   @button class: "btn email-icon-many", outlet: 'btnScopeMany', title: "For all mails filtered", =>
      #
      #       @span class: "btn-group btn-group-mail-actions", =>
      #         @button class: "btn email-icon-reply", outlet: 'btnDoReply', title: "Reply"
      #         @button class: "btn email-icon-reply-all", outlet: 'btnDoReplyAll', title: "Reply All"
      #         @button class: "btn email-icon-forward", outlet: 'btnDoForward', title: "Forward"
      #
      #       # @span class: "btn-group btn-group-mailbox-actions", =>
      #       #   @button class: "btn email-icon-copy-to-folder", outlet: 'btnDoCopyToFolder', title: "Copy to Mailbox Folder"
      #       #   @button class: "btn email-icon-move-to-folder", outlet: 'btnDoMoveToFolder', title: "Move to Mailbox Folder"
      #
      #       # @span class: "btn-group btn-group-calendar-actions", => #       #   @button class: "btn icon-copy", title: "Copy to Mailbox Folder"

        @div class: 'mailbox-view-container', outlet: 'mailboxViewContainer', =>
          @header =>
            @span class: "tool-group tool-group-select-mailbox", =>
              @button class: 'btn', outlet: 'btnSelectMailbox'

              @span class: 'mailbox-stats', =>
                 @span class: 'mailbox-filtered-count', outlet: 'filteredCount', '0'
                 @span "/"
                 @span class: 'mailbox-message-count', outlet: 'messageCount', '0'

            @span class: "tool-group tool-group-mailbox-tools", =>
              @span class: 'btn-group', =>
                @button class: 'btn', outlet: 'btnFilterRegex', title: "Do regex filtering", =>
                  @b ".*"
                @button class: 'btn', outlet: 'btnFilterFuzzy', title: "Do fuzzy filtering", =>
                  @b "~"
              @span class: 'btn-group', =>
                @select class: 'btn', outlet: 'selSortField', =>
                  @option value: 'sent', "Sent"
                  @option value: 'sender', "Sender"
                  @option value: 'subject', "Subject"
                @button class: 'btn email-icon-sort-alt-up', outlet: 'btnSortAscending', title: "Sort Ascending"
                @button class: 'btn email-icon-sort-alt-down', outlet: 'btnSortDescending', title: "Sort Descending"

                #@button class: 'btn email-icon-folder-folder-outline', outlet: 'btnFolderOpen', title: "Open a Mailbox in another Pane"

              # @span class: 'btn-group', =>
              #   @button class: 'btn email-icon-folder-add', outlet: 'btnFolderAdd', title: "Create a Mailbox"
              #   @button class: 'btn email-icon-folder-delete', outlet: 'btnFolderRemove', title: "Remove a Mailbox"
              #
              # @span class: 'btn-group', =>
              #   @button class: 'btn email-icon-folder-outline', outlet: 'btnFolderOpen', title: "Open a Mailbox in another Pane"

          @section class: 'mail-list-view-container', outlet: 'mailListViewContainer', =>
            @subview 'mailListView', new MailListView

        @div class: 'mailbox-editor-view-resize-handle', outlet: 'resizeHandleTL'

  initialize: (state) ->
    {@mailboxEditor} = state

    @mailboxListView = new MailboxListView {@mailboxEditor}
    @subscriptions = new CompositeDisposable
    @mailPreview = require("../mail/preview.coffee")

    # @mailboxEditor.onDidSelectMessage (message) =>
    #   if not @mailViewPanel.isVisible()
    #     @mailViewPanel.show()
    #
    #   @mailView.showMessage(message)

#    @initializeActionScope()
    @initializeMailListView()
#    @initializeToolBar()
    @initializeSort()
    @initializeFilter()

    @selSortField.select('sent')

  #  @mailViewContainer.append @mailView.element

  initializeFilter: ->
    if @mailboxEditor.getFilterType() is 'fuzzy'
      @btnFilterFuzzy.addClass('selected')
      @mailListView.setFilterType 'fuzzy'
    else
      @btnFilterRegex.addClass('selected')
      @mailListView.setFilterType 'regex-i'

    @mailboxEditor.onDidChangeFilterType (filterType) =>
      @mailListView.setFilterType filterType

      if filterType is 'fuzzy'
        @btnFilterFuzzy.addClass('selected')
        @btnFilterRegex.removeClass('selected')
      else
        @btnFilterFuzzy.removeClass('selected')
        @btnFilterRegex.addClass('selected')

    @btnFilterFuzzy.click => @mailboxEditor.setFilterType('fuzzy')
    @btnFilterRegex.click => @mailboxEditor.setFilterType('regex-i')

  initializeActionScope: ->
    if @mailboxEditor.getActionScope() is 'one'
      @btnScopeOne.addClass('selected')
    else
      @btnScopeMany.addClass('selected')

    #@subscriptions = new CompositeDisposable

    @subscriptions.add @mailboxEditor.onDidChangeActionScope (actionScope) =>
      if actionScope is 'one'
        @btnScopeOne.addClass('selected')
        @btnScopeMany.removeClass('selected')
      else
        @btnScopeOne.removeClass('selected')
        @btnScopeMany.addClass('selected')

  initializeSort: ->
    @selSortField.select(@mailboxEditor.getSortField())
    @updateSortTypeButtons @mailboxEditor.getSortType()

    @mailboxEditor.onDidChangeSortType (type) =>
      @updateSortTypeButtons type
      @setMailListItems null

    @mailboxEditor.onDidChangeSortField (type) =>
      @mailListView.setItems
      @setMailListItems null

    @btnSortAscending.click  => @mailboxEditor.setSortType 'ascending'
    @btnSortDescending.click => @mailboxEditor.setSortType 'descending'
    @selSortField.change     => @mailboxEditor.setSortField @selSortField.val()

  updateSortTypeButtons: (type) ->
    if type is 'ascending'
      @btnSortAscending.addClass('selected')
      @btnSortDescending.removeClass('selected')
    else
      @btnSortAscending.removeClass('selected')
      @btnSortDescending.addClass('selected')

  setMailListItems: (messages=null) ->
    unless messages?
      messages = @mailListView.items
      @mailListView.setItems []

    messages = values messages unless messages instanceof Array

    factor = if @mailboxEditor.getSortType() is 'ascending' then 1 else -1

    field = @mailboxEditor.getSortField()
    if field == 'sent'
      messages.sort (a,b) => factor*(a.sentTimestamp - b.sentTimestamp)
    else
      messages.sort (a,b) => factor*(if a[field] < b[field] then -1 else
        if a[field] > b[field] then 1 else 0)

    @mailListView.setItems values messages


  initializeMailListView: ->
    @mailboxEditor.onDidStartGetMessages (messages) =>
      @setMailListItems messages

    @mailboxEditor.onDidProgressGetMessages (messages) =>
      console.log "progress get messages", messages
      @setMailListItems messages

    @mailboxEditor.onDidEndGetMessages (messages) =>
      @setMailListItems messages

    @mailboxEditor.onDidSelectMailbox ({path, info}) =>
      @btnSelectMailbox.text(path)
      @messageCount.text(info.exists)

    @mailListView.onDidSelectItem (item) =>
      @mailboxEditor.selectMessage(item)

    @mailboxEditor.onDidSelectMessage (message) =>
      @mailPreview.showMessage(message)

    @mailboxEditor.onDidUpdateMessages (messages) =>
      @setMailListItems()

    @mailListView.onDidPopulateList ({items, count}) =>
      @filteredCount.removeClass('filter-overflow')
      @filteredCount.attr('title', '# of hits')

      if count < items.length
        @filteredCount.addClass('filter-overflow')
        @filteredCount.attr('title', 'too many hits')

      @filteredCount.text(count)
      @mailboxEditor.selectMessages items

    @mailboxEditor.openMailbox()

    @btnSelectMailbox.on 'click', =>
      @mailboxEditor.showMailboxSelector()

  initializeToolBar: ->
    @btnNewMail.click    => @mailboxEditor.newMail()
    @btnDoReply.click    => @mailboxEditor.reply()
    @btnDoReplyAll.click => @mailboxEditor.replyAll()
    @btnDoForward.click  => @mailboxEditor.forward()
    @btnScopeOne.click   => @mailboxEditor.setActionScope('one')
    @btnScopeMany.click  => @mailboxEditor.setActionScope('many')

    #@mailViewContainer.height("50%")
    #@mailboxViewContainer.height("50%")

  destroy: ->
    @mailView.destroy()
    @mailboxListView.destroy()
    @subscriptions.dispose()
