# Janus WebRTC Example with Phoenix and WebSockets!

start server Janus
- docker pull voxo/janus-gateway
- docker run -it -d --ulimit nofile=65536:65536 --network="host" --restart always voxo/janus-gateway

- docker run -it -d --ulimit nofile=65536:65536 --network="128.199.216.34" --restart always voxo/janus-gateway

To start your Janus and Phoenix servers:

- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `cd assets && yarn`
- Start Janus via docker with `docker-compose up`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more about Janus

- Official website: https://janus.conf.meetecho.com/
- Docs: https://janus.conf.meetecho.com/docs/
- Mailing list: https://groups.google.com/forum/#!forum/meetecho-janus
- Source: https://github.com/meetecho/janus-gateway
