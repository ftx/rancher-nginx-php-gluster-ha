#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${GLUSTER_PEER}" == "storage" -o -z "${GLUSTER_PEER}" ]; then
   GLUSTER_HOST=${GLUSTER_PEER}
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

### Prepare configuration
# nginx config
perl -p -i -e "s/HTTP_PORT/${HTTP_PORT}/g" /etc/nginx/sites-enabled/website
perl -p -i -e "s/DOMAIN/${DOMAIN}/g" /etc/nginx/sites-enabled/website
HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"`
perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/website

# php-fpm config
PHP_ESCAPED_SESSION_PATH=`echo ${PHP_SESSION_PATH} | sed "s/\//\\\\\\\\\//g"`
perl -p -i -e "s/;?session.save_path\s*=.*/session.save_path = \"${PHP_ESCAPED_SESSION_PATH}\"/g" /etc/php5/fpm/php.ini

ALIVE=0
for glusterHost in ${GLUSTER_PEER}; do
    echo "=> Checking if I can reach GlusterFS node ${glusterHost} ..."
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

if [ ! -d ${HTTP_DOCUMENTROOT} ]; then
   mkdir -p ${HTTP_DOCUMENTROOT}
fi

if [ ! -d ${PHP_SESSION_PATH} ]; then
   mkdir -p ${PHP_SESSION_PATH}
   chown www-data:www-data ${PHP_SESSION_PATH}
fi

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



if [ ! -e ${HTTP_DOCUMENTROOT}/healthcheck.txt ]; then
   echo "OK" > ${HTTP_DOCUMENTROOT}/healthcheck.txt
fi

/usr/bin/supervisord

