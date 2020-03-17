#!/bin/bash
port=$1

image="julia_with_image_libs:latest"
# image="julia:latest"
## docker pull $image
docker run -it --rm --entrypoint /bin/bash \
       -v ~/main:/root/main \
       -v ~/.aws:/root/.aws \
       -p $port:$port \
       -m=1.5G \
       --name "maxwell" \
       -e GRANT_SUDO=yes \
       -e USERID=$UID \
       -e AWS_DEFAULT_REGION="us-east-2" \
       $image
