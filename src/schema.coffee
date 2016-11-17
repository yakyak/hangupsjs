{Field, BooleanField, EnumField, DictField, RepeatedField, Message} = require './pblite'

s = {}

None = ''

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

s.ClientDeliveryMediumType =

    UNKNOWN: 0
    BABEL: 1
    GOOGLE_VOICE: 2
    LOCAL_SMS: 3

s.ClientConversationStatus =

    UNKNOWN_CONVERSATION_STATUS : 0
    INVITED : 1
    ACTIVE : 2
    LEFT : 3

s.MessageActionType =

    NONE : 0
    ME_ACTION : 4

s.SegmentType =

    TEXT : 0
    LINE_BREAK : 1
    LINK : 2

s.ItemType =

    THING : 0
    PLUS_PHOTO : 249    # Google Plus Photo
    PLACE : 335         # Google Map Place
    PLACE_V2 : 340      # Google Map Place v2

s.MediaType =

    MEDIA_TYPE_UNKNOWN : 0
    MEDIA_TYPE_PHOTO : 1
    MEDIA_TYPE_ANIMATED_PHOTO : 4

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

s.InvitationStatus =

    UNKNOWN : 0
    PENDING : 1
    ACCEPTED : 2

s.ParticipantType =

    UNKNOWN : 0
    GAIA: 2
    GOOGLE_VOICE: 3

s.PhoneValidationResult =

    IS_POSSIBLE : 0

##############################################################################
# Structures
##############################################################################

s.USER_ID = Message([
    'gaia_id', Field()
    'chat_id', Field()
])

s.CLIENT_ENTITY = Message([
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
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
    None, Field() # 'cgsirp'
    None, Field() # response header
    'self_entity', s.CLIENT_ENTITY
])

s.CONVERSATION_ID = Message([
    'id', Field()
])

s.I18N_DATA = Message([
    'national_number', Field()
    'international_number', Field()
    'country_code', Field()
    'region_code', Field()
    'is_valid', BooleanField()
    'validation_result', EnumField(s.PhoneValidationResult)
])

s.PHONE_NUMBER = Message([
    'e164', Field()
    'i18n_data', s.I18N_DATA
])

s.CLIENT_DELIVERY_MEDIUM = Message([
    'delivery_medium_type', EnumField(s.ClientDeliveryMediumType)
    'phone_number', s.PHONE_NUMBER
])

s.CLIENT_DELIVERY_MEDIUM_OPTION = Message([
    'delivery_medium', s.CLIENT_DELIVERY_MEDIUM
    'current_default',  BooleanField()
    None, Field() # No idea what this is yet
])

s.CLIENT_CONVERSATION = Message([
    'conversation_id', s.CONVERSATION_ID
    'type', EnumField(s.ConversationType)
    'name', Field()
    'self_conversation_state', Message([
        None, Field()
        None, Field()
        None, Field()
        None, Field()
        None, Field()
        None, Field()
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
        None, Field()   # This one should be "invite_affinity"
        None, Field()   # No idea what this field is
        'delivery_medium_option', RepeatedField(s.CLIENT_DELIVERY_MEDIUM_OPTION)
        None, Field()
    ])
    None, Field()
    None, Field()
    None, Field()
    'read_state', RepeatedField(Message([
            'participant_id', s.USER_ID
            'last_read_timestamp', Field()
        ])
    )
    None, Field()
    'otr_status', EnumField(s.OffTheRecordStatus)
    None, Field()
    None, Field()
    'current_participant', RepeatedField(s.USER_ID)
    'participant_data', RepeatedField(Message([
            'id', s.USER_ID
            'fallback_name', Field()
            'invitation_status', EnumField(s.InvitationStatus)
            'phone_number', s.PHONE_NUMBER
            'participant_type', EnumField(s.ParticipantType)
            'new_invitation_status', EnumField(s.InvitationStatus)
    ]))
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
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

s.PLUS_PHOTO_THUMBNAIL = Message([
    'url', Field()
    None, Field()
    None, Field()
    'image_url', Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    'width_px', Field()
    'height_px', Field()
])

s.PLUS_PHOTO = Message([
    'thumbnail', s.PLUS_PHOTO_THUMBNAIL
    'owner_obfuscated_id', Field()
    'album_id', Field()
    'photo_id', Field()
    None, Field()
    'url', Field()
    None, Field()
    None, Field()
    None, Field()
    'original_content_url', Field()
    None, Field()
    None, Field()
    'media_type', EnumField(s.MediaType)
    'stream_id', RepeatedField(Field())
])

# Special numbers make up the property names of things in the embedded item
s.EMBED_ITEM = DictField({
    '27639957': s.PLUS_PHOTO,
    '35825640': Field()       # not supporting maps yet
})

s.MESSAGE_ATTACHMENT = Message([
    'embed_item', Message([
        'type', RepeatedField(EnumField(s.ItemType))
        'data', s.EMBED_ITEM    # this is a dictionary, which is like an ordinary object that has members that need to be looked up using a tag number
    ])
])

s.CLIENT_CHAT_MESSAGE = Message([
    None, Field()  # always None?
    'annotation', RepeatedField(Field()) # [0, ""] or [4, ""] 4 is the "/me" action
    'message_content', Message([
        'segment', RepeatedField(s.MESSAGE_SEGMENT)
        'attachment', RepeatedField(s.MESSAGE_ATTACHMENT)
    ])
])

s.CLIENT_MEMBERSHIP_CHANGE = Message([
    'type', EnumField(s.MembershipChangeType)
    None, RepeatedField(Field())
    'participant_ids', RepeatedField(s.USER_ID)
    None, Field()
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
    None, Field()  # always 1?
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
    None, Field()  # always ''?
    None, Field()  # always 0? (expiration_timestamp?)
    'chat_message', s.CLIENT_CHAT_MESSAGE
    None, Field()  # always ''?
    'membership_change', s.CLIENT_MEMBERSHIP_CHANGE
    'conversation_rename', s.CLIENT_CONVERSATION_RENAME
    'hangout_event', s.CLIENT_HANGOUT_EVENT
    'event_id', Field()
    'advances_sort_timestamp', Field()
    'otr_modification', s.CLIENT_OTR_MODIFICATION
    None, Field()  # 0, 1 or ''? related to notifications?
    'event_otr', EnumField(s.OffTheRecordStatus)
    None, Field()  # always 1? (advances_sort_timestamp?)
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
    None, Field()
    'event_continuation_token', s.CLIENT_EVENT_CONTINUATION_TOKEN
    None, Field()
    None, RepeatedField(Field())
])

s.CLIENT_CONVERSATION_STATE_LIST = RepeatedField(s.CLIENT_CONVERSATION_STATE)

s.CLIENT_ENTITY = Message([
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
    None, Field()
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
    None, Field() # always 0?
    None, Field() # some sort of ID
    'entities', RepeatedField(Message([
        'entity', s.CLIENT_ENTITY
        None, Field()  # always 0?
    ]))
])

s.INITIAL_CLIENT_ENTITIES = Message([
    None, Field()  # 'cgserp'
    None, Field()  # a header
    'entities', RepeatedField(s.CLIENT_ENTITY)
    None, Field()  # always ''?
    'group1', s.ENTITY_GROUP
    'group2', s.ENTITY_GROUP
    'group3', s.ENTITY_GROUP
    'group4', s.ENTITY_GROUP
    'group5', s.ENTITY_GROUP
])

s.CLIENT_STATE_UPDATE_HEADER = Message([
    'active_client_state', EnumField(s.ActiveClientState)
    None, Field(),
    'request_trace_id', Field()
    None, Field()
    'current_server_time', Field()
    None, Field()
    None, Field()
    # optional ID of the client causing the update?
    None, Field()
])

s.CLIENT_EVENT_NOTIFICATION = Message([
    'event', s.CLIENT_EVENT
])

s.CLIENT_SET_FOCUS_NOTIFICATION = Message([
    'conversation_id', s.CONVERSATION_ID
    'user_id', s.USER_ID
    'timestamp', Field()
    'status', EnumField(s.FocusStatus)
    'device', EnumField(s.FocusDevice)
])

s.CLIENT_SET_TYPING_NOTIFICATION = Message([
    'conversation_id', s.CONVERSATION_ID
    'user_id', s.USER_ID
    'timestamp', Field()
    'status', EnumField(s.TypingStatus)
])

s.CLIENT_WATERMARK_NOTIFICATION = Message([
    'participant_id', s.USER_ID
    'conversation_id', s.CONVERSATION_ID
    'latest_read_timestamp', Field()
])

s.CLIENT_STATE_UPDATE = Message([
    'state_update_header', s.CLIENT_STATE_UPDATE_HEADER
    'conversation_notification', Field()  # always None?
    'event_notification', s.CLIENT_EVENT_NOTIFICATION
    'focus_notification', s.CLIENT_SET_FOCUS_NOTIFICATION
    'typing_notification', s.CLIENT_SET_TYPING_NOTIFICATION
    'notification_level_notification', Field()
    'reply_to_invite_notification', Field()
    'watermark_notification', s.CLIENT_WATERMARK_NOTIFICATION
    None, Field(),
    'settings_notification', Field()
    'view_modification', Field()
    'easter_egg_notification', Field()
    'client_conversation_notification', s.CLIENT_CONVERSATION # deviation from python
    'self_presence_notification', Field()
    'delete_notification', Field()
    'presence_notification', Field()
    'block_notification', Field()
    'invitation_watermark_notification', Field()
])

s.CLIENT_RESPONSE_HEADER = Message([
    'status', Field()  # 1 => success
    None, Field()
    None, Field()
    'request_trace_id', Field()
    'current_server_time', Field()
])

s.CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE = Message([
    None, Field()  # 'csanerp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'sync_timestamp', Field()
    'conversation_state', RepeatedField(s.CLIENT_CONVERSATION_STATE)
])

s.CLIENT_GET_CONVERSATION_RESPONSE = Message([
    None, Field()  # 'cgcrp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'conversation_state', s.CLIENT_CONVERSATION_STATE
])

s.CLIENT_GET_ENTITY_BY_ID_RESPONSE = Message([
    None, Field()  # 'cgebirp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'entities', RepeatedField(s.CLIENT_ENTITY)
    'unknown', RepeatedField(Message([None, Field()
                                     'entities', RepeatedField(s.CLIENT_ENTITY)]))
])

module.exports = s
