# Onepanel REST API defined using Swagger (http://swagger.io)

This repo contains Swagger specification of Onepanel REST API.

Onepanel is part of [Onedata](http://onedata.org), a distributed data management platform. Onepanel is an administrative service which enables management of other Onedata services including [Onezone](http://github.com/onedata/onezone) and [Oneprovider](http://github.com/onedata/oneprovider).

For more details about Onepanel service please check (http://github.com/onedata/onepanel).

Building needs Docker; most of the images come from `docker.onedata.org`. To
aggregate the YAML files into a single `swagger.json` file, with the
specification of the Onepanel REST API:
```
make swagger.json
```

`make validate` builds the file and checks it. The targets `cowboy-server`,
`python-client`, `bash-client` and `javascript-client` generate Onepanel's
server code and the clients from it into `generated/`. The file can also be
viewed online, for instance in the [Swagger Editor](https://editor.swagger.io/).
