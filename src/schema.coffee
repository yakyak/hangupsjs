{Field, BooleanField, EnumField, DictField, NumberField, RepeatedField, Message} = require './pblite'

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

    UNKNOWN : 0
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

s.USER_ID = new Message([
    'gaia_id', new Field()
    'chat_id', new Field()
])

s.CLIENT_ENTITY = new Message([
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    'id', s.USER_ID
    'properties', new Message([
        'type',        new Field(), # 0, 1, or None
        'display_name', new Field()
        'first_name',   new Field()
        'photo_url',    new Field()
        'emails',       new RepeatedField(new Field())
        'phones',       new RepeatedField(new Field())
        None, new Field()
        None, new Field()
        None, new Field()
        'in_users_domain',  new Field()
        'gender',           new Field()
        'photo_url_status', new Field()
        None, new Field()
        None, new Field()
        'canonical_email',  new Field()
    ])
])

s.CLIENT_GET_SELF_INFO_RESPONSE = new Message([
    None, new Field() # 'cgsirp'
    None, new Field() # response header
    'self_entity', s.CLIENT_ENTITY
])

s.CONVERSATION_ID = new Message([
    'id', new Field()
])

s.I18N_DATA = new Message([
    'national_number', new Field()
    'international_number', new Field()
    'country_code', new Field()
    'region_code', new Field()
    'is_valid', new BooleanField()
    'validation_result', new EnumField(s.PhoneValidationResult)
])

s.PHONE_NUMBER = new Message([
    'e164', new Field()
    'i18n_data', s.I18N_DATA
])

s.CLIENT_DELIVERY_MEDIUM = new Message([
    'delivery_medium_type', new EnumField(s.ClientDeliveryMediumType)
    'phone_number', s.PHONE_NUMBER
])

s.CLIENT_DELIVERY_MEDIUM_OPTION = new Message([
    'delivery_medium', s.CLIENT_DELIVERY_MEDIUM
    'current_default',  new BooleanField()
    None, new Field() # No idea what this is yet
])

s.CLIENT_CONVERSATION = new Message([
    'conversation_id', s.CONVERSATION_ID
    'type', new EnumField(s.ConversationType)
    'name', new Field()
    'self_conversation_state', new Message([
        None, new Field()
        None, new Field()
        None, new Field()
        None, new Field()
        None, new Field()
        None, new Field()
        'self_read_state', new Message([
            'participant_id', s.USER_ID
            'latest_read_timestamp', new NumberField()
        ])
        'status', new EnumField(s.ClientConversationStatus)
        'notification_level', new EnumField(s.ClientNotificationLevel)
        'view', new RepeatedField(new EnumField(s.ClientConversationView))
        'inviter_id', s.USER_ID
        'invite_timestamp', new NumberField()
        'sort_timestamp', new NumberField()
        'active_timestamp', new NumberField()
        None, new Field()   # This one should be "invite_affinity"
        None, new Field()   # No idea what this field is
        'delivery_medium_option', new RepeatedField(s.CLIENT_DELIVERY_MEDIUM_OPTION)
        None, new Field()
    ])
    None, new Field()
    None, new Field()
    None, new Field()
    'read_state', new RepeatedField(new Message([
            'participant_id', s.USER_ID
            'last_read_timestamp', new NumberField()
        ])
    )
    None, new Field()
    'otr_status', new EnumField(s.OffTheRecordStatus)
    None, new Field()
    None, new Field()
    'current_participant', new RepeatedField(s.USER_ID)
    'participant_data', new RepeatedField(new Message([
            'id', s.USER_ID
            'fallback_name', new Field()
            'invitation_status', new EnumField(s.InvitationStatus)
            'phone_number', s.PHONE_NUMBER
            'participant_type', new EnumField(s.ParticipantType)
            'new_invitation_status', new EnumField(s.InvitationStatus)
    ]))
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
])

s.MESSAGE_SEGMENT = new Message([
    'type', new EnumField(s.SegmentType)
    'text', new Field()  # Can be None for linebreaks
    'formatting', new Message([
        'bold', new Field()
        'italic', new Field()
        'strikethrough', new Field()
        'underline', new Field()
    ])
    'link_data', new Message([
        'link_target', new Field()
    ])
])

s.PLUS_PHOTO_THUMBNAIL = new Message([
    'url', new Field()
    None, new Field()
    None, new Field()
    'image_url', new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    'width_px', new Field()
    'height_px', new Field()
])

s.PLUS_PHOTO = new Message([
    'thumbnail', s.PLUS_PHOTO_THUMBNAIL
    'owner_obfuscated_id', new Field()
    'album_id', new Field()
    'photo_id', new Field()
    None, new Field()
    'url', new Field()
    None, new Field()
    None, new Field()
    None, new Field()
    'original_content_url', new Field()
    None, new Field()
    None, new Field()
    'media_type', new EnumField(s.MediaType)
    'stream_id', new RepeatedField(new Field())
])

# Special numbers make up the property names of things in the embedded item
s.EMBED_ITEM = new Message([
    'type_', new RepeatedField(new Field()) # new EnumField(s.ItemType))
    'data', new Field()
    'plus_photo', new DictField({
        '27639957': [s.PLUS_PHOTO, 'data'],
    })
    'places', new DictField({
        '35825640': [new Field(), 'data']
    })
])

s.MESSAGE_ATTACHMENT = new Message([
    #'type_', new RepeatedField(new EnumField(s.ItemType))
    #'data', new Field()
    'embed_item', s.EMBED_ITEM
])

s.CLIENT_CHAT_MESSAGE = new Message([
    None, new Field()  # always None?
    'annotation', new RepeatedField(new Field()) # [0, ""] or [4, ""] 4 is the "/me" action
    'message_content', new Message([
        'segment', new RepeatedField(s.MESSAGE_SEGMENT)
        'attachment', new RepeatedField(s.MESSAGE_ATTACHMENT)
    ])
])

s.CLIENT_MEMBERSHIP_CHANGE = new Message([
    'type', new EnumField(s.MembershipChangeType)
    None, new RepeatedField(new Field())
    'participant_ids', new RepeatedField(s.USER_ID)
    None, new Field()
])

s.CLIENT_CONVERSATION_RENAME = new Message([
    'new_name', new Field()
    'old_name', new Field()
])

s.CLIENT_HANGOUT_EVENT = new Message([
    'event_type', new EnumField(s.ClientHangoutEventType)
    'participant_id', new RepeatedField(s.USER_ID)
    'hangout_duration_secs', new Field()
    'transferred_conversation_id', new Field()  # always None?
    'refresh_timeout_secs', new Field()
    'is_periodic_refresh', new Field()
    None, new Field()  # always 1?
])

s.CLIENT_OTR_MODIFICATION = new Message([
    'old_otr_status', new EnumField(s.OffTheRecordStatus)
    'new_otr_status', new EnumField(s.OffTheRecordStatus)
    'old_otr_toggle', new EnumField(s.ClientOffTheRecordToggle)
    'new_otr_toggle', new EnumField(s.ClientOffTheRecordToggle)
])

s.CLIENT_EVENT = new Message([
    'conversation_id', s.CONVERSATION_ID
    'sender_id', s.USER_ID
    'timestamp', new NumberField()
    'self_event_state', new Message([
        'user_id', s.USER_ID
        'client_generated_id', new Field()
        'notification_level', new EnumField(s.ClientNotificationLevel)
    ]),
    None, new Field()  # always ''?
    None, new Field()  # always 0? (expiration_timestamp?)
    'chat_message', s.CLIENT_CHAT_MESSAGE
    None, new Field()  # always ''?
    'membership_change', s.CLIENT_MEMBERSHIP_CHANGE
    'conversation_rename', s.CLIENT_CONVERSATION_RENAME
    'hangout_event', s.CLIENT_HANGOUT_EVENT
    'event_id', new Field()
    'advances_sort_timestamp', new NumberField()
    'otr_modification', s.CLIENT_OTR_MODIFICATION
    None, new Field()  # 0, 1 or ''? related to notifications?
    'event_otr', new EnumField(s.OffTheRecordStatus)
    None, new Field()  # always 1? (advances_sort_timestamp?)
])

s.CLIENT_EVENT_CONTINUATION_TOKEN = new Message([
    'event_id', new Field()
    'storage_continuation_token', new Field()
    'event_timestamp', new NumberField()
])

s.CLIENT_CONVERSATION_STATE = new Message([
    'conversation_id', s.CONVERSATION_ID
    'conversation', s.CLIENT_CONVERSATION
    'event', new RepeatedField(s.CLIENT_EVENT)
    None, new Field()
    'event_continuation_token', s.CLIENT_EVENT_CONTINUATION_TOKEN
    None, new Field()
    None, new RepeatedField(new Field())
])

s.CLIENT_CONVERSATION_STATE_LIST = new RepeatedField(s.CLIENT_CONVERSATION_STATE)

s.ENTITY_GROUP = new Message([
    None, new Field() # always 0?
    None, new Field() # some sort of ID
    'entities', new RepeatedField(new Message([
        'entity', s.CLIENT_ENTITY
        None, new Field()  # always 0?
    ]))
])

s.INITIAL_CLIENT_ENTITIES = new Message([
    None, new Field()  # 'cgserp'
    None, new Field()  # a header
    'entities', new RepeatedField(s.CLIENT_ENTITY)
    None, new Field()  # always ''?
    'group1', s.ENTITY_GROUP
    'group2', s.ENTITY_GROUP
    'group3', s.ENTITY_GROUP
    'group4', s.ENTITY_GROUP
    'group5', s.ENTITY_GROUP
])

s.CLIENT_STATE_UPDATE_HEADER = new Message([
    'active_client_state', new EnumField(s.ActiveClientState)
    None, new Field(),
    'request_trace_id', new Field()
    None, new Field()
    'current_server_time', new Field()
    None, new Field()
    None, new Field()
    # optional ID of the client causing the update?
    None, new Field()
])

s.CLIENT_EVENT_NOTIFICATION = new Message([
    'event', s.CLIENT_EVENT
])

s.CLIENT_SET_FOCUS_NOTIFICATION = new Message([
    'conversation_id', s.CONVERSATION_ID
    'user_id', s.USER_ID
    'timestamp', new NumberField()
    'status', new EnumField(s.FocusStatus)
    'device', new EnumField(s.FocusDevice)
])

s.CLIENT_SET_TYPING_NOTIFICATION = new Message([
    'conversation_id', s.CONVERSATION_ID
    'user_id', s.USER_ID
    'timestamp', new NumberField()
    'status', new EnumField(s.TypingStatus)
])

s.CLIENT_WATERMARK_NOTIFICATION = new Message([
    'participant_id', s.USER_ID
    'conversation_id', s.CONVERSATION_ID
    'latest_read_timestamp', new NumberField()
])

s.CLIENT_STATE_UPDATE = new Message([
    'state_update_header', s.CLIENT_STATE_UPDATE_HEADER
    'conversation_notification', new Field()  # always None?
    'event_notification', s.CLIENT_EVENT_NOTIFICATION
    'focus_notification', s.CLIENT_SET_FOCUS_NOTIFICATION
    'typing_notification', s.CLIENT_SET_TYPING_NOTIFICATION
    'notification_level_notification', new Field()
    'reply_to_invite_notification', new Field()
    'watermark_notification', s.CLIENT_WATERMARK_NOTIFICATION
    None, new Field(),
    'settings_notification', new Field()
    'view_modification', new Field()
    'easter_egg_notification', new Field()
    'client_conversation_notification', s.CLIENT_CONVERSATION # deviation from python
    'self_presence_notification', new Field()
    'delete_notification', new Field()
    'presence_notification', new Field()
    'block_notification', new Field()
    'invitation_watermark_notification', new Field()
])

s.CLIENT_RESPONSE_HEADER = new Message([
    'status', new Field()  # 1 => success
    None, new Field()
    None, new Field()
    'request_trace_id', new Field()
    'current_server_time', new Field()
])

s.CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE = new Message([
    None, new Field()  # 'csanerp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'sync_timestamp', new NumberField()
    'conversation_state', new RepeatedField(s.CLIENT_CONVERSATION_STATE)
])

s.CLIENT_GET_CONVERSATION_RESPONSE = new Message([
    None, new Field()  # 'cgcrp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'conversation_state', s.CLIENT_CONVERSATION_STATE
])

s.CLIENT_GET_ENTITY_BY_ID_RESPONSE = new Message([
    None, new Field()  # 'cgebirp'
    'response_header', s.CLIENT_RESPONSE_HEADER
    'entities', new RepeatedField(s.CLIENT_ENTITY)
])

s.CLIENT_CREATE_CONVERSATION_RESPONSE = new Message([
    None, new Field()
    'response_header', s.CLIENT_RESPONSE_HEADER
    'conversation', s.CLIENT_CONVERSATION
])

s.CLIENT_SEARCH_ENTITIES_RESPONSE = new Message([
    None, new Field()
    'response_header', s.CLIENT_RESPONSE_HEADER
    'entity', new RepeatedField(s.CLIENT_ENTITY)
])

module.exports = s
