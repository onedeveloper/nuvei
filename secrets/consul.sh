#!/bin/bash

HOST_CONSUL_DATA_DIR="./consul/data"
mkdir -p "$HOST_CONSUL_DATA_DIR"

echo "Starting Consul..."
docker run \
    -d \
    -v "$HOST_CONSUL_DATA_DIR:/consul/data" \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=nuvei \
    hashicorp/consul agent -server -ui -node=consul -bootstrap-expect=1 -client=0.0.0.0

echo "Consul is up and running!"