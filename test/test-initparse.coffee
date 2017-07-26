{assert} = require('chai')
deql = assert.deepEqual

{CLIENT_GET_SELF_INFO_RESPONSE
INITIAL_CLIENT_ENTITIES,
CLIENT_CONVERSATION_STATE_LIST,
EMBED_ITEM} = require '../src/schema'

msg1 = ["cgsirp",[1,null,"","1950326504872917925",1430493729941000],[null,null,null,null,null,null,null,[1,0,[],null,null,null,null,null,[[]]],["102224360723365489932","102224360723365489932"],[1,"Bo Tenström","Bo","//lh5.googleusercontent.com/-99B0CMsSo68/AAAAAAAAAAI/AAAAAAAAABI/v8oOeHFwNSI/photo.jpg",["botenstrom2@gmail.com"],[],null,null,null,null,null,2,[],[]],null,null,2,null,0,0,0],0,[],[0,null,0],[0],[[],[],2],[[8,0],[9,1],[22,0],[19,1],[10,1],[11,1],[14,0],[20,0],[17,0],[16,0],[23,0],[24,0],[27,0],[5,1],[6,1],[1,0],[2,1],[7,1],[3,1],[4,1],[29,1],[13,0],[12,0],[15,0],[28,0]],[1],1,[1,1],[null,[],[[5,0],[4,0],[2,0],[6,1],[1,0],[3,1]]],1,1,0,2,[],1,["SE",46],[],null,[1]]

cmp1 = {
  "self_entity": {
    "id": {
      "gaia_id": "102224360723365489932",
      "chat_id": "102224360723365489932"
    },
    "properties": {
      "type": 1,
      "display_name": "Bo Tenström",
      "first_name": "Bo",
      "photo_url": "//lh5.googleusercontent.com/-99B0CMsSo68/AAAAAAAAAAI/AAAAAAAAABI/v8oOeHFwNSI/photo.jpg",
      "canonical_email": null,
      "in_users_domain": null,
      "gender": null,
      "phones": [],
      "photo_url_status": 2,
      "emails": [
        "botenstrom2@gmail.com"
      ]
    }
  }
}

describe 'CLIENT_GET_SELF_INFO_RESPONSE', ->

    it 'parses', ->
        deql CLIENT_GET_SELF_INFO_RESPONSE.parse(msg1), cmp1


msg2 = ["cgserp",[1,null,"","-7303892207317438164",1430552593677000],[],null,[0,"XrPb1g==",[[[null,null,null,null,null,null,null,null,["110994664963851875523","110994664963851875523"],[1,"Martin Algesten","Martin","//lh5.googleusercontent.com/-R7AuYVncPys/AAAAAAAAAAI/AAAAAAAAAIw/incUIqFokok/photo.jpg",[],[],null,null,null,0,null,2,[],[]],null,null,2,null,1,1,0],0],[[null,null,null,null,null,null,null,null,["105510613398923491294","105510613398923491294"],[1,"Bo Tenström","Bo","//lh6.googleusercontent.com/-Xg2kTTvP-1o/AAAAAAAAAAI/AAAAAAAAABY/buSUZUepxPY/photo.jpg",[],[],null,null,null,0,null,2,[],[]],null,null,2,null,1,1,0],0]]],[0,"KCC4Ng==",[[[null,null,null,null,null,null,null,null,["105510613398923491294","105510613398923491294"],[1,"Bo Tenström","Bo","//lh6.googleusercontent.com/-Xg2kTTvP-1o/AAAAAAAAAAI/AAAAAAAAABY/buSUZUepxPY/photo.jpg",[],[],null,null,null,0,null,2,[],[]],null,null,2,null,1,1,0],1],[[null,null,null,null,null,null,null,null,["110994664963851875523","110994664963851875523"],[1,"Martin Algesten","Martin","//lh5.googleusercontent.com/-R7AuYVncPys/AAAAAAAAAAI/AAAAAAAAAIw/incUIqFokok/photo.jpg",[],[],null,null,null,0,null,2,[],[]],null,null,2,null,1,1,0],2]]],[0,"AAAAAA==",[]],[0,"AAAAAA==",[]],[0,"AAAAAA==",[]],[0,"AAAAAA==",[]]]

cmp2 = {
  "entities": [],
  "group1": {
    "entities": [
      {
        "entity": {
          "id": {
            "gaia_id": "110994664963851875523",
            "chat_id": "110994664963851875523"
          },
          "properties": {
            "type": 1,
            "display_name": "Martin Algesten",
            "first_name": "Martin",
            "photo_url": "//lh5.googleusercontent.com/-R7AuYVncPys/AAAAAAAAAAI/AAAAAAAAAIw/incUIqFokok/photo.jpg",
            "canonical_email": null,
            "in_users_domain": 0,
            "gender": null,
            "phones": [],
            "photo_url_status": 2,
            "emails": []
          }
        }
      },
      {
        "entity": {
          "id": {
            "gaia_id": "105510613398923491294",
            "chat_id": "105510613398923491294"
          },
          "properties": {
            "type": 1,
            "display_name": "Bo Tenström",
            "first_name": "Bo",
            "photo_url": "//lh6.googleusercontent.com/-Xg2kTTvP-1o/AAAAAAAAAAI/AAAAAAAAABY/buSUZUepxPY/photo.jpg",
            "canonical_email": null,
            "in_users_domain": 0,
            "gender": null,
            "phones": [],
            "photo_url_status": 2,
            "emails": []
          }
        }
      }
    ]
  },
  "group2": {
    "entities": [
      {
        "entity": {
          "id": {
            "gaia_id": "105510613398923491294",
            "chat_id": "105510613398923491294"
          },
          "properties": {
            "type": 1,
            "display_name": "Bo Tenström",
            "first_name": "Bo",
            "photo_url": "//lh6.googleusercontent.com/-Xg2kTTvP-1o/AAAAAAAAAAI/AAAAAAAAABY/buSUZUepxPY/photo.jpg",
            "canonical_email": null,
            "in_users_domain": 0,
            "gender": null,
            "phones": [],
            "photo_url_status": 2,
            "emails": []
          }
        }
      },
      {
        "entity": {
          "id": {
            "gaia_id": "110994664963851875523",
            "chat_id": "110994664963851875523"
          },
          "properties": {
            "type": 1,
            "display_name": "Martin Algesten",
            "first_name": "Martin",
            "photo_url": "//lh5.googleusercontent.com/-R7AuYVncPys/AAAAAAAAAAI/AAAAAAAAAIw/incUIqFokok/photo.jpg",
            "canonical_email": null,
            "in_users_domain": 0,
            "gender": null,
            "phones": [],
            "photo_url_status": 2,
            "emails": []
          }
        }
      }
    ]
  },
  "group3": {
    "entities": []
  },
  "group4": {
    "entities": []
  },
  "group5": {
    "entities": []
  }
}

describe 'INITIAL_CLIENT_ENTITIES', ->

    it 'parses', ->
        deql INITIAL_CLIENT_ENTITIES.parse(msg2), cmp2


msg3 = [[["UgxjmN5ygMnYI6ZRPZp4AaABAQ"],[["UgxjmN5ygMnYI6ZRPZp4AaABAQ"],1,null,[null,null,null,null,null,null,[["102224360723365489932","102224360723365489932"],1430497808139701],2,30,[1],["102224360723365489932","102224360723365489932"],1430497801138000,1430497808139701,1430497801138000,null,null,[[[2,["+14011234567",["(401) 123-4567","+1 401-123-4567",1,"US",0,0]]],0,1]],0],[],[],null,[[["105510613398923491294","105510613398923491294"],0],[["102224360723365489932","102224360723365489932"],1430497808139701]],0,2,1,1,[["102224360723365489932","102224360723365489932"],["105510613398923491294","105510613398923491294"]],[[["105510613398923491294","105510613398923491294"],"Bo Tenström",1,null,2,1],[["102224360723365489932","102224360723365489932"],"Bo Tenström",2,["+14017654321",["(401) 765-4321","+1 401-765-4321",1,"US",1,0]                    ],3,2]],null,0,null,[1],1],[[["UgxjmN5ygMnYI6ZRPZp4AaABAQ"],["102224360723365489932","102224360723365489932"],1430497808139701,[["102224360723365489932","102224360723365489932"],"1289503288794"],null,0,[null,[],[[[0,"hey",[0,0,0,0]]],[]]],null,null,null,null,"7zbr7sUt_No7zbr8i4WRTa",null,null,1,2,1,null,null,[1],null,null,1,1430497808139701]],null,null,null,[]],[["UgzJilj2Tg_oqk5EhEp4AaABAQ"],[["UgzJilj2Tg_oqk5EhEp4AaABAQ"],1,null,[null,null,null,null,null,null,[["102224360723365489932","102224360723365489932"],1430497844252252],2,30,[1],["110994664963851875523","110994664963851875523"],1430497826216000,1430497904083513,1430497840649000,null,null,[[[1],1]],0],[],[],null,[[["102224360723365489932","102224360723365489932"],1430497844252252],[["110994664963851875523","110994664963851875523"],0]],0,2,1,1,[["110994664963851875523","110994664963851875523"],["102224360723365489932","102224360723365489932"]],[[["102224360723365489932","102224360723365489932"],"Bo Tenström",2,null,2,2],[["110994664963851875523","110994664963851875523"],"Martin Algesten",2,null,2,2]],null,0,null,[1],1],[[["UgzJilj2Tg_oqk5EhEp4AaABAQ"],["110994664963851875523","110994664963851875523"],1430497831165769,[["102224360723365489932","102224360723365489932"]],null,0,[null,[],[[[0,"the second",[0,0,0,0]]],[]]],null,null,null,null,"7zbrAwdAT-g7zbrBWycNlt",null,null,1,2,1,null,null,[1],null,null,1,1430497831165769],[["UgzJilj2Tg_oqk5EhEp4AaABAQ"],["102224360723365489932","102224360723365489932"],1430497844252252,[["102224360723365489932","102224360723365489932"],"260429275674"],null,0,[null,[],[[[0,"test123",[0,0,0,0]]],[]]],null,null,null,null,"7zbrAwdAT-g7zbrD7DR5bM",null,null,1,2,1,null,null,[1],null,null,1,1430497844252252],[["UgzJilj2Tg_oqk5EhEp4AaABAQ"],["110994664963851875523","110994664963851875523"],1430497904083513,[["102224360723365489932","102224360723365489932"]],null,0,[null,[],[[[0,"the second one",[0,0,0,0]]],[]]],null,null,null,null,"7zbrAwdAT-g7zbrKQdW4ZV",null,null,1,2,1,null,null,[1],null,null,1,1430497904083513]],null,null,null,[]]]

cmp3 = require './convstate.json'

describe 'CLIENT_CONVERSATION_STATE_LIST', ->

    it 'parses', ->
        deql CLIENT_CONVERSATION_STATE_LIST.parse(msg3), cmp3

msg4 = [['249'], '' ,  { "27639957": [["https://plus.google.com/photos/albums/p16geqve3h5t3tqdn4odhtha2j5lqkale?pid=6275042227379600450&oid=103730981268153889186", null, null, "https://lh3.googleusercontent.com/-QUwpEWamKew/VxVtqMGJfEI/AAAAAAAAAFM/jeRZI6e_DUIZkUVdhXoNbQNiY8UxBGvwwCK8B/s0/2016-04-18.jpg", null, null, null, null, null, 768, 401], "103730981268153889186", "6272415246136908337", "6275042227379600450", null, "https://lh3.googleusercontent.com/-QUwpEWamKew/VxVtqMGJfEI/AAAAAAAAAFM/jeRZI6e_DUIZkUVdhXoNbQNiY8UxBGvwwCK8B/s0/2016-04-18.jpg", null, null, null, "https://lh3.googleusercontent.com/nUIH-qp7Cgeei1PAAdirnxrtS2Ryc6A2Tai2gzOdR0oIAPxhIj9BtSkTkYQWxalPvr4", null, null, 1, ["shared_group_6275042227379600450", "BABEL_STREAM_ID", "BABEL_UNIQUE_ID_1e30efc4-8f46-4f58-ab52-c2b8ec77a3a7"]] }, '']

cmp4 = {
  'type_': ['249'],
  'data': "",
  'places': null,
  'plus_photo': {"data":{"album_id":"6272415246136908337","media_type":"MEDIA_TYPE_PHOTO","original_content_url":"https://lh3.googleusercontent.com/nUIH-qp7Cgeei1PAAdirnxrtS2Ryc6A2Tai2gzOdR0oIAPxhIj9BtSkTkYQWxalPvr4","owner_obfuscated_id":"103730981268153889186","photo_id":"6275042227379600450","stream_id":["shared_group_6275042227379600450","BABEL_STREAM_ID","BABEL_UNIQUE_ID_1e30efc4-8f46-4f58-ab52-c2b8ec77a3a7"],"thumbnail":{"height_px":401,"image_url":"https://lh3.googleusercontent.com/-QUwpEWamKew/VxVtqMGJfEI/AAAAAAAAAFM/jeRZI6e_DUIZkUVdhXoNbQNiY8UxBGvwwCK8B/s0/2016-04-18.jpg","url":"https://plus.google.com/photos/albums/p16geqve3h5t3tqdn4odhtha2j5lqkale?pid=6275042227379600450&oid=103730981268153889186","width_px":768},"url":"https://lh3.googleusercontent.com/-QUwpEWamKew/VxVtqMGJfEI/AAAAAAAAAFM/jeRZI6e_DUIZkUVdhXoNbQNiY8UxBGvwwCK8B/s0/2016-04-18.jpg"}}}

describe 'EMBED_ITEM', ->

    it 'parses', ->
        deql EMBED_ITEM.parse(msg4), cmp4
