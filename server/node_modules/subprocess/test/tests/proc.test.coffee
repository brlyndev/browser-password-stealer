sub = require '../../lib'
assert = require 'assertive'

currentProcesses = null

# if mocha crashes, the child process
# running our tests won't clean itself
# up properly; so, we have to do this
process.on 'uncaughtException', (error) ->
  sub.killAll(currentProcesses) if currentProcesses?
  console.error error.stack
  process.exit(1)

runSub = (config, done, callback) ->
  sub config, (error, _processes) ->
    # save off the current processes
    # so that we can kill them
    # (1) if mocha crashes or
    # (2) afterEach test
    currentProcesses = _processes

    # if an error is thrown async,
    # the mocha process crashes;
    # this allows the test suite to
    # keep running
    try
      callback(error, currentProcesses)
    catch testError
      done(testError)

describe 'sub', ->
  afterEach ->
    sub.killAll(currentProcesses) if currentProcesses?
    currentProcesses = null

  describe 'starts a process', ->
    before (done) ->
      config =
        app:
          command: 'node'
          commandArgs: ['test/apps/service.js', '%port%']
          logFilePath: 'test/log/start-proc.log'
          port: 9903

      runSub config, done, (error, processes) =>
        @proc = processes?.app
        done(error)

    it 'has rawProcess.pid', ->
      assert.truthy 'process.rawProcess.pid', @proc.rawProcess.pid

    it 'has baseUrl', ->
      assert.equal 'process.baseUrl', 'http://127.0.0.1:9903', @proc.baseUrl

    it 'has port', ->
      assert.equal 'process.port', 9903, @proc.port

    it 'has logPath', ->
      assert.match 'process.logPath', /test\/log\/start-proc\.log$/, @proc.logPath

    it 'has logHandle', ->
      assert.equal 'process.logHandle', 'number', typeof @proc.logHandle

    it 'has launchCommand', ->
      assert.equal 'process.launchCommand', 'node', @proc.launchCommand

    it 'has launchArguments', ->
      assert.deepEqual 'process.launchArguments', ['test/apps/service.js', '9903'], @proc.launchArguments

    it 'has workingDirectory', ->
      assert.equal 'process.workingDirectory', 'string', typeof @proc.workingDirectory

  it 'allows custom verification', (done) ->
    forceError = new Error 'force failure'

    config =
      app:
        command: 'node'
        commandArgs: ['test/apps/service.js', '%port%']
        logFilePath: 'test/log/custom-verification.log'
        port: 6501
        verify: (port, callback) ->
          callback(forceError)

    runSub config, done, (error, processes) ->
      assert.equal forceError, error
      done()

  it 'passes along spawn options', (done) ->
    config =
      app:
        command: 'node'
        commandArgs: ['test/apps/env-echo.js']
        logFilePath: 'test/log/spawn-opts.log'
        port: 9933
        verify: (port, callback) ->
          callback(null, true)
        spawnOpts:
          env:
            testResult: 100

    runSub config, done, (error, processes) ->
      return done(error) if error?

      # wait a little bit for the process
      # to actually write out to the log file;
      # yes, arbitrary delays are bad
      setTimeout ( ->
        processes.app.readLog (error, log) ->
          return done(error) if error?
          try
            assert.include '100', log
            done()
          catch testError
            done(testError)
      ), 100

  it 'allows arbitrary verification timeouts', (done) ->
    config =
      app:
        command: 'node'
        commandArgs: ['test/apps/hang.js']
        logFilePath: 'test/log/timeout.log'
        verifyTimeout: 10
        verify: (port, callback) ->
          callback(null, false) # not yet ready

    runSub config, done, (error, processes) ->
      assert.include 'timeout: 10ms', error.message
      done()

  it 'shows the log when a process errors', (done) ->
    config =
      app:
        command: 'node'
        commandArgs: ['test/apps/error.js', '%port%']
        logFilePath: 'test/log/process-error.log'

    runSub config, done, (error, _processes) ->
      assert.include 'intentional failure', error.message
      done()

  it 'starts dependant processes', (done) ->
    serviceReady = false

    config =
      app:
        dependsOn: ['service']
        command: 'node'
        commandArgs: ['test/apps/service.js', '%port%']
        logFilePath: 'test/log/dep-app.log'
        port: 6500
        verify: (port, callback) ->
          return callback(new Error 'service not yet started') if !serviceReady
          callback(null, true)

      service:
        command: 'node'
        commandArgs: ['test/apps/service.js', '%port%']
        logFilePath: 'test/log/dep-service.log'
        verify: (port, callback) ->
          serviceReady = true
          callback(null, true) # no error

    runSub config, done, (error, processes) ->
      done(error)

