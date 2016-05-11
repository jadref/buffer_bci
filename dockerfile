# Docker image for computer brain interfaces

# Getting USB to work: docker run -t -i -privileged -v /dev/bus/usb:/dev/bus/usb bci bash
# VERSION 2

FROM debian
MAINTAINER Jason Farquhar, jadref@gmail.com

# Update Debian
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get clean

# JDK, Octave
RUN apt-get install -y default-jdk octave

# Common dependencies
RUN apt-get install -y git-core subversion build-essential wget cmake automake autoconf gfortran unzip

# Fetch buffer_bci
WORKDIR /

RUN git clone https://github.com/jadref/buffer_bci.git

# Java
WORKDIR /buffer_bci/dataAcq/buffer/java
RUN ./build.sh

# C
WORKDIR /buffer_bci/dataAcq/buffer/c
RUN make
