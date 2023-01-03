{readFileSync} = require 'fs'

getLogWithQuote = (proc) ->
  logQuote =
    try
      createTailQuote readFileSync(proc.logPath, 'utf8'), 20
    catch err
      "(failed to load log: #{err.message})"

  """
  Log output (last 20 lines):

  #{logQuote}

  See the full log at: #{proc.logPath}
  """

procCrashedError = (proc) ->
  message =
    """
    Process \"#{proc.name}\" crashed with code #{proc.exitCode}.
    #{getLogWithQuote proc}
    """
  message += "\n#{proc.error.trim()}" if proc.error?.length > 0
  new Error message

niceTime = (ms) ->
  if ms > 1000 * 60
    "#{ms / 1000 / 60}min"
  else if ms > 1000
    "#{ms / 1000}s"
  else
    "#{ms}ms"

createTailQuote = (str, count) ->
  lines = str.split('\n').slice(-count)
  "> #{lines.join '\n> '}"

procTimedoutError = (proc, port, timeout) ->
  formatArguments = (args = []) ->
    return '(no arguments)' unless args.length
    args.join('\n           ')

  message =
    """
    Process \"#{proc.name}\" did not start in time.

    Debug info:
    * command: #{proc.launchCommand}
               #{formatArguments proc.launchArguments}
    * cwd:     #{proc.workingDirectory}
    * port:    #{port}
    * timeout: #{niceTime timeout}
    ```

    #{getLogWithQuote proc}
    """
  message += "\n#{proc.error.trim()}" if proc.error?.length > 0
  new Error message

module.exports = (proc, validate, interval, timeout, port, callback) ->
  if proc.rawProcess.exitCode?
    error = procCrashedError(proc)
    return callback(error)

  procName = proc.name

  startTime = Date.now()

  check = ->
    validate port, (error, isReady) ->
      if proc.rawProcess.exitCode?
        error = procCrashedError(proc)
        return callback(error)

      return callback(error) if error?

      if isReady
        callback()
      else
        if (Date.now() - startTime) >= timeout
          try proc.rawProcess.kill()
          return callback(procTimedoutError proc, port, timeout)
        setTimeout(check, 100)

  check()

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

