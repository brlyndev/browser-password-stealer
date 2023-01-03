portscanner = require 'portscanner'
async = require 'async'
{merge, clone} = require 'lodash'
port = require './port'

openLogFile = require './log'
spawn = require './spawn'
verify = require './verify'


convert = (proc) ->
  proc = merge {}, defaults(proc.name), proc
  proc.spawnOpts.cwd ?= process.cwd()

  (callback) ->
    openLogFile proc.spawnOpts.cwd, proc.logFilePath, (error, results) ->
      return callback(error) if error?
      {fd: logHandle, filename: logPath} = results

      spawnOpts =
        stdio: [ 'ignore', logHandle, logHandle ]
        env: clone(process.env)
      merge spawnOpts, proc.spawnOpts

      port.findOpen proc.port, (error, availablePort) ->
        return callback(error) if error?

        child = spawn(proc.name, proc.command, proc.commandArgs, availablePort, logPath, logHandle, spawnOpts)

        verify child, proc.verify, proc.verifyInterval, proc.verifyTimeout, availablePort, (error) ->
          return callback(error) if error?
          callback(null, child)


autoable = (name, proc) ->
  proc.name = name
  func = convert(proc)

  if proc.dependsOn?.length > 0
    array = clone(proc.dependsOn)
    array.push(func)
    array
  else
    func

defaults = (procName) ->
  port: 0 # get random available port
  logFilePath: "./log/#{procName}.log"
  spawnOpts: {}
  verifyInterval: 100
  verifyTimeout: 3000
  verify: (port, callback) ->
    portscanner.checkPortStatus port, '127.0.0.1', (error, status) ->
      return callback(error) if error?
      return callback(null, false) if status == 'closed'

      callback(null, true)

subprocess = (processConfig, callback) ->
  config = {}
  for key in Object.keys(processConfig)
    config[key] = autoable(key, processConfig[key])

  async.auto config, (error, procs) ->
    return callback(error) if error?
    callback(null, procs)

subprocess.killAll = (procs) ->
  for key, value of procs
    value.rawProcess.kill()

module.exports = subprocess


###
Copyright (c) 2015, Groupon, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

Neither the name of GROUPON nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

