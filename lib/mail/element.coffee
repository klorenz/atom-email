{makeLabel, addressLink} = require "../utils"

class MailMessageElement extends HTMLElement
  createdCallback: ->

  initialize: (model) ->
    debugger
    @shadowRoot = this.createShadowRoot()
    @setModel model
    this

  getTitle: ->
    return @model.subject

  setModel: (@model) ->
    render = (not @message? || @model.uid != @message.uid)
    @message = @model

    @render() if render

  render: ->
    unless @message?
      @shadowRoot.innerHTML = '<div><span class="email-icon-mail"></span></div>'
      return

    html = [ '<header>' ]
    values = {}

    for field in "from sender subject sent replyTo cc".split(" ")
      if @message[field]
        value = @message[field]
        if value instanceof Array
          addrlist = []
          for v in value
            if typeof v is "string"
              addrlist.push addressLink v, v
            else
              if v.name
                addrlist.push addressLink v.name, v.address
              else
                addrlist.push addressLink v.address, v.address

          value = addrlist.join ", "

        values[field] = value
        if field is 'sender' and value == values.from
          continue
        if field is 'replyTo' and value == values.from
          continue

        label = makeLabel field
        html.push """
          <div class="header-field header-field-#{field}">
            <span class="label label-#{field}">#{label}</span><span class="value value-#{field}">#{value}</span>
          </div>
        """
    html.push '</header>'

    html.push '<section class="message-body">'

    for part in @message.bodyParts
      if part.type == 'html'
        continue unless part.content

        console.log part
        html.push(part.content)

      else if part.type == 'text'
        continue unless part.content

        content = part.content.replace /(([\w\-]+:\/\/|mailto:)\S+[\w\/])/g, """<a href="$1">$1</a>"""
        html.push("<pre>#{content}</pre>")
    html.push '</section>'

    @shadowRoot.innerHTML = html.join("\n")

  destroy: ->

module.exports = MailMessageElement = document.registerElement 'mail-message', prototype: MailMessageElement.prototype
