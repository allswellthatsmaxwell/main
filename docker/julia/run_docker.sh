#!/bin/bash
port=$1

image="julia_with_image_libs:latest"
# image="julia:latest"
## docker pull $image
docker run -it --rm --entrypoint /bin/bash \
       -v /home/ec2-user/main:/home/jovyan/main \
       -p $port:$port \
       -m=1.5G \
       --name "maxwell" \
       -e GRANT_SUDO=yes \
       -e USERID=1000 \
       $image
