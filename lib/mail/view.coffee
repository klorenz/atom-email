# {ScrollView} = require 'atom-space-pen-views'





module.exports =
class MailView extends ScrollView
  @content: ->
    # header for buttons "source", "mail"
    @div class: "mail-view", =>
      @div class: "mail-container", outlet: 'mailContainer'

  # initialize: (state) ->
  #
  #   @panel = atom.workspace.addRightPanel(item: this, visible: false)
  #   @visibleMessage = null
  #
  #   @subscriptions.add atom.commands.addCommand "atom.workspace", "email:toggle-preview", =>
  #     if @panel.isVisible()
  #       @panel.hide()
  #     else
  #       @panel.show()

  showMessage: (message, parts) ->
    return if message.uid == @visibleMessage?.uid

    console.log parts
    @mailContainer.html('')

    header = [ '<header>' ]
    makeLabel = (s) =>
      s = s.replace /[A-Z]/, (m) -> " "+m
      s[0].toUpperCase()+s[1..]

    console.log "message", message

    makeAddress = (n,a)  =>
      """<a href="mailto:#{a}" title="#{a}">#{n}</a>"""

    values = {}

    for field in "from sender subject sent replyTo cc".split(" ")
      if message[field]
        value = message[field]
        if value instanceof Array
          addrlist = []
          for v in value
            if typeof v is "string"
              addrlist.push makeAddress v, v
            else
              if v.name
                addrlist.push makeAddress v.name, v.address
              else
                addrlist.push makeAddress v.address, v.address

          value = addrlist.join ", "

        values[field] = value
        if field is 'sender' and value == values.from
          continue
        if field is 'replyTo' and value == values.from
          continue

        label = makeLabel field
        header.push """
          <div class="header-field header-field-#{field}">
            <span class="label label-#{field}">#{label}</span><span class="value value-#{field}">#{value}</span>
          </div>
        """
    header.push '</header>'

    @mailContainer.append header.join('\n')

    for part in parts
      if part.type == 'html'
        console.log part
        @mailContainer.append(part.content)
      else
        #content = part.content.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/&/g, '&amp;')
        content = part.content.replace /(([\w\-]+:\/\/|mailto:)\S+[\w\/])/g, """<a href="$1">$1</a>"""
        @mailContainer.append("<pre>#{content}</pre>")

    @visibleMessage = message

      # debugger
      # @text(message.bodystructure)
      # console.log message
