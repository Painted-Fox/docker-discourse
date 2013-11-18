# Discourse (http://www.discourse.org/)

FROM paintedfox/ruby
MAINTAINER Ryan Seto <ryanseto@yak.net>

# Add Nginx
RUN apt-get install -y python-software-properties && \
    apt-add-repository -y ppa:nginx/stable && \
    apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix \
    nginx \
    git \
    libtool libxslt-dev libxml2-dev libpq-dev gawk pngcrush imagemagick  \
    libzmq-dev libevent-dev python-dev python-pip

# Install Discourse.
RUN mkdir -p /var/www/discourse && \
    git clone https://github.com/discourse/discourse.git /var/www/discourse && \
    cd /var/www/discourse && \
    git checkout latest-release && \
    sed -i -e"s/^source 'https:\\/\\/rubygems\\.org'/source 'http:\/\/rubygems.org'/" Gemfile && \
    gem install bundler && \
    bundle install --deployment --without test

# Configure Discourse
RUN cd /var/www/discourse/config && \
    cp database.yml.production-sample database.yml && \
    cp redis.yml.sample redis.yml && \
    cp discourse.pill.sample discourse.pill && \
    cp environments/production.rb.sample environments/production.rb

# Setup nginx
RUN cp -f /var/www/discourse/config/nginx.sample.conf /etc/nginx/sites-enabled/default
RUN sed -i -e"s/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
ADD nginx-site.conf /etc/nginx/sites-enabled/default

# Setup Circus
pip install circus
ADD circus.ini circus.ini

# Add startup script
ADD start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
ENTRYPOINT ["/bin/bash", "/start.sh"]
