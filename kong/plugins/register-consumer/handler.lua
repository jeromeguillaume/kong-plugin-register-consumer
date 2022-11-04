-- handler.lua

local registerConsumer = {
    PRIORITY = 1,
    VERSION = "0.1",
  }

----------------------------------------------------------------------------------
-- Executed after the whole response has been received from the upstream service,
-- but before sending any part of it to the client
----------------------------------------------------------------------------------
function registerConsumer:response(plugin_conf)
    kong.log.debug("registerConsumer response(): BEGIN")
    
    kong.log.debug("registerConsumer response(): END")
end

------------------------------------------------------
-- Executed for every request from a client and 
-- before it is being proxied to the upstream service
------------------------------------------------------
function registerConsumer:access(plugin_conf)
  kong.log.debug("registerConsumer access(): BEGIN")
  
  local http = require "resty.http"
  local httpc = http.new()

  ---------------------------------
  -- Call the user register on IdP
  ---------------------------------
  kong.request.get_path_with_query()

  local idp_body_req  = kong.request.get_raw_body()
  local idp_header_authorization = kong.request.get_header ("Authorization")

  kong.log.debug("registerConsumer IdP Request body=" .. idp_body_req)
  kong.log.debug("registerConsumer IdP Request Authorization=" .. idp_header_authorization)

  local res, err = httpc:request_uri(plugin_conf.idp_client_registration_endpoint, {
    method = "POST",
    headers = {
      ["Accept"] = "application/json",
      ["Content-Type"] = "application/json",
      ["Authorization"] = idp_header_authorization,
    },
    query = {
      -- 
    },
    body = idp_body_req,
    keepalive_timeout = 60,
    keepalive_pool = 10
  })
  
  if err then
    return nil, err
  end
  
  local status = res.status
  
  if status >= 300 then
    return kong.response.exit(status, "{\
      \"Error Code\": " .. status .. ",\
      \"Error Message\": \"IdP Register: failure to register a new Client in the IdP \"\
      }",
      {
      ["Content-Type"] = "application/json"
      }
    )
  end

  ---------------------------------------
  -- Get Body from IdP User Registration
  ---------------------------------------
  local idp_body_res = res.body
  kong.log.debug("registerConsumer IdP Response body=" .. idp_body_res)

  local cjson = require("cjson.safe").new()
  local json_idp_body_res, err = cjson.decode(idp_body_res)
  if err then
    return nil, err
  end

  -- kong.log.debug("registerConsumer IdP Response data=" .. json_idp_body_res.data)
  -- local json2, err = cjson.decode(json_idp_body_res.data)
  -- kong.log.debug("registerConsumer IdP Response data.client_id=" .. json2.client_id)
  -- local client_id = json2.client_id
  -- local registration_access_token = json2.registration_access_token
  -- kong.log.debug("registerConsumer IdP Response registration_access_token=" .. registration_access_token)
  
  local client_id = json_idp_body_res.client_id
  local registration_access_token = json_idp_body_res.registration_access_token

  if client_id == nil or registration_access_token == nil then
    return kong.response.exit(500, "{\
      \"Error Code\": 500 ,\
      \"Error Message\": \"IdP Register: Unable to get 'client_id' or 'registration_access_token'\"\
      }",
      {
      ["Content-Type"] = "application/json"
      }
    )
  end  
  
  kong.log.debug("registerConsumer IdP Response client_id=" .. client_id)
  kong.log.debug("registerConsumer IdP Response registration_access_token=" .. registration_access_token)

  -----------------------------------
  -- Kong Admin API: create customer
  -----------------------------------
  local res, err = httpc:request_uri(plugin_conf.kong_admin_api .. "/consumers", {
    method = "POST",
    headers = {
      ["Kong-Admin-Token"] = plugin_conf.kong_admin_token,
      ["Content-Type"] = "application/json",
    },
    body = "{\
      \"username\": \""  .. client_id .. "\",\
      \"custom_id\": \"" .. client_id .. "\",\
      \"tags\": [\"" .. registration_access_token .. "\"]\
      }",
    keepalive_timeout = 60,
    keepalive_pool = 10
  })
  
  if err then
    return nil, err
  end
  
  status = res.status
  kong.log.debug("registerConsumer Admin API - Create Customer - Body response=" .. res.body)
  
  if status >= 300 then
    return kong.response.exit(status, "{\
      \"Error Code\": " .. status .. ",\
      \"Error Message\": \"Kong Admin API: failure to create Customer\"\
      }",
      {
      ["Content-Type"] = "application/json"
      }
    )
  end
  
  ------------------------------------------
  -- If the Rate Limiting option is enabled
  ------------------------------------------
  if plugin_conf.rate_limiting == true then
  
    local body_rate ="{\
      \"name\": \"rate-limiting\",\
      \"tags\": [\"" .. registration_access_token .. "\"],\
      \"config\": {\
        \"policy\": \"local\""

    if plugin_conf.rate_limiting_config_second ~= nil then
      body_rate = body_rate ..
      [[,
        "second": ]] .. plugin_conf.rate_limiting_config_second  
    end
    if plugin_conf.rate_limiting_config_minute ~= nil then
      body_rate = body_rate ..
      [[,
        "minute": ]] .. plugin_conf.rate_limiting_config_minute  
    end
    if plugin_conf.rate_limiting_config_hour ~= nil then
      body_rate = body_rate ..
      [[,
        "hour": ]]  .. plugin_conf.rate_limiting_config_hour
    end
    if plugin_conf.rate_limiting_config_day ~= nil then
      body_rate = body_rate ..
      [[,
        "day": ]]   .. plugin_conf.rate_limiting_config_day
    end
    if plugin_conf.rate_limiting_config_month ~= nil then
      body_rate = body_rate ..
      [[,
        "month": ]] .. plugin_conf.rate_limiting_config_month
    end
    if plugin_conf.rate_limiting_config_year ~= nil then
      body_rate = body_rate ..
      [[,
        "year": ]] .. plugin_conf.rate_limiting_config_year
    end
    body_rate = body_rate ..
      [[
      
      }
    }]]
    
    kong.log.debug("registerConsumer Admin API - Create Rate Limiting plugin - Body Request=" .. body_rate)

    -----------------------------------------------
    -- Kong Admin API: create Rate Limiting plugin
    -----------------------------------------------
    res, err = httpc:request_uri( plugin_conf.kong_admin_api .. "/consumers" .. "/" .. client_id .. "/plugins", {
      method = "POST",
      headers = {
        ["Kong-Admin-Token"] = plugin_conf.kong_admin_token,
        ["Content-Type"] = "application/json",
      },
      body = body_rate,
      keepalive_timeout = 60,
      keepalive_pool = 10
    })
    
    if err then
      return nil, err
    end

    kong.log.debug("registerConsumer Admin API - Create Rate Limiting plugin - Body Response=" .. res.body)
    status = res.status
    if status >= 300 then
      return kong.response.exit(status, "{\
        \"Error Code\": " .. status .. ",\
        \"Error Message\": \"Kong Admin API: failure to create Rate Limiting plugin\"\
        }",
        {
        ["Content-Type"] = "application/json"
        }
      )
    end

    --------------------------------------------------
    -- Kong Admin API: Associate Consumers with an ACL
    --------------------------------------------------
    res, err = httpc:request_uri( plugin_conf.kong_admin_api .. "/consumers" .. "/" .. client_id .. "/acls", {
      method = "POST",
      headers = {
        ["Kong-Admin-Token"] = plugin_conf.kong_admin_token,
        ["Content-Type"] = "application/json",
      },
      body = "{\
      \"group\": \""  .. plugin_conf.acl_group_name .. "\",\
      \"tags\": [\"" .. registration_access_token .. "\"]\
      }",
      keepalive_timeout = 60,
      keepalive_pool = 10
    })
    
    if err then
      return nil, err
    end

    kong.log.debug("registerConsumer Admin API - Associate consumer to ACL - Body Response=" .. res.body)
    status = res.status
    if status >= 300 then
      return kong.response.exit(status, "{\
        \"Error Code\": " .. status .. ",\
        \"Error Message\": \"Kong Admin API: failure to associate consumer to ACL\"\
        }",
        {
        ["Content-Type"] = "application/json"
        }
      )
    end

  end

  kong.log.debug("registerConsumer access(): END")
  
  -- Send 200 Ok with the Reponse Body retrieved on the User register
  return kong.response.exit(200, idp_body_res, {["Content-Type"] = "application/json"})

end

return registerConsumer