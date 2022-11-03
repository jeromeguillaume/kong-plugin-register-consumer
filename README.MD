# Register Customer Plugin

Actions done by the plugin:
1. Do a REST API call on IDP 
```
https://<idp-host>/connect/register
```
Get `client-id` and `registration_access_token` from IDP response

2. Do a REST API call on Kong Admin API to create a Consumer

The consumer-name and consumer-id have the `client-id` value
A tag with the value of `registration_access_token` is added
```
https://<kong-admin_api>:8001/consumers
```

3. Do a REST API call on Kong Admin API to create a Rate Limiting plugin on Consumer created on step #2
```
https://<kong-admin_api>:8001/consumers/<client_id>/plugins
```
A tag with the value of `registration_access_token` is added