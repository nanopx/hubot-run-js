# Description
#   A hubot script which executes JavaScript and outputs the result
#
# Commands:
#   #run ```<JavaScript>``` - Executes the code provided in <JavaScript>
#
# Author:
#   nanopx <0nanopx@gmail.com>

path = require('path').resolve __dirname, '../lib/jsSandbox.js'
readline = require('readline')
child = require('child_process')
_ = require('lodash')

replaceQuotes = (code) ->
  code = code.replace(/“/g, '"')
  code = code.replace(/”/g, '"')
  code = code.replace(/’/g, '\'')
  code = code.replace(/‘/g, '\'')
  return code;

setupSandbox = (lines, _code, cb) ->
  code = replaceQuotes(_code)

  sandbox = child.fork(path, [], {silent: true})

  # readline.createInterface
  #   input: sandbox.stdout,
  #   terminal: false
  # .on 'line', (line) ->

  sandbox.stdout.on 'data', (buf) ->
    line = String(buf).replace(/\n$/, '')
    if !/__EXEC_TIME__/.test(line)
      lines.push(line)
    else
      lines.push("```")
      lines.push("Execution time: `#{line.replace('__EXEC_TIME__: ', '')}`")

  sandbox.stderr.on 'data', (buf) ->
    outputData = String(buf).replace(/\n$/, '')
    lines.push("Error:\n```#{outputData}```")

  sandbox.on 'message', (msg) ->
    if msg.state == 'initialized'
      lines.push('Initializing script...')
      lines.push("Output:\n```")

    if msg.state == 'error'
      str = "Error: `#{msg.error.name}`\n"
      str += "Message: `#{msg.error.message}`\n"
      str += "Stack:\n```#{msg.error.stack}```"
      lines.push(str)

    if msg.state == 'success'
      str = "Script executed successfully.\n"
      if !_.isEmpty(msg.usedVariables)
        str += "Used variables: \n"
        for key, value of msg.usedVariables
          str += "`#{key}: #{value} (#{typeof value})`\n"
      lines.push(str)

  sandbox.on 'error', (msg) ->
    lines.push('EXECUTION ERROR!')

  sandbox.on 'exit', (exitStatus) ->
    cb(null, lines)
    # lines.push("EXIT-#{exitStatus}")

  sandbox.send(code)

runInSandbox = (msg, _code) ->
  code = replaceQuotes(_code)
  setupSandbox [], code, (err, lines) ->
    msg.send(">>> #{lines.join('\n')}")

module.exports = (robot) ->

  robot.hear /#run ```(.*)```/, (msg) ->
    runInSandbox(msg, msg.match[1])

  robot.hear /#run\n```(.*)```/, (msg) ->
    runInSandbox(msg, res.match[1])

  robot.hear /#run\n```\n([\s\S]*)\n```/, (res) ->
    runInSandbox(res, res.match[1])
