local typedefs = require "kong.db.schema.typedefs"

return {
  name = "register-consumer",
  fields = {
    {
      -- this plugin will only be applied to Services or Routes
      consumer = typedefs.no_consumer
    },
    {
      -- this plugin will only run within Nginx HTTP module
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        fields = {
          { idp_client_registration_endpoint = typedefs.url ({  required = true, default = "http://idp-server/connect/register" }) },
          { kong_admin_api = typedefs.url ({  required = true, default = "http://localhost:8001/default" }) },
          { kong_admin_token = { type = "string", required = true, default = "A-B-C-D" } },
          { rate_limiting = { type = "boolean", required = true, default = true } },
          { rate_limiting_config_second = { type = "number", required = false, default = 1 } },
          { rate_limiting_config_minute = { type = "number", required = false  } },
          { rate_limiting_config_hour = { type = "number", required = false } },
          { rate_limiting_config_day = { type = "number", required = false } },
          { rate_limiting_config_month = { type = "number", required = false } },
          { rate_limiting_config_year = { type = "number", required = false } },
        },
      },
    },
  },
  entity_checks = {
    -- Describe your plugin's entity validation rules
  },
}
