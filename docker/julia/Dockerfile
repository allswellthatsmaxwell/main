FROM julia:latest

COPY install.jl /install.jl
RUN julia install.jl

RUN apt-get update
RUN apt-get upgrade -y
RUN rm -r /var/lib/apt/lists/*

