#!/bin/bash

docker run -d \
    -v $PWD/script:/web \
    -p 8080:8080 \
    --name fserver \
    halverneus/static-file-server