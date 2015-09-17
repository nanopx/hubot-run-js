var vm = require('vm');
var _ = require('lodash');

process.on('message', function(_code) {
  process.send({
    state: 'initialized',
  });

  var sandbox = {
    console: console,
    _: _,
    setTimeout: setTimeout,
  };

  // get time scores
  var code = 'console.time(\'__EXEC_TIME__\');' +
  _code + 'console.timeEnd(\'__EXEC_TIME__\');';

  try {
    var script = vm.createScript(code);
    script.runInNewContext(sandbox);
  } catch (e) {
    process.send({
      state: 'error',
      error: {
        name: e.name,
        message: e.message,
        stack: e.stack,
        code: e.code,
      },
    });
    process.exit(1);
  }

  delete sandbox.console;
  delete sandbox._;
  delete sandbox.setTimeout;

  process.send({
    state: 'success',
    usedVariables: sandbox
  });
  process.exit(0);
});
