#!/bin/bash

# Generate aggregate JSON file from YAML
docker run --rm -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.4.0

# Validate the JSON
docker run --rm -v `pwd`:/swagger docker.onedata.org/swagger-cli:1.2.0 validate /swagger/swagger.json

# Generate the Cowboy server stub
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.2.0 generate -i ./swagger.json -l cowboy -o ./generated/cowboy

# Generate the 
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.2.0 generate -i ./swagger.json -l html -o ./generated/html

