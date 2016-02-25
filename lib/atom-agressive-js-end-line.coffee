{CompositeDisposable} = require 'atom'

emptyLine = /^\s*$/
objectLiteralLine = /^\s*[\w'"]+\s*\:\s*/m
continuationLine = /[\{\(;,]\s*$/

withActiveEditor = (action) ->
  action atom.workspace.getActiveTextEditor()

preservingSelections = (action) -> (editor) ->
  selections = editor.getSelectedBufferRanges()
  action editor
  editor.setSelectedBufferRanges selections

guessTerminator = (line) ->
  if objectLiteralLine.test line then ',' else ';'

collapsingHistory = (action) -> (editor) ->
  editor.transact action.bind(this, editor)

lastChar = (row) -> (editor) ->
  editor.lineTextForBufferRow row
    .slice -1

atEndOfLine = (line) -> (action) -> (editor) ->
  editor.setCursorBufferPosition [line]
  editor.moveToEndOfLine()
  action editor

removeTerminator = (line) -> (terminator) -> (editor) ->
  atEndOfLine(line)((editor) -> editor.backspace())(editor)

insertTerminator = (line) -> (terminator) -> (editor) ->
  atEndOfLine(line)((editor) -> editor.insertText(terminator))(editor)

action = {
  'remove terminator': removeTerminator,
  'insert terminator': insertTerminator
}

chooseAction = (line, terminator, editor) ->
  return 'remove terminator' if terminator is lastChar(line)(editor)
  return 'insert terminator'

toggleAtEndOfLine = (terminator) -> (editor) ->
  editor.getCursors().forEach (cursor) ->
    action[chooseAction cursor.getBufferRow(), terminator, editor](cursor.getBufferRow())(terminator)(editor)

unseenCommands = ->
  symbols = ';,'
  object = {}
  symbols
    .split ''
    .forEach (char) -> object["agressive-js-end-line:toggle-#{char}"] = -> withActiveEditor collapsingHistory preservingSelections toggleAtEndOfLine char
  object

seenCommands = ->
  symbols = ':.'
  object = {}
  symbols
    .split ''
    .forEach (char) -> object["agressive-js-end-line:toggle-#{char}"] = -> withActiveEditor collapsingHistory toggleAtEndOfLine char
  object

module.exports =
  activate: ->
    @subsctiptions = new CompositeDisposable
    @subsctiptions.add atom.commands.add 'atom-text-editor', unseenCommands()
    @subsctiptions.add atom.commands.add 'atom-text-editor', seenCommands()

  deactivate: ->
    @subsctiptions.dispose()
    @subsctiptions = null
