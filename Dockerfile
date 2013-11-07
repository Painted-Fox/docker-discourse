FROM ubuntu
MAINTAINER Ryan Seto <ryanseto@yak.net>
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade

RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Discourse suggests using `tasksel`, but we can just install the packages `tasksel` would select.
RUN apt-get install -y postgresql postfix

# Install necessary packages
RUN apt-get -y install build-essential libssl-dev libyaml-dev git libtool libxslt-dev libxml2-dev libpq-dev gawk curl pngcrush imagemagick python-software-properties

# Install Redis
RUN apt-add-repository -y ppa:rwky/redis
RUN apt-get update
RUN apt-get install redis-server
