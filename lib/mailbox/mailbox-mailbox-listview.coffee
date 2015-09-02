{$$, SelectListView} = require "atom-space-pen-views"
{match} = require 'fuzzaldrin'

module.exports =
class MailboxListView extends SelectListView
  initialize: ({@mailboxEditor}) ->
    super
    @addClass "mailbox-list-view"

    @mailboxEditor.onDidGetMailboxes (mailboxes) =>
      console.log "got mailboxes"
      @setItems mailboxes

    @mailboxEditor.onDidRequestShowMailboxSelector =>
      @show()

    # trigger fetching mailboxes
    # @mailboxEditor.getMailboxes().then =>
    #   console.log "got mailboxes"
    @mailboxEditor.getMailboxes().catch (error) =>
      console.log error
      atom.notifications.addError "Error getting Mailboxes", detail: "#{error}", stack: error.stack, dismissable: true

  getFilterKey: -> 'path'

  viewForItem: (item) =>
    slices = []
    filterQuery = @getFilterQuery()
    matches = match item.path, filterQuery

    $$ ->
      highlighter = (path, matches, offsetIndex=0) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit path matches
          unmatched = path.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(path[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text path.substring(lastIndex)

      @li => highlighter(item.path, matches)

  confirmed: (item) =>
    @mailboxEditor.selectMailbox item.path
    @panel.hide()

  cancelled: =>
    @panel.hide()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()
