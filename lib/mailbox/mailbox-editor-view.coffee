{View} = require 'atom-space-pen-views'

MailboxView = require './mailbox-editor-mailbox-view.coffee'
MailboxListView = require './mailbox-mailbox-listview.coffee'
MailView = require './mailbox-editor-mail-view.coffee'

module.exports =
class MailboxEditorView extends View

  @content: ->
    @div class: 'mailbox-editor-container', =>
      @div class: 'mail-view-container', outlet: 'mailViewContainer'
      @div class: 'mailbox-editor-view-resizer tool-panel', 'data-show-on': 'left', =>
        @div class: 'mailbox-editor-maillist-view-container', outlet: 'mailboxViewContainer'
        @div class: 'mailbox-editor-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    {@mailboxEditor} = state

    @mailboxView = new MailboxView {@mailboxEditor}
    @mailView = new MailView {@mailboxEditor}
    @mailboxListView = new MailboxListView {@mailboxEditor}

    @mailboxViewContainer.append @mailboxView.element
    @mailViewContainer.append @mailView.element
    @mailViewContainer.height("50%")
    @mailboxViewContainer.height("50%")
