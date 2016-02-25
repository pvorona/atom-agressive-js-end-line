{CompositeDisposable} = require 'atom'

withActiveEditor = (action) ->
  action atom.workspace.getActiveTextEditor()

preservingSelections = (action) -> (editor) ->
  selections = editor.getSelectedBufferRanges()
  action editor
  editor.setSelectedBufferRanges selections

collapsingHistory = (action) -> (editor) ->
  editor.transact action.bind(this, editor)

atEndOfLine = (line) -> (action) -> (editor) ->
  editor.setCursorBufferPosition [line]
  editor.moveToEndOfLine()
  action editor

lastChar = (row, editor) ->
  editor
    .lineTextForBufferRow row
    .slice -1

removeTerminator = (line, terminator, editor) ->
  atEndOfLine(line)((editor) -> editor.backspace())(editor)

insertTerminator = (line, terminator, editor) ->
  atEndOfLine(line)((editor) -> editor.insertText(terminator))(editor)

match = {
  'remove terminator': removeTerminator,
  'insert terminator': insertTerminator
}

action = (line, terminator, editor) ->
  if terminator is lastChar line, editor then 'remove terminator' else 'insert terminator'

toggleAtEndOfLine = (terminator) -> (editor) ->
  editor.getCursors().forEach (cursor) ->
    match[action cursor.getBufferRow(), terminator, editor] cursor.getBufferRow(), terminator, editor

generateCommands = (symbols, action) ->
  object = {}
  symbols
    .split ''
    .forEach (char) -> object["agressive-js-end-line:toggle-#{char}"] = action char
  object

module.exports =
  activate: ->
    @subsctiptions = new CompositeDisposable
    @subsctiptions.add atom.commands.add 'atom-text-editor', generateCommands ';,', (char) -> -> withActiveEditor collapsingHistory preservingSelections toggleAtEndOfLine char
    @subsctiptions.add atom.commands.add 'atom-text-editor', generateCommands ':.', (char) -> -> withActiveEditor collapsingHistory toggleAtEndOfLine char

  deactivate: ->
    @subsctiptions.dispose()
