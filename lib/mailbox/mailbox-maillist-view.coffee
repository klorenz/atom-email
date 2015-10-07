{SelectListView, $} = require 'atom-space-pen-views'
fuzzaldrin = require 'fuzzaldrin'
# scorer} = require 'fuzzaldrin'
#fuzzyFilter = require('fuzzaldrin').filter
{Emitter}  = require 'atom'
{keys} = require 'underscore'
_ = require 'underscore'

capitalize = (s) -> s[0].toUpper() + s[1..]

formatAddress = (o) ->
  return o.trim() if typeof o is 'string'

  address = ''
  if o.name
    address += o.name
  if o.address
    address += " <#{o.address}>"

  address.trim()

formatAddressList = (o) ->
  if o instanceof Array
    (formatAddress x for x in o).join(', ')
  else
    formatAddress o

module.exports =
  class MailListView extends SelectListView
    initialize: ->
      debugger
      super
      @filterEditorView.off('blur')
      @focusFilterEditor()
      @setMaxItems(2000)
      @displayFields = ['from', 'sent', 'subject']
      @filterKeyFields = null
      @emitter = new Emitter
      @filterType = 'regex-i'  # or fuzzaldrin

      @initializeCommandPalette()

    initializeCommandPalette: ->
      CommandPalette = atom.packages.getActivePackage('command-palette').mainModule
      @commandPalette = new CommandPalette()

      mailListView = @
      @commandPalette.show = ->
        @panel ?= atom.workspace.addModalPanel(item: this)
        @panel.show()

        @storeFocusedElement()
        @eventElement = mailListView.parents('mailbox-editor')[0]
        @keyBindings = atom.keymaps.findKeyBindings(target: @eventElement)

        commands = atom.commands.findCommands(target: @eventElement).filter (e) ->
          e.name.match /^(?:mail:|mailbox:|message:|all-filtered-messages:)/

        commands = _.sortBy(commands, 'displayName')
        @setItems(commands)

        @focusFilterEditor()

    setFilterType: (@filterType) ->
      @populateList()

    getFilterKeyFields: ->
      if @filterKeyFields?
        @filterKeyFields
      else
        @displayFields

# TODO: reset selection after populating the list
    populateList: ->
      return unless @items?

      filterQuery = @getFilterQuery()
      if filterQuery.length
        filterKeyFields = @getFilterKeyFields()
        if m = @filterType.match /^regex(-i)?/
          regexes = []
          for q in filterQuery.split /\s+/
            regexes.push new RegExp "^([\\s\\S]*?)("+q+")([\\s\\S]*)", m[1] and "i" or ""

          viewItems = []

          for candidate in @items
            matches = {}
            total = 0
            for field in filterKeyFields
              s = value = @getItemFieldValueString candidate, field
              match = []
              for regex in regexes
                mob = regex.exec s
                unless mob
                  match = null
                  break

                match.push mob[1]
                match.push mob[2]
                s = mob[3]

              match.push s if match?

              matches[field] = match
              continue unless match
              total += 1

            if total
              viewItems.push {candidate, matches, total}

          # filteredItems = @items.filter (a) ->
          #   for field in filterKeyFields
          #     return true if regex.match a[field]

        else
          scoredCandidates = []
          for candidate in @items
            scores = {total: 0}
            for field in filterKeyFields
              scores[field] = 0
              s = @getItemFieldValueString candidate, field
              continue unless s
              score = fuzzaldrin.score s, filterQuery
              scores.total += score
              scores[field] = score

            scoredCandidates.push {candidate, scores} if scores.total > 0
            scores.total = scores.total / 3

          scoredCandidates.sort (a,b) -> b.scores.total - a.scores.total

          #filteredItems = scoredCandidates.map (a) -> a.candidate
          viewItems = scoredCandidates
          #filteredItems = fuzzyFilter(@items, filterQuery, key: @getFilterKey())
      else
        viewItems = @items.map (candidate) => {candidate}

      @emitter.emit 'did-filter-items', viewItems

      count = 0

      @list.empty()
      if viewItems.length
        @setError(null)
        count = Math.min(viewItems.length, @maxItems)

        for i in [0...count]
          item = viewItems[i]
          itemView = $(@viewForItem(item))
          itemView.data('select-list-item', item.candidate)
          @list.append(itemView)

        @selectItemView(@list.find('li:first'))
      else
        @setError(@getEmptyMessage(@items.length, viewItems.length))

      @emitter.emit 'did-populate-list', {items: viewItems.map((a) -> a.candidate), count}

    # populate: ->
    #   super
    #   @emitter.emit 'did-populate-list', @list

    viewForItem: (item) ->
      filterQuery = @getFilterQuery()
      # if item.scores
      #   matches = match item.filterKey, filterQuery
      # list of indexes in filterKey

      # gravatar?
      htmlEnc = (s) -> s.replace(/&/, '&amp;').replace(/</g, "&lt;").replace(/>/g, "&gt;")

      scoresString = ''
      if item.scores?.total?
        scoresString += 'total: '+item.scores.total

      result = """<li data="#{item.candidate.uid}"><div class="mailbox-editor-mail-info">"""
      for field in @displayFields
        value = @getItemFieldValueString item.candidate, field
        continue unless value?

        if item.scores?[field]
          matches = fuzzaldrin.match value, filterQuery
          parts = []
          prev = 0
          for i in matches
            parts.push htmlEnc value[prev...i]
            parts.push "<b>" + htmlEnc(value[i]) + "</b>"
            prev = i+1
          parts.push value[i+1...]

          scoresString += " #{field}: "+item.scores[field]

          value = parts.join('')
        else if item.matches?[field]
          match = item.matches?[field]
          value = ''
          for val, i in match
            value += if i%2 == 1 then "<b>"+htmlEnc(val)+"</b>" else htmlEnc(val)

        else
          value = htmlEnc value

        result += '<span class="field-'+field+'">'+value+'</span>\n'


      flagmap =
        seen: ['email-icon-mail', '']
        answered: ['', 'email-icon-reply-outline']
        forwarded: ['', 'email-icon-forward-outline']

        # TOOD: if both are there, it should be clickable to change flag state
        #'*': ['email-icon-star-outline', 'email-icon-star-filled']

        '*': ['', 'email-icon-star-outline']
        deleted: ['', 'email-icon-cancel']
        flagged: ['', 'email-icon-tags']
        attachment: ['', 'email-icon-attach-1']
        draft: ['', 'email-icon-edit']
        junk: ['', 'email-icon-flash']

      #console.log "flags", item.flag

      msg = item.candidate

      flags = keys(msg.flag).sort()

      result += '<span class="field-flag">'
      for flag,f of msg.flag
        if flag of flagmap
          id = f and 1 or 0
          icon = flagmap[flag][id]
          if icon isnt ''
            result += """<span class="message-flag #{icon}"></span>"""
      result += '</span>'

      result += "</div>"

      if 0 and scoresString
        result += "<div>#{scoresString}</div>"

      if @filterKeyFields?
        result += '<div class="filter-key">'+item.filterKey+'</div>'

      result += "</li>"

      return result

    getItemFieldValue: (item, field) ->
      value = null

      if item[field]
        value = item[field]

      value

    getItemFieldValueString: (item, field) ->
      value = @getItemFieldValue item, field
      if value instanceof Array
        value = formatAddressList value
      value

    # setItemsFilterKey: (items, {force}={}) ->
    #   if force isnt true
    #     if items.length
    #       if items[0].filterKey
    #         return
    #
    #   items.forEach (item) =>
    #     filterKey = ''
    #     filterKeyRanges = {}
    #     offset = 0
    #     for key in @getFilterKeyFields()
    #       value = @getItemFieldValueString item, key
    #       continue unless value?
    #
    #       #prefix = capitalize(key) + ":"
    #       prefix = ""
    #       offset += prefix.length
    #
    #       filterKey += prefix + value + "\n"
    #
    #       start = offset
    #
    #       offset += value.length + 1
    #
    #       filterKeyRanges[key] = [start, offset]
    #
    #     item.filterKey = filterKey
    #     item.filterKeyRanges = filterKeyRanges
    #
    # setItems: (items) ->
    # #  @setItemsFilterKey items
    #   super items

    setFilterKeyFields: (filterKeyFields) ->
      @filterKeyFields = filterKeyFields
      @setItemsFilterKey @items force: true

    getFilterKey: () ->
      # depends on some SmtpSettingsView
      return 'filterKey'

    confirmed: (item) ->
      @commandPalette.show()

    selectItemView: (view) ->
      return unless @items?.length > 0

      result = super view
      console.log view, result
      @emitter.emit 'did-select-item', @getSelectedItem()
      return result

    onDidSelectItem: (callback) ->
      @emitter.on 'did-select-item', callback

    onDidPopulateList: (callback) ->
      @emitter.on 'did-populate-list', callback

    onDidFilterItems: (callback) ->
      @emitter.on 'did-filter-items', callback
