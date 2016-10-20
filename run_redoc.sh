#!/bin/bash

docker run -v $PWD/swagger.json:/usr/share/nginx/html/swagger.json:ro -p 8088:80 docker.onedata.org/swagger-redoc:1.0.0
