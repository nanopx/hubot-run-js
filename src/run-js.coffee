# Description
#   A hubot script which executes JavaScript and outputs the result
#
# Commands:
#   #run ```<JavaScript>``` - Executes the code provided in <JavaScript>
#
# Author:
#   nanopx <0nanopx@gmail.com>

path = require('path').resolve __dirname, '../lib/jsSandbox.js'
child = require('child_process')
_ = require('lodash')

replaceQuotes = (code) ->
  code = code.replace('“', '"')
  code = code.replace('”', '"')
  code = code.replace('’', '\'')
  code = code.replace('‘', '\'')
  return code;

setupSandbox = (res, _code) ->
  code = replaceQuotes(_code)

  runJS = child.fork(path, [], {silent: true})

  runJS.stdout.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    if !/__EXEC_TIME__/.test(outputData)
      res.send("> Output:\n```#{outputData}```")
    else
      outputData = outputData.replace('__EXEC_TIME__: ', '')
      res.send("> Execution time: `#{outputData}`")

  runJS.stderr.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    res.send("Error:\n```#{outputData}```")

  runJS.on 'message', (msg) ->
    if msg.state == 'initialized'
      res.send('> Initializing script...')

    if msg.state == 'error'
      str = "> ERROR: `#{msg.error.name}`\n"
      str += "> Message: `#{msg.error.message}`\n"
      str += "> Stack:\n```#{msg.error.stack}```"
      res.send(str)

    if msg.state == 'success'
      str = "> Script executed successfully.\n"
      if !_.isEmpty(msg.usedVariables)
        str += "> Used variables: \n"
        for key, value of msg.usedVariables
          str += "> `#{key}: #{value}`\n"
      res.send(str)

  runJS.on 'error', (msg) ->
    res.send('> EXECUTION ERROR!')

  # runJS.on 'exit', (exitStatus) ->
  #   res.send("EXIT-> #{exitStatus}")

  runJS.send(code)

module.exports = (robot) ->

  robot.hear /#run ```(.*)```/, (res) ->
    setupSandbox(res, res.match[1])

  robot.hear /#run\n```(.*)```/, (res) ->
    setupSandbox(res, res.match[1])

  robot.hear /#run\n```\n(.*)\n```/, (res) ->
    setupSandbox(res, res.match[1])
