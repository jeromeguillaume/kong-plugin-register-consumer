#!/bin/bash

docker rm -f kong-register-consumer

docker run -d --name kong-register-consumer \
  --network=kong-net \
  --mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-register-consumer/kong/plugins/register-consumer,destination=/usr/local/share/lua/5.1/kong/plugins/register-consumer \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-database-register-consumer" \
  -e "KONG_PG_USER=kong" \
  -e "KONG_PG_PASSWORD=kongpass" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_PROXY_LISTEN=0.0.0.0:8000 reuseport backlog=16384, 0.0.0.0:8443 http2 ssl reuseport backlog=16384" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
  -e "KONG_ADMIN_API_URI=http://localhost:8001" \
  -e KONG_LICENSE_DATA \
  -e "KONG_ENFORCE_RBAC=on "\
  -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
  -e "KONG_ADMIN_GUI_SESSION_CONF={
    \"cookie_name\":\"kong_manager_session\",
    \"secret\":\"manager_secret\",
    \"storage\":\"kong\",
    \"cookie_secure\":false}"\
  -e "KONG_PLUGINS=bundled,register-consumer" \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -p 8002:8002 \
  -p 8445:8445 \
  -p 8003:8003 \
  -p 8004:8004 \
  kong/kong-gateway:3.0.0.0-alpine

echo "*** See logs container ***"
echo "docker logs kong-register-consumer -f"