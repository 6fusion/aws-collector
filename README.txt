Environment variables:

MONGOID_ENV - responsible for the config part to be used from config/mongoid.yml for MongoDB (ex: development)



INVENTORY TODO

Implement current_inventory in conjunction with Meter API
Send Infrastructure and Hosts only when something has changed
Implement equality methods in Inventory/Host models
A) Detect new hosts
B) Detect deleted hosts
C) Detect changed hosts
Send POST requests on NEW or CHANGED hosts
Send DELETE requests on DELETED hosts


Retries in Meter Client on 5XX errors
Replace puts with loggers
