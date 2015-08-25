{View} = require 'atom-space-pen-views'

module.exports =
class MailboxEditorView extends View

  @content: ->
    @div class: 'mailbox-editor-view-resizer tool-panel', 'data-show-on': 'left', =>
      @div class: 'mailbox-editor-view-scroller', outlet: 'scroller', =>
        @div "Hello World"
      @div class: 'mailbox-editor-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
