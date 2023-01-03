# subprocess

subprocess is a child process management library for Node.js.
It handles startup, port management, availability checking, and teardown
of a series of child processes.

It's like an [`async.auto`](https://github.com/caolan/async#auto)
for processes.
Note that the depedencies are registered
as the property `dependsOn`
instead of preceding elements in an array.

This project is a safe and inclusive place
for contributors of all kinds.
See the [Code of Conduct](CODE_OF_CONDUCT.md)
for details.


## install

```bash
npm install --save subprocess
```

## usage

```js
var subprocess = require('subprocess');

var config = {
  processName: {
    dependsOn: ['<other proc name>', ...],  // optional dependant processes
                                            // differs from async.auto in syntax
    command: 'node',
    commandArgs: ['index.js', '%port%'],    // %port% is replaced with the port
    port: 9999,                             // omit to get a random available port
    logPath: './log/process.log',           // file path to log file for stdio
    spawnOptions: {},                       // options to pass to child_process.spawn

    verifyInterval: 100,                    // ms, default
    verifyTimeout: 3000,                    // ms, default

    // optional, defaults to checking for something listening on the port
    // called every `verifyInterval` until `verifyTimeout` or
    // the callback says it's ready
    verify: function(port, callback){
      // custom verification logic

      // `error` means to stop checking for availability
      // `isAvailable=false` means to keep checking
      // `isAvailable=true` means that the process is up and ready
      callback(error, isAvailable);
    }
  }
};

subprocess(config, function(error, processes){
  // `error` can be a custom error thrown
  // by the verify function or it can be
  // an subprocess-specific error;
  // see the errors section for more info

  /*
  processes = {
    processName: {
      rawProcess: [ChildProcess],
      baseUrl: "http://127.0.0.1:9999",
      port: 9999,
      logPath: './log/process.log',
      logHandle: [LogHandle],
      launchCommand: 'node',
      launchArguments: ['index.js', '9999'],
      workingDirectory: '~/someplace'
    }
  }
  */
});
```

All processes started this way will be
automatically registered to kill themselves
on `process.on('uncaughtException', handler)`.


### `subprocess.killAll`

subprocess exposes a method that
can kill all of your processes for you.

```js
subprocess(config, function(error, processes){
  if (error) throw error;

  // do some things

  subprocess.killAll(processes);
});
```

You don't have to use this method
to kill all processes.
The point of subprocess is that it
will kill these for you when the
main process exits.
However, if you want to manage this yourself,
this is how you do it.


## example

```js
var subprocess = require('subprocess');
var request = require('request');

var processes = {
  app: {
    dependsOn: ['service'],
    command: 'node',
    commandArgs: ['index.js', '--port=%port%'],
    port: 4500
  },

  service: {
    command: 'node',
    commandArgs: ['service.js', '--port=%port%'],
    verify: function(port, callback){
      request('http://localhost:'+port+'/status', function(error, response, body){
        var isReady = !error && response.statusCode == 200;
        callback(null, isReady);
      });
    }
  }
};

subprocess(processes, function(error, processes){
  if (error) {
    console.error(error.stack);
    process.exit(1);
  }
  console.log('processes started successfully!');
});
```

## errors

### command not found

When the `command` string is passed to the system
and a `NOENT` error is returned,
subprocess will callback with an error with message:

```
Unable to find <command>
```

### process crashed

When a process started by subprocess crashes
before it can be verified,
subprocess will callback with an error with message:

```
Process <processName> crashed with code <exitCode>.
Log output (last 20 lines):

>
> <log output>
>

See the full log at: <log path>
<original error message>
```

### process verification timeout

When a process appears to start propertly,
but cannot be verified before the `verifyTimeout`,
subprocess will callback with an error with message:

```
Process <processName> did not start in time.

Debug info:
* command: <command>
           <command arguments>
* cwd:     <working directory>
* port:    <port>
* timeout: <timeout>

Log output (last 20 lines):

>
> <log output>
>

See the full log at: <log path>
<original error message>
```

