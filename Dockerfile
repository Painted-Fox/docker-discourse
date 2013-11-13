FROM ubuntu
MAINTAINER Ryan Seto <ryanseto@yak.net>
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list && \
        apt-get update && \
        apt-get upgrade

RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Add Redis and Nginx
RUN apt-get install -y python-software-properties && \
        apt-add-repository -y ppa:rwky/redis && \
        apt-add-repository -y ppa:nginx/stable && \
        apt-get update

RUN apt-get install -y postgresql postgresql-contrib postfix \  # Postgres and sendmail
        redis-server \
        nginx \
        build-essential libssl-dev libyaml-dev git libtool \
        libxslt-dev libxml2-dev libpq-dev gawk curl pngcrush imagemagick  \
        libzmq-dev libevent-dev python-dev python-pip  # Circus

# Create the discourse user.
RUN adduser --shell /bin/bash --gecos 'Discourse application' discourse
RUN install -d -m 755 -o discourse -g discourse /var/www/discourse

# Give Postgres database rights to the discourse user.
RUN /etc/init.d/postgresql start && /bin/su postgres -c 'createuser -s discourse'

# Install Ruby 2.0.0 with RVM as the discourse user.
RUN /bin/su discourse -c \
       '\curl -L https://get.rvm.io | bash -s stable && \
        cat ~/.bash_profile >> ~/.profile && rm ~/.bash_profile'
RUN /home/discourse/.rvm/bin/rvm requirements
RUN /bin/su discourse -c \
       '. ~/.profile && \
        rvm install 2.0.0 && \
        rvm use 2.0.0 --default && \
        gem install bundler'

# Install Discourse
RUN /bin/su discourse -c \
       '. ~/.profile && \
        git clone https://github.com/discourse/discourse.git /var/www/discourse && \
        cd /var/www/discourse && \
        git checkout latest-release && \
        sed -i -e"s/^source 'https:\/\/rubygems\.org'/source 'http:\/\/rubygems\.org'/" /var/www/discourse/Gemfile && \
        bundle install --deployment --without test'

# Configure Discourse
RUN cd /var/www/discourse/config && /bin/su discourse -c \
       'cp database.yml.production-sample database.yml && \
        cp redis.yml.sample redis.yml && \
        cp discourse.pill.sample discourse.pill && \
        cp environments/production.rb.sample environments/production.rb'

# Initialize the database
RUN /etc/init.d/postgresql start && cd /var/www/discourse && /bin/su discourse -c 'createdb discourse_prod'
RUN /etc/init.d/postgresql start && (/usr/bin/redis-server &) && cd /var/www/discourse && /bin/su discourse -c \
        '. ~/.profile && RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake db:migrate'
RUN /etc/init.d/postgresql start && (/usr/bin/redis-server &) && cd /var/www/discourse && /bin/su discourse -c \
        '. ~/.profile && RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake assets:precompile'

# Setup nginx
RUN cp -f /var/www/discourse/config/nginx.sample.conf /etc/nginx/sites-enabled/default
RUN sed -i -e"s/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
ADD nginx-site.conf /etc/nginx/sites-enabled/default

# Setup Bluepill
#RUN /bin/su discourse -c '. ~/.profile && gem install bluepill'
#RUN /bin/su discourse -c ". ~/.profile && echo \'alias bluepill=\"NOEXEC_DISABLE=1 bluepill --no-privileged -c ~/.bluepill\"\' >> ~/.bash_aliases"
#RUN /bin/su discourse -c '. ~/.profile && rvm wrapper $(rvm current) bootup bluepill'
#RUN /bin/su discourse -c '. ~/.profile && rvm wrapper $(rvm current) bootup bundle'

# Setup Circus
pip install circus
ADD circus.ini circus.ini

# Add startup script
ADD start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/bin/bash", "/start.sh"]
