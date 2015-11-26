[![](https://badge.imagelayers.io/flotix/rancher-nginx-php-gluster-ha:latest.svg)](https://imagelayers.io/?images=flotix/rancher-nginx-php-gluster-ha:latest 'Get your own badge on imagelayers.io')

:whale: Available on DockerHub (https://hub.docker.com/r/flotix/rancher-nginx-php-gluster-ha/)

## Stackable Docker Container for Rancher
### Nginx / PHP-FPM
##### In Option : GlusterFS Client /  HaProxy for Galera SQL CLuster / FTP Server
##### Extra : Git repo for your Nginx folder or/and Your Web Project


:warning: OPTIONAL : Have a GlusterFS Server and had a volume name. / Have a Percona DB Cluster




##### Global
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|SITE_NAME   |YES (except with Git Nginx)   |**ChangeMe**   |flotix   |
|DOMAIN   |YES (except with Git Nginx)   |**ChangeMe**   |flotix.jp   |


##### PHP
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|PHP_MAX_UPLOAD_FILESIZE   |No   |20M   |150M   |
|PHP_MAX_POST   |No   |20M   |150M   |
|PHP_SESSION_PATH   |No   |/defaultpath/phpsessions   |/tmp   |


##### NGINX
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|HTTP_PORT   |No   |80   |8080   |
|HTTP_DOCUMENTROOT   |No   |/var/www   |/home/flotix   |
|NGINX_WORKER_PROCESSES  |No   |2   |8   |
|NGINX_WORKER_CONNECTIONS  |No   |2048   |4096   |
|NGINX_MULTI_ACCEPT (not implemented)  |No   |off   |on   |
|NGINX_SET_REAL_IP (not implemented) |No   |0.0.0.0   |0.0.0.0   |

##### SQL
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|DB_CLUSTER   |No   |**NO**   |YES   |
|DB_USER (for health check)   |No   |**ChangeMe**   |healthuser   |
|DB_PASSWORD  |No   |**ChangeMe**   |123456   |
|DB_HOSTS  |No   |N/A   |10.0.0.0:3306,10.0.0.1:3306   |


##### GlusterFS
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|GLUSTER   |YES   |**NO**   |YES   |
|GLUSTER_VOL   |NO   |ranchervol   |flotix   |
|GLUSTER_VOL_PATH  |NO   |/var/www   |/home/flotix   |
|GLUSTER_PEER   |NO   |storage   |10.0.0.0 10.0.0.1   |


##### Git NGINX
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|GIT_NGINX_REPO   |NO   |**NO**   |https://github.com/ftx/mynginxfolder   |
|GIT_NGINX_LOGIN   |NO   |**NO**   |ftx   |
|GIT_NGINX_PASS   |NO   |**NO**   |lsdfgzeihti$!976756   | 
|GIT_NGINX_BRANCH   |NO   |master   |dev   |


##### Git WEB
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|GIT_WEB_REPO   |NO   |**NO**   |https://github.com/ftx/mynginxfolder   |
|GIT_WEB_LOGIN   |NO   |**NO**   |ftx   |
|GIT_WEB_PASS   |NO   |**NO**   |lsdfgzeihti$!976756   | 
|GIT_WEB_BRANCH   |NO   |master   |dev   |

##### FTP
|ENV Variable  |Required |Default   |Example   |
|---|---|---|---|
|FTP   |NO   |**NO**   |YES   |
|FTP_LOGIN   |NO   |flotix   |ftx   |
|FTP_PASSWD   |NO   |**CHANGEME**   |lsdfgzeihti$!976756   |


Don't hesitate to make a pull request!! :kissing_heart:

Contact : flotix@linux.com
Website : www.flotix.jp
