{ScrollView} = require 'atom-space-pen-views'

module.exports =
class MailView extends ScrollView
  @content: ->
    # header for buttons "source", "mail"
    @div class: "mail-view"

  initialize: (state) ->
    super
    {@mailboxEditor} = state

    @displayedMessage = null

    @prefer = [ "html", "text" ]

    @mailboxEditor.onDidRequestDisplayMessage (message) =>
      return if message.uid == @displayedMessage?.uid

      for preferred in @prefer
        neededParts = message.getBodyPartsForType preferred
        break if neededParts.length

      @mailboxEditor.getMessageBodyParts(message, neededParts).then (parts) =>
        console.log parts
        @html('')

        for part in parts
          if part.type == 'html'
            console.log part
            @append(part.content)
          else
            #content = part.content.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/&/g, '&amp;')
            @append("<pre>#{part.content}</pre>")

        @displayedMessage = message
      .catch (error) =>
        atom.notifications.addError "Could not load message parts", detail: "#{error}", stack: error.stack, dismissable: true

      # debugger
      # @text(message.bodystructure)
      # console.log message
