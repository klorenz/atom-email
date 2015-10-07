MailboxEditorView = require './mailbox-editor-view'

class MailboxEditorElement extends HTMLElement
  createdCallback: ->

  initialize: (@mailboxEditor) ->
    v = new MailboxEditorView {@mailboxEditor}
    @appendChild v.element
    this

  getTitle: ->
    return "mailbox"

  setModel: (@model) ->

  destroy: ->
    debugger
    @mailboxEditor.destroy()

module.exports = MailboxEditorElement = document.registerElement 'mailbox-editor', prototype: MailboxEditorElement.prototype
