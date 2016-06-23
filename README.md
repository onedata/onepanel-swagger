# Onepanel REST API defined using Swagger (http://swagger.io)

This repo contains Swagger specification of Oneprovider REST API.

Onepanel is part of [Onedata](http://onedata.org), a distributed data management platform. Onepanel is an administrative service which enables management of other Onedata services including [Onezone](http://github.com/onedata/onezone) and [Oneprovider](http://github.com/onedata/oneprovider).

For more details about Onepanel service please check (http://github.com/onedata/onepanel).

Compiling (Using Onedata docker repository):
```
./build.sh
```

Compiling from scratch:
```
# Install Node.js dependencies
npm install

# Aggregate Yaml specification files into a single swagger.json file
node resolve.js > swagger.json
```

After any of these steps you should have a complete `swagger.json` file, with specification of Onepanel REST API. The file can be used by Swagger [code generator](https://github.com/swagger-api/swagger-codegen) to produce example code for clients in various languages or viewed online using for instance [Swagger Online Editor](http://editor.swagger.io/).
