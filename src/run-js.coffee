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
  code = code.replace(/“/g, '"')
  code = code.replace(/”/g, '"')
  code = code.replace(/’/g, '\'')
  code = code.replace(/‘/g, '\'')
  return code;

setupSandbox = (res, _code) ->
  code = replaceQuotes(_code)

  runJS = child.fork(path, [], {silent: true})

  runJS.stdout.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    if !/__EXEC_TIME__/.test(outputData)
      res.send("> Output:\n```#{outputData}```")
    else
      console.log(1, outputData)
      outputData = outputData.split('__EXEC_TIME__: ', '')
      console.log(2, outputData)

      if outputData.length == 1
        res.send("> Execution time: `#{outputData[0]}`")
      else if outputData.length == 2
        res.send("> Output:\n```#{outputData[0].replace('\n', '')}```")
        res.send("> Execution time: `#{outputData[1]}`")

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
          str += "> `#{key}: #{value} (#{typeof value})`\n"
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

  robot.hear /#run\n```\n([\s\S]*)\n```/, (res) ->
    setupSandbox(res, res.match[1])
