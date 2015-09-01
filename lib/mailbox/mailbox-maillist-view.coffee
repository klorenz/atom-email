{SelectListView} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
{Emitter}  = require 'atom'

capitalize = (s) -> s[0].toUpper() + s[1..]

formatAddress = (o) ->
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
      super
      @focusFilterEditor()
      @setMaxItems(100)
      @displayFields = ['sentDate', 'sender', 'subject']
      @filterKeyFields = null
      @emitter = new Emitter

    getFilterKeyFields: ->
      if @filterKeyFields?
        @filterKeyFields
      else
        @displayFields

    viewForItem: (item) ->
      filterQuery = @getFilterQuery()

      matches = match item.filterKey, filterQuery
      # list of indexes in filterKey

      # gravatar?
      result = "<li><div>"
      for field in @displayFields
        value = @getItemFieldValueString item, field
        continue unless value?

        result += '<span class="field-'+field+'">'+value+'</span>\n'
      result += "</div>"

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


    setItemsFilterKey: (items, {force}={}) ->
      if force isnt true
        if items.length
          if items[0].filterKey
            return

      items.forEach (item) =>
        filterKey = ''
        filterKeyRanges = {}
        offset = 0
        for key in @getFilterKeyFields()
          value = @getItemFieldValueString item, key
          continue unless value?

          prefix = capitalize(key) + ": "
          offset += prefix.length

          filterKey += prefix + value + "\n"

          start = offset

          offset += value.length + 1

          filterKeyRanges[key] = [start, offset]

        item.filterKey = filterKey
        item.filterKeyRanges = filterKeyRanges

    setItems: (items) ->
      @setItemsFilterKey items
      super items

    setFilterKeyFields: (filterKeyFields) ->
      @filterKeyFields = filterKeyFields
      @setItemsFilterKey @items force: true

    getFilterKey: () ->
      # depends on some SmtpSettingsView
      return 'filterKey'

    confirmed: (item) ->
      #

    selectItemView: (view) ->
      result = super view
      @emitter.emit 'did-select-item', @getSelectedItem()
      return result

    onDidSelectItem: (callback) ->
      @emitter.on 'did-select-item', callback
