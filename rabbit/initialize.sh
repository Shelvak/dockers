#!/bin/bash

# Here should be all the DB initialization that we need
rabbitmqctl add_vhost sync.devel
rabbitmqctl set_permissions -p sync.devel wisproMQ ".*" ".*" ".*"
