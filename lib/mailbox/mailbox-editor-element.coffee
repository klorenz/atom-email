MailboxEditorView = require './mailbox-editor-view'

class MailboxEditorElement extends HTMLElement
  createdCallback: ->
    v = new MailboxEditorView @mailboxEditor
    debugger
    @appendChild v.element

  initialize: (@mailboxEditor) ->
    this

module.exports = MailboxEditorElement = document.registerElement 'mailbox-editor', prototype: MailboxEditorElement.prototype
