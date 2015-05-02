hangupsjs
=========

# Not finished

The client connects and sets up the necessary push channels. However no API-calls for sending/receiving chat message have been implemented.

## Summary

Client library for Google Hangouts in nodejs.

## Disclaimer

This library is in no way affiliated with or endorsed by Google. Use
at your own risk.

## Origins

Port of https://github.com/tdryer/hangups to node js.

I take no credit for the excellent work of Tom Dryer putting together
the original python client library for Google Hangouts. This port is
simply taking his work and porting it to coffeescript step by step.

## Usage

```
$ npm install hangupsjs
```

The client is started with `connect()` passing callback function for a
promise for a login object containing the credentials.

```coffee
Client = require 'hangupsjs'
Q      = require 'q'

creds = -> Q
    email: 'login@gmail.com'
    pass:  'mysecret'

client = new Client()

# set more verbose logging
client.loglevel 'debug'

client.connect(creds).done()
```

## License

Copyright (c) 2015 Martin Algesten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
