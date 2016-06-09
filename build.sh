#!/bin/bash

# Generate aggregate JSON file from YAML
docker run --rm -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.4.0

# Validate the JSON
docker run --rm -v `pwd`:/swagger docker.onedata.org/swagger-cli:1.2.0 validate /swagger/swagger.json

# Generate the Cowboy server stub
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.2.0 generate -i ./swagger.json -l cowboy -o ./generated/cowboy

# Generate C# stub to get all moustache tempalte keywords
#swagger-codegen-dbg generate -i ./swagger.json -l csharp -o ./generated/csharp -o tmp > model.json

# Generate the 
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.2.0 generate -i ./swagger.json -l html -o ./generated/html

# Generate the static documentation
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-bootprint:1.1.0 swagger ./swagger.json generated/static

sed -n '/<body>/,/<\/body>/p' generated/static/index.html | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' > generated/static/onepanel-static.html
