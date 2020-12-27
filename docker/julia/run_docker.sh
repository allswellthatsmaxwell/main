#!/bin/bash
port=$1

image="julia_with_packages:latest"

 ## will need to make config dir for startup.jl.
docker run -it --rm --entrypoint /bin/bash \
       -v ~/main:/root/main \
       -v ~/.aws:/root/.aws \
       -v ~/main/setup/startup.jl:/root/.julia/config/startup.jl \
       -p $port:$port \
       -m=4G \
       --name "maxwell" \
       -e GRANT_SUDO=yes \
       -e USERID=$UID \
       -e AWS_DEFAULT_REGION="us-east-2" \
       $image
