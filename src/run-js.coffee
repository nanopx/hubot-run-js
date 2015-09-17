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

setupSandbox = (res, code) ->
  runJS = child.fork(path, [], {silent: true})

  runJS.stdout.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    if !/__EXEC_TIME__/.test(outputData)
      res.send("Result:\n```#{outputData}```")
    else
      outputData = outputData.replace('__EXEC_TIME__: ', '')
      res.send("Execution time:\n`#{outputData}`")

  runJS.stderr.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    res.send("Error:\n```#{outputData}```")

  runJS.on 'message', (msg) ->
    if msg.state == 'initialized'
      res.send('Initializing script...')

    if msg.state == 'error'
      str = "> ERROR: `#{msg.error.name}`\n"
      str += "> Message: `#{msg.error.message}`\n"
      str += "> Stack:\n```#{msg.error.stack}```"
      res.send(str)

    if msg.state == 'success'
      str = "> Script executed successfully.\nUsed variables: \n"
      for key, value of msg.usedVariables
        str += "`#{key}: #{value}`\n"
      res.send(str)


  runJS.on 'error', (msg) ->
    res.send('ERR->', msg)

  runJS.on 'exit', (exitStatus) ->
    res.send("EXIT-> #{exitStatus}")

  runJS.send(code)

module.exports = (robot) ->

  robot.hear /#run ```(.*)```/, (res) ->
    setupSandbox(res, res.match[1])
