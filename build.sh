#!/bin/bash

#
# Clean
#
rm -rf generated
rm swagger.json


# Generate aggregate JSON file from YAML
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0

# Validate the JSON
output=$(docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger docker.onedata.org/swagger-cli:1.5.0 validate /swagger/swagger.json 2>&1)

if [[ $output =~ .*SyntaxError.* ]] ; then
  echo "Generated swagger.json is not valid - check YAML sources:\n"
  echo $output
  exit 1
fi

# Generate the Cowboy server stub
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.5.3 generate -i ./swagger.json -l cowboy -o ./generated/cowboy

# Fix generated Erlang files
./fix_generated.py

# Generate C# stub to get all moustache tempalte keywords
#swagger-codegen-dbg generate -i ./swagger.json -l csharp -o ./generated/csharp -o tmp > model.json

# Generate the static documentation
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/swagger-bootprint:1.5.0 swagger ./swagger.json generated/static

#cp generated/static/index.html generated/static/oneprovider-static.html
sed -n '/<body>/,/<\/body>/p' generated/static/index.html \
  | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' \
  > generated/static/onepanel-static.html

# Generate Markdown for direct Gitbook integration
# The output from generated/gitbook should be copied to onedata-documentation/doc/advanced/rest/onepanel folder
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-gitbook:1.4.1 convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties

#
# Build Python client using official latest version of swagger-codegen
# in 'generated/python'
#
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen-official:ID-507bde287c  generate -i ./swagger.json -l python -o ./generated/python -c python-config.json

#
# Build Bash client
#
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/bash-swagger-codegen:0.3.7 generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

