#!/bin/bash

set -e
[ "$DEBUG" == "1" ] && set -x && set +e

#ENV
if [ "${GLUSTER_PEER}" == "storage" -o -z "${GLUSTER_PEER}" ]; then
   GLUSTER_HOST=${GLUSTER_PEER}
fi

if [ "${GLUSTER_VOL}" == "ranchervol" -o -z "${GLUSTER_VOL}" ]; then
   GLUSTER_VOL=${GLUSTER_VOL}
fi

if [ "${SITE_NAME}" == "**ChangeMe**" -o -z "${SITE_NAME}" ]; then
   SITE_NAME=${SITE_NAME}
fi

if [ "${DOMAIN}" == "**ChangeMe**" -o -z "${DOMAIN}" ]; then
   DOMAIN=${DOMAIN}
fi

if [ "${HTTP_DOCUMENTROOT}" == "**ChangeMe**" -o -z "${HTTP_DOCUMENTROOT}" ]; then
   HTTP_DOCUMENTROOT=${GLUSTER_VOL_PATH}/${SITE_NAME}
fi


### Configuration Nginx
# From Git

## ENV
if [ "${GIT_NGINX_REPO}" == "**NO**" -o -z "${GIT_NGINX_REPO}" ]; then
   GIT_NGINX_REPO=`echo ${GIT_NGINX_REPO} | sed "s=https://==g"`
fi

if [ "${GIT_NGINX_LOGIN}" == "**NO**" -o -z "${GIT_NGINX_LOGIN}" ]; then
   GIT_NGINX_LOGIN=${GIT_NGINX_LOGIN}
fi

if [ "${GIT_NGINX_BRANCH}" == "**NO**" -o -z "${GIT_NGINX_BRANCH}" ]; then
   GIT_NGINX_BRANCH=${GIT_NGINX_BRANCH}
fi

if [ "${GIT_NGINX_PASS}" == "**NO**" -o -z "${GIT_NGINX_PASS}" ]; then
   GIT_NGINX_PASS=${GIT_NGINX_PASS}
fi

#DEPLOY
if [ "${GIT_NGINX}" == "YES" ]; then

	
	if [ "${GIT_NGINX_LOGIN}" != "**NO**" ]; then
		git clone https://${GIT_NGINX_LOGIN}:${GIT_NGINX_PASS}@${GIT_NGINX_REPO}/tree/${GIT_NGINX_BRANCH} /etc/nginx
	else
		git clone https://${GIT_NGINX_REPO}/tree/${GIT_NGINX_BRANCH} /etc/nginx
	fi
else

	perl -p -i -e "s/HTTP_PORT/${HTTP_PORT}/g" /etc/nginx/sites-enabled/website
	perl -p -i -e "s/DOMAIN/${DOMAIN}/g" /etc/nginx/sites-enabled/website
	HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"`
	perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/website
	perl -p -i -e "s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
	perl -p -i -e "s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
	echo "daemon off;" >> /etc/nginx/nginx.conf
	rm -f /etc/nginx/sites-enabled/default

fi

### Configuration PHP-FPM 
if [ "${PHP_MAX_UPLOAD_FILESIZE}" == "20M" -o -z "${PHP_MAX_UPLOAD_FILESIZE}" ]; then
   PHP_MAX_UPLOAD_FILESIZE=${PHP_MAX_UPLOAD_FILESIZE}
fi
if [ "${PHP_MAX_POST_SIZE}" == "20M" -o -z "${PHP_MAX_POST_SIZE}" ]; then
   PHP_MAX_POST_SIZE=${PHP_MAX_POST_SIZE}
fi
PHP_ESCAPED_SESSION_PATH=`echo ${PHP_SESSION_PATH} | sed "s/\//\\\\\\\\\//g"`

perl -p -i -e "s/;?session.save_path\s*=.*/session.save_path = \"${PHP_ESCAPED_SESSION_PATH}\"/g" /etc/php5/fpm/php.ini

perl -p -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
perl -p -i -e "s/post_max_size\s*=\s*8M/post_max_size = ${PHP_MAX_POST_SIZE}/g" /etc/php5/fpm/php.ini
perl -p -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = ${PHP_MAX_UPLOAD_FILESIZE}/g" /etc/php5/fpm/php.ini
perl -p -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf


### HAProxy (if SQL)
if [ "${DB_CLUSTER}" == "YES" ]; then

perl -p -i -e "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy

if grep "PXC nodes here" /etc/haproxy/haproxy.cfg >/dev/null; then
   PXC_HOSTS_HAPROXY=""
   PXC_HOSTS_COUNTER=0

   for host in `echo ${DB_HOSTS} | sed "s/,/ /g"`; do
      PXC_HOSTS_HAPROXY="$PXC_HOSTS_HAPROXY\n  server pxc$PXC_HOSTS_COUNTER $host check port 9200 rise 2 fall 3"
      if [ $PXC_HOSTS_COUNTER -gt 0 ]; then
         PXC_HOSTS_HAPROXY="$PXC_HOSTS_HAPROXY backup"
      fi
      PXC_HOSTS_COUNTER=$((PXC_HOSTS_COUNTER+1))
   done
   perl -p -i -e "s/DB_PASSWORD/${DB_PASSWORD}/g" /etc/haproxy/haproxy.cfg
   perl -p -i -e "s/.*server pxc.*//g" /etc/haproxy/haproxy.cfg
   perl -p -i -e "s/# PXC nodes here.*/# PXC nodes here\n${PXC_HOSTS_HAPROXY}/g" /etc/haproxy/haproxy.cfg
fi

fi

### GlusterFS
if [ "${GLUSTER}" == "YES" ]; then

if [ "${GLUSTER_VOL_PATH}" == "/var/www" -o -z "${GLUSTER_VOL_PATH}" ]; then
   GLUSTER_VOL_PATH=${GLUSTER_VOL_PATH}
fi

if [ "${GLUSTER_PEER}" == "storage" -o -z "${GLUSTER_PEER}" ]; then
   GLUSTER_PEER=${GLUSTER_PEER}
fi

ALIVE=0
for glusterHost in ${GLUSTER_PEER}; do
    echo "=> Checking ${glusterHost} ..."
    if ping -c 10 ${glusterHost} >/dev/null 2>&1; then
       echo "=> GlusterFS node ${glusterHost} is alive"
       ALIVE=1
       break
    else
       echo "*** Could not reach server ${glusterHost} ..."
    fi
done

if [ "$ALIVE" == 0 ]; then
   echo "ERROR: could not contact any GlusterFS node from this list: ${GLUSTER_PEER} - Exiting..."
   exit 1
fi

echo "=> Mounting GlusterFS volume ${GLUSTER_VOL} from GlusterFS node ${glusterHost} ..."
mount -t glusterfs ${glusterHost}:/${GLUSTER_VOL} ${GLUSTER_VOL_PATH}
fi

if [ ! -d ${HTTP_DOCUMENTROOT} ]; then
   mkdir -p ${HTTP_DOCUMENTROOT}
fi

if [ ! -d ${PHP_SESSION_PATH} ]; then
   mkdir -p ${PHP_SESSION_PATH}
   chown www-data:www-data ${PHP_SESSION_PATH}
fi

if [ ! -e ${HTTP_DOCUMENTROOT}/healthcheck.txt ]; then
   echo "OK" > ${HTTP_DOCUMENTROOT}/healthcheck.txt
fi

###Deploy Git Project
if [ "${GIT_WEB_REPO}" == "**NO**" -o -z "${GIT_WEB_REPO}" ]; then
   GIT_WEB_REPO=`echo ${GIT_WEB_REPO} | sed "s=https://==g"`
fi

if [ "${GIT_WEB_LOGIN}" == "**NO**" -o -z "${GIT_WEB_LOGIN}" ]; then
   GIT_WEB_LOGIN=${GIT_WEB_LOGIN}
fi

if [ "${GIT_WEB_BRANCH}" == "**NO**" -o -z "${GIT_WEB_BRANCH}" ]; then
   GIT_WEB_BRANCH=${GIT_WEB_BRANCH}
fi

if [ "${GIT_WEB_PASS}" == "**NO**" -o -z "${GIT_WEB_PASS}" ]; then
   GIT_WEB_PASS=${GIT_WEB_PASS}
fi


if [ "${GIT_WEB_REPO}" == "YES" ]; then

	if [ "${GIT_WEB_LOGIN}" -ne "**NO**" ]; then
                git clone https://${GIT_WEB_LOGIN}:${GIT_WEB_PASS}@${GIT_WEB_REPO}/tree/${GIT_WEB_BRANCH} /etc/nginx
        else
                git clone https://${GIT_WEB_REPO}/tree/${GIT_WEB_BRANCH} /etc/nginx
        fi

fi


### FTP
if [ "${FTP}" == "**NO**" -o -z "${FTP}" ]; then
   FTP=${FTP}
fi


#if [ "${FTP}" == "YES" ]; then

if [ "${FTP_LOGIN}" == "flotix" -o -z "${FTP_LOGIN}" ]; then
   FTP_LOGIN=${FTP_LOGIN}
fi

if [ "${FTP_PASSWD}" == "**ChangeMe**" -o -z "${FTP_PASSWD}" ]; then
   FTP_PASSWD=${FTP_PASSWD}
fi


# User
useradd -d ${GLUSTER_VOL_PATH} -p ${FTP_PASSWD} ${FTP_USER}

#fi

#/usr/bin/supervisord
