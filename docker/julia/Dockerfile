FROM julia:latest
RUN apt-get update && \
    apt-get install -y \
      ffmpeg cmake xorg-dev \
      build-essential libgl1-mesa-dev && \
      rm -r /var/lib/apt/lists/*

CMD cd /home/jovyan/main/projects