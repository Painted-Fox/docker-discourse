FROM ubuntu
MAINTAINER Ryan Seto <ryanseto@yak.net>
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade

RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Discourse suggests using `tasksel`,
# but we can just install the packages `tasksel` would select.
RUN apt-get install -y postgresql postfix

# Install necessary packages
RUN apt-get -y install build-essential libssl-dev libyaml-dev git libtool \
        libxslt-dev libxml2-dev libpq-dev gawk curl pngcrush imagemagick  \
        python-software-properties

# Install Redis
RUN apt-add-repository -y ppa:rwky/redis
RUN apt-get update
RUN apt-get install redis-server

# Install Nginx
RUN add-apt-repository ppa:nginx/stable
RUN apt-get update
RUN apt-get install -y nginx

# Create the discourse user.
RUN adduser --shell /bin/bash --gecos 'Discourse application' discourse
RUN install -d -m 755 -o discourse -g discourse /var/www/discourse

# Give Postgres database rights to the discourse user.
RUN /etc/init.d/postgresql start && /bin/su postgres -c 'createuser -s discourse'

# Install Ruby 2.0.0 with RVM as the discourse user.
RUN /bin/su discourse -c '\curl -L https://get.rvm.io | bash -s stable'
RUN /bin/su discourse -c 'cat ~/.bash_profile >> ~/.profile && rm ~/.bash_profile'
RUN /home/discourse/.rvm/bin/rvm requirements
RUN /bin/su discourse -c '. ~/.profile && rvm install 2.0.0'
RUN /bin/su discourse -c '. ~/.profile && rvm use 2.0.0 --default'
RUN /bin/su discourse -c '. ~/.profile && gem install bundler'

# Install Discourse
RUN mkdir -p /srv/www
RUN git clone https://github.com/discourse/discourse.git /srv/www
RUN cd /srv/www && git checkout latest-release
RUN chown -R discourse:discourse /srv/www
RUN cd /srv/www && /bin/su discourse -c '. ~/.profile && bundle install --deployment --without test'
