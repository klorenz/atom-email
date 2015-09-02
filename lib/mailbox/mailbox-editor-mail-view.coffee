{ScrollView} = require 'atom-space-pen-views'

module.exports =
class MailView extends ScrollView
  @content: ->
    # header for buttons "source", "mail"
    @div class: "mail-view", =>
      @div class: "mail-container", outlet: 'mailContainer'

  initialize: (state) ->
    super
    {@mailboxEditor} = state

    @visibleMessage = null

    @prefer = [ "html", "text" ]

    @mailboxEditor.onDidRequestShowMessage (message) =>
      return if message.uid == @visibleMessage?.uid

      for preferred in @prefer
        neededParts = message.getBodyPartsForType preferred
        break if neededParts.length

      @mailboxEditor.getMessageBodyParts(message, neededParts).then (parts) =>
        console.log parts
        @mailContainer.html('')

        for part in parts
          if part.type == 'html'
            console.log part
            @mailContainer.append(part.content)
          else
            #content = part.content.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/&/g, '&amp;')
            @mailContainer.append("<pre>#{part.content}</pre>")

        @visibleMessage = message
      .catch (error) =>
        atom.notifications.addError "Could not load message parts", detail: "#{error}", stack: error.stack, dismissable: true

      # debugger
      # @text(message.bodystructure)
      # console.log message
