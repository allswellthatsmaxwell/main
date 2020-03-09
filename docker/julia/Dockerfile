FROM julia:latest
#RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/source.list
#RUN echo "deb-src http://us.archive.ubuntu.com/ubuntu/ trusty multiverse">> /etc/apt/source.list
#RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates multiverse" >> /etc/apt/source.list
#RUN echo "deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-updates multiverse" >> /etc/apt/source.list


RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install build-essential -y
RUN apt-get install -y cmake mesa-utils
RUN apt-get install -y libxrandr-dev libxinerama-dev libxcursor-dev mesa-utils
RUN apt-get install -y ffmpeg
# RUN apt-get install -y libfdk-aac libfdk-aac0 libfdk-aac-dev
RUN apt-get install -y xorg-dev libgl1-mesa-dev libglfw3
RUN rm -r /var/lib/apt/lists/*
