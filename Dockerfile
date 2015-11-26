FROM ubuntu:14.04

MAINTAINER Florian Mauduit <flotix@linux.com>

ENV DEBIAN_FRONTEND=noninteractive

######## ENV VARIABLES ########

# DEBUG
ENV DEBUG 0

# GLOBAL
ENV SITE_NAME **ChangeMe**
ENV DOMAIN **ChangeMe**

# Config GlusterFSClient
ENV GLUSTER **NO**
ENV GLUSTER_VOL ranchervol
ENV GLUSTER_VOL_PATH /var/www
ENV GLUSTER_PEER storage

# Git NGINX
ENV GIT_NGINX_REPO **NO**
ENV GIT_NGINX_LOGIN **NO**
ENV GIT_NGINX_PASS **NO**
ENV GIT_NGINX_BRANCH master

# Git WEB
ENV GIT_WEB_REPO **NO**
ENV GIT_WEB_LOGIN **NO**
ENV GIT_WEB_PASS **NO**
ENV GIT_WEB_BRANCH master

# Config PHP
ENV PHP_MAX_UPLOAD_FILESIZE 20M
ENV PHP_MAX_POST_SIZE 20M
ENV PHP_SESSION_PATH ${GLUSTER_VOL_PATH}/phpsessions

# Config NGINX
ENV HTTP_PORT 80
ENV HTTP_DOCUMENTROOT **ChangeMe**
ENV NGINX_WORKER_PROCESSES 2
ENV NGINX_WORKER_CONNECTIONS 2048
ENV NGINX_MULTI_ACCEPT on
ENV NGINX_SET_REAL_IP 0.0.0.0

# Config SQL
ENV DB_CLUSTER **NO** 
ENV DB_USER **ChangeMe**
ENV DB_PASSWORD **ChangeMe**

# FTP
ENV FTP **NO**
ENV FTP_LOGIN flotix
ENV FTP_PASSWD **ChangeMe**



################################


RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common
RUN add-apt-repository -y ppa:gluster/glusterfs-3.7 && \
    apt-get update && \
    apt-get install -y proftpd nginx php5-fpm php5-mysql php-apc supervisor glusterfs-client curl pwgen unzip mysql-client dnsutils git 


RUN mkdir -p /var/log/supervisor ${GLUSTER_VOL_PATH}
WORKDIR ${GLUSTER_VOL_PATH}

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
#ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#ADD ./etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
ADD ./etc/nginx/sites-enabled/website /etc/nginx/sites-enabled/website
ADD ./etc/proftpd.conf /etc/proftpd/proftpd.conf

CMD ["/usr/local/bin/run.sh"]
