hangupsjs
=========

[![Greenkeeper badge](https://badges.greenkeeper.io/yakyak/hangupsjs.svg)](https://greenkeeper.io/)

### 2021-04-15 v1.4.0-beta

* Fix create conversation not working, and names showing up as Unknown

### 2021-04-15 v1.3.11

* Fix bad crash when we don't have any active conversations.

### 2020-07-07 v1.3.10

* Adds `VERSION` property to client

### 2020-06-16 v1.3.9

* Fix connection issues due to server changing data to an array ([#117](https://github.com/yakyak/hangupsjs/pull/117))

### 2018-11-08 v1.3.8

* Use the name instead of the key in AF_initDataChunkQueue. ([#107](https://github.com/yakyak/hangupsjs/pull/107))

### 2018-10-26 v1.3.7

* Fix email and self_entity changing ids server-side. And initial conv list ([#104](https://github.com/yakyak/hangupsjs/pull/104))
* update versions of modules

### 2017-11-16 v1.3.6

* Adds ability to modify OTR status
* Add client delivery medium type
* Update node version

### 2017-09-15 v1.3.5

* Adds additional fields to ENTITY schema
* Updates the subscribe method to only `babel` and `babel_presence_last_seen`


### 2016-12-05 v1.3.4

Add support for conversation metadata fetching

### 2016-12-01 v1.3.3

Fixes a breaking change of the google apis.

### 2016-01-15 v1.3.2

This is a minor release. It does not solve login problems that are related to
recent Google API changes. They have been solved in yakyak/yakyak client because
auth method there is different. That solution involves user interaction
therefore it can't be implemented hangupsjs library.

We are still looking for a solution.

### 2016-01-15 v1.3.0 breaking change

It seems the entities information that previously was available in the
init data is no longer there. Relying on these entities would now
break.

[tdryer](https://github.com/algesten/hangupsjs/issues/39#issuecomment-171853264)
pointed out that hangups have stopped doing this init data request,
since it's not necessary. hangupsjs should follow (soon) and remove
everything around pvt/init. this will be a major release.

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

The library is rather new and needs more tests, error handling etc.

## Usage

```bash
$ npm install hangupsjs
```

The client is started with `connect()` passing callback function for a
promise for a login object containing the credentials.

Example usage (javascript below):

```coffee
Client = require 'hangupsjs'
Q      = require 'q'

# callback to get promise for creds using stdin. this in turn
# means the user must fire up their browser and get the
# requested token.
creds = -> auth:Client.authStdin

client = new Client()

# set more verbose logging
client.loglevel 'debug'

# receive chat message events
client.on 'chat_message', (ev) ->
    console.log ev

# connect and post a message.
# the id is a conversation id.
client.connect(creds).then ->
    client.sendchatmessage('UgzJilj2Tg_oqkAaABAQ', [
        [0, 'Hello World']
    ])
.done()
```

The same example code in javascript:

```javascript
var Client = require('hangupsjs');
var Q = require('q');

// callback to get promise for creds using stdin. this in turn
// means the user must fire up their browser and get the
// requested token.
var creds = function() {
  return {
    auth: Client.authStdin
  };
};

var client = new Client();

// set more verbose logging
client.loglevel('debug');

// receive chat message events
client.on('chat_message', function(ev) {
  return console.log(ev);
});

// connect and post a message.
// the id is a conversation id.
client.connect(creds).then(function() {
    return client.sendchatmessage('UgzJilj2Tg_oqkAaABAQ',
    [[0, 'Hello World']]);
}).done();
```

## Long running sessions / reconnect

hangupsjs will not try to keep the connection open endlessly. the push
channel has some reconnect logic, but it will eventually back off with
a `connect_failed` event.

additionally the client also monitors activity. the push channel
receives events at least every 20-30 seconds, if there are no chat
events, we get a `noop`.

after a successful `connect()`, the client monitors the channel to
ensure we receive any event at least every 45 seconds. if 45 seconds
passes and the push channel got nothing, the client stops with a
`connect_failed` event.

### Example

To construct a client that just doesn't give up we do:

```javascript
var reconnect = function() {
    client.connect(creds).then(function() {
        // we are now connected. a `connected`
        // event was emitted.
    });
};

// whenever it fails, we try again
client.on('connect_failed', function() {
    Q.Promise(function(rs) {
        // backoff for 3 seconds
        setTimeout(rs,3000);
    }).then(reconnect);
});

// start connection
reconnect();
```

## API

### High Level API

High level API calls that are not doing direct hangouts calls.

#### `Client()`

`Client(opts)`

`opts.jarstore` (optional) instance of
[`Store`](https://github.com/SalesforceEng/tough-cookie) to use
instead of default file persistence for cookies.

`opts.cookiespath` (optional) path to file in which to store cached
login cookies. Defaults to `cookies.json` in module dir. not used
if `opts.jarstore` is passed.

`opts.rtokenpath` (optional) path to file in which to store the
oauth refresh token. Defaults to `refreshtoken.txt` in module dir.

`opts.proxy` (optional) proxy URL that gets passed to
request. Documentation is
[here](https://github.com/request/request#proxies)

#### `connect`

`connect: (creds) ->`

Attempts to connect the client to hangouts. See
[`isInited`](#isinited) for the steps that connects the client.
Returns a promise for connection. The promise only resolves when init
is completed. On the [`connected`](#connected) event.

`creds`: is callback that returns a promise for login creds. The creds
are either `{creds:-><promise for token>}` or
`{cookies:<array of strings or tough-cookie-jar>}`

##### email/pass

To login using an email/password combo, you need to login using OAuth
and provide the access token to the API. Furthermore it uses a google
white listed OAuth CLIENT\_ID and CLIENT\_SECRET that shows up as
"iOS Device" in your accounts page.

This is the login URL, also available as `Client.OAUTH2_LOGIN_URL`.

https://accounts.google.com/o/oauth2/auth?&client_id=936475272427.apps.googleusercontent.com&scope=https%3A%2F%2Fwww.google.com%2Faccounts%2FOAuthLogin&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code

The library provides a stdin-method that requests the token.

```coffee
creds = -> auth:Client.authStdin

client.connect(creds).then -> # and so on...
```

##### cookies

The other way to log in is to provide a string array of cookies for
the `google.com` domain that are set up as part of a successful login.

Typically these cookies are called: `NID`, `SID`, `HSID`, `SSID`,
`APISID`, `SAPISID`

Example:

```coffee
creds = -> Q {cookies:[
    'NID=67=QI6go9WM<redacted>WDFxv; Expires=Wed, 04 Nov 2015 06:10:24 GMT; Domain=google.com; Path=/; HttpOnly'
    'SID=DASDPgAAA<redacted>AKJASKJD; Expires=Thu, 04 May 2017 06:10:24 GMT; Domain=google.com; Path=/'
    'HSID=AR<redacted>QX_; Expires=Thu, 04 May 2017 06:10:24 GMT; Domain=google.com; Path=/; HttpOnly; Priority=HIGH'
    'SSID=Ak<redacted>D; Expires=Thu, 04 May 2017 06:10:24 GMT; Domain=google.com; Path=/; Secure; HttpOnly; Priority=HIGH'
    'APISID=kM<redacted>seXb; Expires=Thu, 04 May 2017 06:10:24 GMT; Domain=google.com; Path=/; Priority=HIGH'
    'SAPISID=cl<redacted>Od; Expires=Thu, 04 May 2017 06:10:24 GMT; Domain=google.com; Path=/; Secure; Priority=HIGH'
    ]}

client.connect(creds).then -> # and so on...
```


#### `disconnect`

`disconnect: ->`

Disconnects the client.


#### `isInited`

`isInited`

For Client to be fully inited the following must happen on
[`connect`](#connect)

1. Get login cookies against https://accounts.google.com/ServiceLogin
   or reuse cached cookies.

2. Using the cookies, fetch a PVT token (whatever that is) against
   https://talkgadget.google.com/talkgadget/_/extension-start

3. Load the chat widget HTML + javascript using the PVT token from
   https://talkgadget.google.com/u/0/talkgadget/_/chat

4. From the returned javascript get an `apikey` and some other headers
   used in each api call later.

5. Fetch channel `sid`/`gsid` from
   https://0.client-channel.google.com/client-channel/channel-bind

6. Using the `sid`/`gsid` open a long poll request against the same
   URL as in 5. This is the push data channel.

7. From first data coming through the push data channel, extract a
   `clientid` which also is used in each api call later.

8. Post a subscribe request against same URL as in 5 to make push data
   channel receive chat events.

Only after all these steps are completed will `isInited` return true.



#### `loglevel`

`loglevel: (level) ->`

Sets the log level one of `debug`, `info`, `warn` or `error`.


#### `logout`

`logout: () ->`

Logs the current client out by removing refresh token and cached cookies.

Example:

```coffee
# force cleared state
client.logout().then ->
    # will now require new credentials
    client.connect(creds)
.then ->
    ...
```

#### `MessageBuilder`

Helper to compose message `segments` that goes into
[`sendchatmessage`](#sendchatmessage). The builder has these methods.

Example:

```coffee
bld = new Client.MessageBuilder()
segments = bld.text('Hello ').bold('World').text('!!!').toSegments()
client.sendchatmessage('UgzfaJwj2Tg_oqk5EhEp5faABAQ', segments)
```

##### `builder.text(txt)`

`(txt, bold=false, italic=false, strikethrough=false, underline=false, href=null) ->`

Adds a text segment.

```coffee
builder.text('Hello')
```

##### `builder.bold(txt)`

Adds a text segment in bold.

##### `builder.italic(txt)`

Adds a text segment in italic.

##### `builder.strikethrough(txt)`

Adds a text segment strikethroughed.

##### `builder.underline(txt)`

Adds an underlined text segment.

##### `build.linebreak()`

Adds a new line.

##### `builder.link(txt, href)`

Adds a text that is a link.

##### `builder.toSegments`

Turns the builder into an array of segments usable for [`sendchatmessage`](#sendchatmessage).



### Low Level API

Each API call does a direct operation against hangouts. Each call
returns a promise for the result.

#### `sendchatmessage`

`sendchatmessage: (conversation_id,
                   segments,
                   image_id = None,
                   otr_status = OffTheRecordStatus.ON_THE_RECORD,
                   client_generated_id = null,
                   delivery_medium = [ClientDeliveryMediumType.BABEL],
                   message_action_type = [[MessageActionType.NONE, ""]]) ->`

Send a chat message to a conversation.

`conversation_id`: the conversation to send a message to.

`segments`: array of segments to send. See
[`messagebuilder`](#messagebuilder) for help.

`image_id`: is an optional ID of an image retrieved from
[`uploadimage`](#uploadimage). If provided, the image will be
attached to the # message.

`otr_status`: determines whether the message will be saved in the
server's chat history. Note that the OTR status of the conversation is
irrelevant, clients may send messages with whatever OTR status they
like. One of `Client.OffTheRecordStatus.OFF_THE_RECORD` or
`Client.OffTheRecordStatus.ON_THE_RECORD`.

`client_generated_id` is an identifier that is kept in the event both
in the result of this call and the following chat_event.  it can be
used to tie together a client send with the update from the
server. The default is `null` which makes the client generate a random
id.

`delivery_medium`: determines via which medium the message will be
delivered. If caller does not specify value we pick the value BABEL to
ensure the message is delivered via default medium. In fact the caller
should retrieve current conversation's default delivery medium from
self_conversation_state.delivery_medium_option when calling to ensure
the message is delivered back to the conversation on same medium always.

`message_action_type`: determines if the message is a simple text message
or if the message is an action like `/me`. One of `Client.MessageActionType.NONE`
or `Client.MessageActionType.ME_ACTION`

#### `setactiveclient`

`setactiveclient: (active, timeoutsecs) ->`

The active client receives notifications. This marks the client as active.

`active`: boolean indicating active state

`timeoutsecs`: the length of active in seconds.



#### `syncallnewevents`

`syncallnewevents: (timestamp) ->`

List all events occuring at or after timestamp. Timestamp can be a
date or long millis.

`timestamp`: date instance specifying the time after which to return
all events occuring in.



#### `getselfinfo`

`getselfinfo: ->`

Return information about your account.



#### `setconversationnotificationlevel`

`setconversationnotificationlevel: (conversation_id, level) ->`

Set the notification level of a conversation.

Pass `Client.NotificationLevel.QUIET` to disable notifications, or
`Client.NotificationLevel.RING` to enable them.



#### `setfocus`

`setfocus: (conversation_id, focus=FocusStatus.FOCUSED, timeoutsecs=20) ->`

Set focus (occurs whenever you give focus to a client).

`conversation_id`: the conversation you are focusing.

`typing`: constant indicating focus status. One of
`Client.FocusStatus.FOCUSED` or `Client.FocusStatus.UNFOCUSED`

`timeoutsecs`: the length of focus in seconds.



#### `settyping`

`settyping: (conversation_id, typing=TypingStatus.TYPING) ->`

Send typing notification.

`conversation_id`: the conversation you want to send typing
notification for.

`typing`: constant indicating typing status. One of
`Client.TypingStatus.TYPING`, `Client.TypingStatus.PAUSED` or
`Client.TypingStatus.STOPPED`



#### `setpresence`

`setpresence: (online, mood=None) ->`

Set the presence or mood of this client.

`online`: boolean indicating whether client is online.

`mood`: emoticon UTF-8 smiley like 0x1f603



#### `querypresence`

`querypresence: (chat_id) ->`

Check someone's presence status.

`chat_id`: the identifer of the user to check.



#### `removeuser`

`removeuser: (conversation_id) ->`

Remove self from chat.

`conversation_id`: the conversation to remove self from.



#### `deleteconversation`

`deleteconversation: (conversation_id) ->`

Delete one-to-one conversation.

`conversation_id`: the conversation to delete.



#### `updatewatermark`

`updatewatermark: (conversation_id, timestamp) ->`

Update the watermark (read timestamp) for a conversation.

`conversation_id`: the conversation to update the read timestamp for.

`timestamp`: the date or long millis to set as read timestamp.



#### `adduser`

`adduser: (conversation_id, chat_ids) ->`

Add user(s) to existing conversation.

`conversation_id`: the conversation to add user(s) to.

`chat_ids`: array of user chat_ids to add.



#### `renameconversation`

`renameconversation: (conversation_id, name) ->`

Set the name of a conversation.

`conversation_id`: the conversation to change.

`name`: the name to change to.



#### `createconversation`

`createconversation: (chat_ids, force_group=false) ->`

Create a new conversation.

`chat_ids`: is an array of chat_id which should be invited to
conversation (except yourself).

`force_group`: set to true if you invite just one chat_id, but still
want a group.

The new conversation ID is returned as `res.conversation.id.id`



#### `getconversation`

`getconversation: (conversation_id, timestamp, max_events=50) ->`

Return conversation events.

This is mainly used for retrieving conversation scrollback. Events
occurring before timestamp are returned, in order from oldest to
newest.

`conversation_id`: the conversation to get events in.

`timestamp`: the timestamp as long millis or date to get events
before.

`max_events`: number of events to retrieve.



#### `syncrecentconversations`

`syncrecentconversations: (timestamp_since=null) ->`

List the contents of recent conversations, including messages.
Similar to syncallnewevents, but returns a limited number of
conversations (20) rather than all conversations in a given
date range.

To get older conversations, use the timestamp_since parameter.



#### `searchentities`

`searchentities: (search_string, max_results=10) ->`

Search for people.

`search_string`: string to look for.

`max_results`: number of results to return.



#### `getentitybyid`

`getentitybyid: (chat_ids) ->`

Return information about a list of chat_ids.

`chat_ids`: array of user chat ids to get information for.



#### `sendeasteregg`

`sendeasteregg: (conversation_id, easteregg) ->`

Send an easteregg to a conversation.

`conversation_id`: conversation to bother.

`easteregg`: may not be empty. could be one of 'ponies', 'pitchforks',
'bikeshed', 'shydino'



#### `uploadimage`

`uploadimage: (path, filename=null, timeout=30000) ->`

Uploads an image that can be later attached to a chat message.

`imagefile` is a string path

`filename` can optionally be provided otherwise the path name is used.

`timeout` can be used to upload larger images, that may need more than 30 sec to be sent

returns an `image_id` that can be used in [`sendchatmessage`](#sendchatmessage).



## Events

The following events are available on the `Client` object. Example:

```coffee
client.on 'chat_message', (msg) ->
    # ... do something
```

### State events

#### `connecting`

When someone calls `client.connect()` and it indicates we are trying
to connect the client.

#### `connected`

When the client is fully inited and connected.

#### `connect_failed (err)`

Indicates that the client connection either didn't start or was
interrupted. Either way, the client will not try to connect again by
itself.  Another `client.connect` is required.

Emitted in three cases.

1. After `connecting` (in `client.connect()`) indicating that the
client could not connect at all.

2. After `connected` when running the polling (server push channel)
successfully, but is interrupted (such as lost network connection).

3. If the server push channel receives no events after 45 seconds
   (server emits at least `noop` every 20-30 seconds).

### Chat events

#### `chat_message`

On a received chat message.

#### `client_conversation`

Whenever an update about the conversation itself is needed. Like when
a new conversation is created, this event comes first with the
metadata about it.

The conversation state is stored in self_conversation_state of the event.
The self_conversation_state.delivery_medium_option contains an array of the
delivery medium options which indicate all possible medium. The array element
with current_default == true should be the one used to send message via by
default. Currently there are 3 types of known medium, BABEL, Google Voice and
SMS. BABEL is the Google Hangouts codename BTW.

#### `membership_change`

Member joining/leaving conversation.

#### `conversation_rename`

On a renamed conversation.

#### `focus`

When a user focuses a conversation.

#### `hangout_event`

On changes to video/audio calls. A "hangout" is in google API talk
strictly a video/audio event. `START_HANGOUT` and `END_HANGOUT` would
indicate attempts to start/end audio/video events.

#### `typing`

When a user is typing.

#### `watermark`

When a user updates their read timestamp.

#### `notification_level`

When user changes the notification level of his own
conversation. I.e. [setconversationnotificationlevel](#setconversationnotificationlevel).

[See #10](https://github.com/algesten/hangupsjs/issues/10)

#### `easter_egg`

When anyone in the conversation triggers an easter
egg.

[See #10](https://github.com/algesten/hangupsjs/issues/10)

#### `delete`

When a conversation is deleted by the user. As a response
to `deleteconversation`.

### To be investigated

The following events are possible and not investigated. Please tell me
in an [issue](https://github.com/algesten/hangupsjs/issues) if you figure one out.

* `conversation_notification`
* `reply_to_invite`
* `settings`
* `self_presence` [See #10](https://github.com/algesten/hangupsjs/issues/10)
* `presence` [See #10](https://github.com/algesten/hangupsjs/issues/10)
* `block`
* `invitation_watermark`



## License

Copyright © 2015 Martin Algesten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
