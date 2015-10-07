{CompositeDisposable} = require 'atom'

class MailPreview
  constructor: ->
    @element = document.createElement('div')
    @element.classList.add('mail-preview')
    @mailElement = null

    @element.innerHTML = """
      <div class="mail-preview-resizer"></div>
      <div class="mail-preview-container">
        <div class="placeholder">
          <span class="email-icon-mail"></span>
        </div>
      </div>
    """

    @previewContainer = @element.children[1]

    @panel = atom.workspace.addRightPanel(item: @element, visible: false)
    @subscriptions = new CompositeDisposable()

    @subscriptions.add atom.commands.add "atom-workspace", 'email:toggle-preview', =>
      if @panel.isVisible()
        @panel.hide()
      else
        @panel.show()

  showMessage: (message) ->
    if message?
      if @mailElement?
        @mailElement.setModel(message)
      else
        @mailElement = atom.views.getView(message)
        @previewContainer.innerHTML = ''
        @previewContainer.appendChild(@mailElement)

      if not @panel.isVisible()
        @panel.show()

    else
      @previewContainer.innerHTML = '<span class="email-icon-mail"></span>'

      if @mailElement?
        @mailElement.destroy()
        @mailElement = null

  destroy: ->
    @subscriptions.dispose()

module.exports = new MailPreview
