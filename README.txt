Environment variables:

MONGOID_ENV - responsible for the config part to be used from config/mongoid.yml for MongoDB (ex: development)



INVENTORY TODO

Implement current_inventory in conjunction with Meter API
Fix alerts
Send Infrastructure and Hosts only when something has changed
Implement equality methods in Inventory/Host models
A) Detect new hosts
B) Detect deleted hosts
C) Detect changed hosts
Send metrics on Deleted/Changed hosts
Send POST requests on NEW or CHANGED hosts
Send DELETE requests on DELETED hosts
Logger
Retries in Meter Client on 5XX errors
Meaningful error message for REST calls


Send metrics only when any host is deleted, or any disk is removed from host
If only any DISK was added/changed/removed - then use special disks endpoint
