#!/bin/bash

# Generate aggregate JSON file from YAML
docker run --rm -v `pwd`:/swagger swagger-aggregator


# Validate the JSON
docker run --rm -v `pwd`:/swagger swagger-cli validate /swagger/swagger.json

# Run doc server
#docker run --rm -v `pwd`:/swagger swagger-ui 


exit

docker run --rm -v `pwd`:/INPUT -v `pwd`/../generated:/OUTPUT \
   -t swagger-codegen java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
   generate -i /INPUT/swagger.json \
   -l python -o /OUTPUT/python


docker run --rm -v `pwd`:/INPUT -v `pwd`/../generated:/OUTPUT \
   -t swagger-codegen java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
   generate -i /INPUT/swagger.json \
   -l html -o /OUTPUT/html


docker run --rm -v `pwd`:/INPUT -v `pwd`/../generated:/OUTPUT \
   -t swagger-codegen java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
   generate -i /INPUT/swagger.json \
   -l dynamic-html -o /OUTPUT/node-html


docker run --rm -v `pwd`:/INPUT -v `pwd`/../generated:/OUTPUT \
   -t swagger-codegen java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
   generate -i /INPUT/swagger.json \
   -l java -o /OUTPUT/java


docker run --rm -v `pwd`:/INPUT -v `pwd`/../generated:/OUTPUT \
   -t swagger-codegen java -jar modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
   generate -i /INPUT/swagger.json \
   -l ruby -o /OUTPUT/ruby
