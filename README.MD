# Register Customer Plugin

Actions done by the plugin:
1. Do a REST API call on IDP 
```
https://<idp-host>/connect/register
```
Get `client-id` and `registration_access_token` from IDP response

2. Do a REST API call on Kong Admin API to create a Consumer

The consumer-name and consumer-id have the `client-id` value

```
https://<kong-admin_api>:8001/consumers
```
A tag with the value of `registration_access_token` is added

3. Do a REST API call on Kong Admin API to create a Rate Limiting plugin on Consumer (created on step #2)
```
https://<kong-admin_api>:8001/consumers/<client_id>/plugins
```
A tag with the value of `registration_access_token` is added

4. Do a REST API call on Kong Admin API to associate the Consumer (created on step #2) with an ACL Group
```
https://<kong-admin_api>:8001/consumers/<client_id>/acls
```
A tag with the value of `registration_access_token` is added

## Plugin Configuration
![Plugin Configuration](./images/plugin-register-consumer-configuration.png)
