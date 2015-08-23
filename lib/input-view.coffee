
{Point} = require 'atom'
{$, TextEditorView, View}  = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

inputView = null

getInputView = ->
  unless inputView?
    inputView = new InputView()

  inputView


class InputView extends View
  @content: ->
    @div class: 'prompt-input', outlet: 'promptInput', =>
      #@div class: 'title', outlet: 'title'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'message', outlet: 'message'

  initialize: ->

#    @promptInput.inputView = this
#    super

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    # atom.commands.add 'atom-text-editor', 'go-to-line:toggle', =>
    #   @toggle()
    #   false
    #

    @miniEditor.on 'blur', => @close()
    atom.commands.add @miniEditor.element, 'core:confirm', => @confirm()
    atom.commands.add @miniEditor.element, 'core:cancel', =>
      @close()

      if @onCancel?
        @onCancel()


    # @miniEditor.getModel().onWillInsertText ({cancel, text}) ->
    #   cancel() unless text.match(/[0-9:]/)

  # toggle: ->
  #   if @panel.isVisible()
  #     @close()
  #   else
  #     @open()

  close: ->
    return unless @panel.isVisible()
    inputText = @miniEditor.getText()
    @temporarySubscriptions.dispose()

    @message.show()
    @message.text('')

    miniEditorFocused = @miniEditor.hasFocus()

    @miniEditor.setText('')
    @panel.hide()
    @restoreFocus() if miniEditorFocused

    if @onDone
      @onDone inputText

  confirm: ->
    inputText = @miniEditor.getText()
    editor = atom.workspace.getActiveTextEditor()

    @close()

    if @onConfirm?
      @onConfirm inputText

  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  open: ({label, placeholderText, initialValue, onDidChange, onConfirm, onCancel, onDone}={}) ->
    return if @panel.isVisible()

    if editor = atom.workspace.getActiveTextEditor()
      @storeFocusedElement()

      #debugger

      # set input specific values
      @temporarySubscriptions = new CompositeDisposable

      if label?
        @message.text(label)
      else
        @message.hide()

      miniEditor = @miniEditor.getModel()

      @miniEditor.placeholderText = placeholderText

      if onDidChange?
        @temporarySubscriptions.add miniEditor.onDidChange =>
          onDidChange.call miniEditor, miniEditor.getText()

      @onConfirm = onConfirm
      @onCancel  = onCancel
      @onDone    = onDone

      if initialValue?
        miniEditor.setText initialValue

      @panel.show()

      @miniEditor.focus()

showModalInputPanel = (options) -> getInputView().open options

#showBottomInputPanel = ({label, placeholderText, initialValue, onDidChange, onConfirm, onCancel}={})
#  inputView.open {label, placeholderText, initialValue, onDidChange, onConfirm, onCancel}

module.exports = {showModalInputPanel, InputView}
