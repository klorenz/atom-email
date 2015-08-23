{SelectListView, $$} = require('atom-space-pen-views')

module.exports =
  class FolderView extends SelectListView
    initialize: ->
      super
      @addClass "email-folder"
      @setMaxItems 100
      @panel = atom.workspace.addModalPanel(item: this)

    updateItems: (folderInfo) ->
      items = []
      for key,values of folderInfo
        continue if values.length == 0
        if key is not "Other"
          items.push v[0]
        else
          for value in values
            items.push value

      @setItems items

    getFilterKey: ->
      'path'

    viewForItem: ({name, path}) ->
      $$ ->
        @li =>
          @div name
          @div path

    show: ->    @panel.show()
