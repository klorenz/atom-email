{View} = require 'atom-space-pen-views'

MailboxView = require './mailbox-editor-mailbox-view.coffee'

module.exports =
class MailboxEditorView extends View

  @content: ->
    @div 'mailbox-editor-container', =>
      @div class: 'mail-view-container', outlet: 'mailViewContainer'
      @div class: 'mailbox-editor-view-resizer tool-panel', 'data-show-on': 'left', =>
        @div class: 'mailbox-editor-maillist-view-container', outlet: 'mailboxViewContainer'
        @div class: 'mailbox-editor-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    {@mailboxEditor} = state

    # @mailboxEditor.onDidUpdateMailboxInfo (info) =>
    #   "not implemented"
    #
    # @mailboxEditor.onDidUpdateMailboxes (mailboxes) =>
    #   "not implemented"

    debugger

    @mailboxViewContainer.append @subview 'mailbox', new MailboxView {@mailboxEditor}

    #@mailboxEditor.updateMailboxes info: true
