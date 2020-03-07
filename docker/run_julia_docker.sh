#!/bin/bash
port=$1

image="julia:latest"
docker pull $image
docker run -it --entrypoint /bin/bash \
       -v /home/ec2-user/main:/home/jovyan/main \
       -p $port:$port \
       --name "maxwell" \
       -e GRANT_SUDO=yes \
       -e USERID=1000 \
       julia:latest
