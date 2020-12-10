# Audio room with Janus WebRTC

## Demo

1. Create room
- create tunnel to server:
    + `ssh -L 4000:localhost:4000 phung@128.199.216.34`
    + pass: 123
- user1 join room "abc":
    `http://localhost:4000/rooms/abc`
- user2 join room "abc":
    `http://localhost:4000/rooms/abc`

2. Mute example user:
- call api to get list user: 
    `curl -X GET http://128.199.216.34:4000/rooms`

    example response:
    `{"data":{"abc":{"participants":[2380907743310782,8813342264517907],"room_id":98228475}}}`

- mute user with ID = 2380907743310782 in room_id = 98228475
    `curl -X PUT http://128.199.216.34:4000/admin/mute/true/98228475/2380907743310782`

## To start your Janus and Phoenix servers:

- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `cd assets && yarn`
- Start Janus via docker with `docker-compose up`
- Start Phoenix endpoint with `mix phx.server`

Now you can join a room (example "abc")with `http://localhost:4000/rooms/abc` from your browser.


 ## Learn more about Janus

- Official website: https://janus.conf.meetecho.com/
- Docs: https://janus.conf.meetecho.com/docs/
- Mailing list: https://groups.google.com/forum/#!forum/meetecho-janus
- Source: https://github.com/meetecho/janus-gateway