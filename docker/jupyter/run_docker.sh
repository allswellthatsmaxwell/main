#!/bin/bash
port=$1
docker pull jupyter/datascience-notebook:latest
docker run -it --rm \
       -v /home/ec2-user/main:/home/jovyan/main \
       -p $port:$port \
       --name "maxwell" \
       -e GRANT_SUDO=yes \
       -e NOTEBOOK_PORT=$port \
       -e NB_UID=1000 \
       -e USERID=1000 \
       -e JUPYTER_ENABLE_LAB=yes \
       jupyter/datascience-notebook:latest jupyter lab --NotebookApp.token=''
