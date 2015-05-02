{Field, EnumField, RepeatedField, Message} = require './pblite'

s = {}

##############################################################################
# Enums
##############################################################################

s.TypingStatus =

    TYPING : 1  # The user started typing
    PAUSED : 2  # The user stopped typing with inputted text
    STOPPED : 3  # The user stopped typing with no inputted text


s.FocusStatus =

    FOCUSED : 1
    UNFOCUSED : 2


s.FocusDevice =

    DESKTOP : 20
    MOBILE : 300
    UNSPECIFIED : 0


s.ConversationType =

    STICKY_ONE_TO_ONE : 1
    GROUP : 2


s.ClientConversationView =

    UNKNOWN_CONVERSATION_VIEW : 0
    INBOX_VIEW : 1
    ARCHIVED_VIEW : 2


s.ClientNotificationLevel =

    UNKNOWN : 0
    QUIET : 10
    RING : 30


s.ClientConversationStatus =

    UNKNOWN_CONVERSATION_STATUS : 0
    INVITED : 1
    ACTIVE : 2
    LEFT : 3


s.SegmentType =

    TEXT : 0
    LINE_BREAK : 1
    LINK : 2


s.MembershipChangeType =

    JOIN : 1
    LEAVE : 2


s.ClientHangoutEventType =

    # Not sure all of these are correct
    START_HANGOUT : 1
    END_HANGOUT : 2
    JOIN_HANGOUT : 3
    LEAVE_HANGOUT : 4
    HANGOUT_COMING_SOON : 5
    ONGOING_HANGOUT : 6


s.OffTheRecordStatus =

    OFF_THE_RECORD : 1
    ON_THE_RECORD : 2


s.ClientOffTheRecordToggle =

    ENABLED : 0
    DISABLED : 1


s.ActiveClientState =

    NO_ACTIVE_CLIENT : 0
    IS_ACTIVE_CLIENT : 1
    OTHER_CLIENT_IS_ACTIVE : 2


s.USER_ID = Message([
    'gaia_id', Field()
    'chat_id', Field()
])

s.CLIENT_ENTITY = Message([
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    'id', s.USER_ID
    'properties', Message([
        'type',        Field(), # 0, 1, or None
        'display_name', Field()
        'first_name',   Field()
        'photo_url',    Field()
        'emails',       RepeatedField(Field())
    ])
])

s.CLIENT_GET_SELF_INFO_RESPONSE = Message([
    '', Field() # 'cgsirp'
    '', Field() # response header
    'self_entity', s.CLIENT_ENTITY
])

s.CONVERSATION_ID = Message([
    'id', Field()
])

s.CLIENT_CONVERSATION = Message([
    'conversation_id', s.CONVERSATION_ID
    'type', EnumField(s.ConversationType)
    'name', Field()
    'self_conversation_state', Message([
        '', Field()
        '', Field()
        '', Field()
        '', Field()
        '', Field()
        '', Field()
        'self_read_state', Message([
            'participant_id', s.USER_ID
            'latest_read_timestamp', Field()
        ])
        'status', EnumField(s.ClientConversationStatus)
        'notification_level', EnumField(s.ClientNotificationLevel)
        'view', RepeatedField(EnumField(s.ClientConversationView))
        'inviter_id', s.USER_ID
        'invite_timestamp', Field()
        'sort_timestamp', Field()
        'active_timestamp', Field()
        '', Field()
        '', Field()
        '', Field()
        '', Field()
    ])
    '', Field()
    '', Field()
    '', Field()
    'read_state', RepeatedField(Message([
            'participant_id', s.USER_ID
            'last_read_timestamp', Field()
        ])
    )
    '', Field()
    'otr_status', EnumField(s.OffTheRecordStatus)
    '', Field()
    '', Field()
    'current_participant', RepeatedField(s.USER_ID)
    'participant_data', RepeatedField(Message([
            'id', s.USER_ID
            'fallback_name', Field()
            '', Field()
    ]))
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
])

s.MESSAGE_SEGMENT = Message([
    'type', EnumField(s.SegmentType)
    'text', Field()  # Can be None for linebreaks
    'formatting', Message([
        'bold', Field()
        'italic', Field()
        'strikethrough', Field()
        'underline', Field()
    ])
    'link_data', Message([
        'link_target', Field()
    ])
])

s.CLIENT_CHAT_MESSAGE = Message([
    '', Field()  # always ''?
    'annotation', RepeatedField(Field())
    'message_content', Message([
        'segment', RepeatedField(s.MESSAGE_SEGMENT)
        'attachment', RepeatedField(s.MESSAGE_ATTACHMENT)
    ])
])

s.CLIENT_MEMBERSHIP_CHANGE = Message([
    'type', EnumField(s.MembershipChangeType)
    '', RepeatedField(Field())
    'participant_ids', RepeatedField(s.USER_ID)
    '', Field()
])

s.CLIENT_CONVERSATION_RENAME = Message([
    'new_name', Field()
    'old_name', Field()
])

s.CLIENT_HANGOUT_EVENT = Message([
    'event_type', EnumField(s.ClientHangoutEventType)
    'participant_id', RepeatedField(s.USER_ID)
    'hangout_duration_secs', Field()
    'transferred_conversation_id', Field()  # always None?
    'refresh_timeout_secs', Field()
    'is_periodic_refresh', Field()
    '', Field()  # always 1?
])

s.CLIENT_OTR_MODIFICATION = Message([
    'old_otr_status', EnumField(s.OffTheRecordStatus)
    'new_otr_status', EnumField(s.OffTheRecordStatus)
    'old_otr_toggle', EnumField(s.ClientOffTheRecordToggle)
    'new_otr_toggle', EnumField(s.ClientOffTheRecordToggle)
])

s.CLIENT_EVENT = Message([
    'conversation_id', s.CONVERSATION_ID
    'sender_id', s.USER_ID
    'timestamp', Field()
    'self_event_state', Message([
        'user_id', s.USER_ID
        'client_generated_id', Field()
        'notification_level', EnumField(s.ClientNotificationLevel)
    ]),
    '', Field()  # always ''?
    '', Field()  # always 0? (expiration_timestamp?)
    'chat_message', s.CLIENT_CHAT_MESSAGE
    '', Field()  # always ''?
    'membership_change', s.CLIENT_MEMBERSHIP_CHANGE
    'conversation_rename', s.CLIENT_CONVERSATION_RENAME
    'hangout_event', s.CLIENT_HANGOUT_EVENT
    'event_id', Field()
    'advances_sort_timestamp', Field()
    'otr_modification', s.CLIENT_OTR_MODIFICATION
    '', Field()  # 0, 1 or ''? related to notifications?
    'event_otr', EnumField(s.OffTheRecordStatus)
    '', Field()  # always 1? (advances_sort_timestamp?)
])

s.CLIENT_EVENT_CONTINUATION_TOKEN = Message([
    'event_id', Field()
    'storage_continuation_token', Field()
    'event_timestamp', Field()
])

s.CLIENT_CONVERSATION_STATE = Message([
    'conversation_id', s.CONVERSATION_ID
    'conversation', s.CLIENT_CONVERSATION
    'event', RepeatedField(s.CLIENT_EVENT)
    '', Field()
    'event_continuation_token', s.CLIENT_EVENT_CONTINUATION_TOKEN
    '', Field()
    '', RepeatedField(Field())
])

s.CLIENT_CONVERSATION_STATE_LIST = RepeatedField(s.CLIENT_CONVERSATION_STATE)

s.CLIENT_ENTITY = Message([
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    '', Field()
    'id', s.USER_ID
    'properties', Message([
        'type', Field()  # 0, 1, or ''
        'display_name', Field()
        'first_name', Field()
        'photo_url', Field()
        'emails', RepeatedField(Field())
    ])
])

s.ENTITY_GROUP = Message([
    '', Field() # always 0?
    '', Field() # some sort of ID
    'entities', RepeatedField(Message([
        'entity', s.CLIENT_ENTITY
        '', Field()  # always 0?
    ]))
])

s.INITIAL_CLIENT_ENTITIES = Message([
    '', Field()  # 'cgserp'
    '', Field()  # a header
    'entities', RepeatedField(s.CLIENT_ENTITY)
    '', Field()  # always ''?
    'group1', s.ENTITY_GROUP
    'group2', s.ENTITY_GROUP
    'group3', s.ENTITY_GROUP
    'group4', s.ENTITY_GROUP
    'group5', s.ENTITY_GROUP
])

module.exports = s
