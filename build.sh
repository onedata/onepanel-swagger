#!/bin/bash

# Generate aggregate JSON file from YAML
#docker run --rm -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.2.0
docker run --rm -v `pwd`:/swagger swagger-aggregator6


# Validate the JSON
docker run --rm -v `pwd`:/swagger swagger-cli validate /swagger/swagger.json

# Generate the Cowboy server stub
docker run --rm -v `pwd`:/swagger -t swagger-codegen2 generate -i ./swagger.json -l cowboy -o ./generated/cowboy

# Generate the 
docker run --rm -v `pwd`:/swagger -t swagger-codegen2 generate -i ./swagger.json -l html -o ./generated/html

