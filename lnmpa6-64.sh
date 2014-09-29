#!/bin/sh
script_path=`dirname $0`
cpus=`cat /proc/cpuinfo | grep "processor" | wc -l`
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
yum install -y wget gcc gcc-c++ make ncurses-devel qt-devel bison perl cmake
tar zxvf $script_path/lib/mysql-5.6.20.tar.gz -C /tmp/
cd /tmp/mysql-5.6.20
cmake . -DENABLE_DOWNLOADS=1
make -j $cpus
make install
#开放防火墙端口
iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
service iptables save
#配置mysql
groupadd mysql
useradd -r -g mysql mysql
chown -R mysql:mysql /usr/local/mysql
cd /usr/local/mysql/scripts
./mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
cd /usr/local/mysql/support-files
\cp -f mysql.server /etc/rc.d/init.d/mysqld
\cp -f my-default.cnf /etc/my.cnf
chkconfig --add mysqld
chkconfig mysqld on
ln -s /usr/local/mysql/lib/lib* /usr/lib/
ln -s /usr/local/mysql/bin/mysql /bin
#启动mysql
service mysqld start
#--------------------apache--------------------------
#安装apache依赖库
yum install -y gcc libtool make gcc-c++ lynx
#安装软件
tar zxvf $script_path/lib/apr-1.5.1.tar.gz -C /tmp/
cd /tmp/apr-1.5.1
./configure
make && make install
tar zxvf $script_path/lib/apr-util-1.5.3.tar.gz -C /tmp/
cd /tmp/apr-util-1.5.3
./configure --with-apr=/usr/local/apr/
make && make install
tar zxvf $script_path/lib/pcre-8.35.tar.gz -C /tmp/
cd /tmp/pcre-8.35
./configure
make && make install
tar zxvf $script_path/lib/httpd-2.4.10.tar.gz -C /tmp/
cd /tmp/httpd-2.4.10
./configure --enable-so
make && make install
#开放防火墙端口
iptables -I INPUT -p tcp --dport 88 -j ACCEPT
service iptables save
#配置apache
useradd www
mkdir /usr/local/apache2/conf/vhost
mkdir -p /data/web
mkdir -p /data/web/default
mkdir -p /data/web/default/root
mkdir -p /data/web/default/logs
chown www:www -R /usr/local/apache2
chown www:www -R /usr/local
echo "127.0.0.1 `hostname`">>/etc/hosts
ln -s /usr/local/apache2/bin/httpd /bin
cp /usr/local/apache2/bin/apachectl /etc/rc.d/init.d/httpd
cat>>/etc/ld.so.conf.d/libc.conf<<EOF
/usr/local/lib
EOF
sudo ldconfig
sed -i '/#!/ a#description:Apache httpd' /etc/rc.d/init.d/httpd
sed -i '/#!/ a#chkconfig:345 61 61' /etc/rc.d/init.d/httpd
cat >>/usr/local/apache2/conf/httpd.conf<<EOF
<Location /server-status>
	SetHandler server-status
	Order deny,allow
	Allow from all
</Location>
EOF
sed -i 's/Listen 80/Listen 88/' /usr/local/apache2/conf/httpd.conf
sed -i 's/#ServerName www.example.com:80/ServerName 127.0.0.1/' /usr/local/apache2/conf/httpd.conf
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /usr/local/apache2/conf/httpd.conf
sed -i 's/User daemon/User www/' /usr/local/apache2/conf/httpd.conf
sed -i 's/Group daemon/Group www/' /usr/local/apache2/conf/httpd.conf
sed -i '/mime.types/ aAddtype application\/x-httpd-php .php' /usr/local/apache2/conf/httpd.conf
sed -i '196d' /usr/local/apache2/conf/httpd.conf
sed -i '196d' /usr/local/apache2/conf/httpd.conf
sed -i '196d' /usr/local/apache2/conf/httpd.conf
sed -i '196d' /usr/local/apache2/conf/httpd.conf
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.php/' /usr/local/apache2/conf/httpd.conf
sed -i 's/#Include conf\/extra\/httpd-vhosts.conf/Include conf\/vhost\/*.conf/' /usr/local/apache2/conf/httpd.conf
sed -i 's/ServerAdmin you@example.com/ServerAdmin dgugjj@163.com/' /usr/local/apache2/conf/httpd.conf
sed -i 's/\/data\/webserver\/apache2\/htdocs/\/data\/web/' /usr/local/apache2/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /usr/local/apache2/conf/httpd.conf
cat >>/usr/local/apache2/conf/vhost/0000-default.conf<<EOF
<VirtualHost *:88>
ServerAdmin dggugjj@163.com
DocumentRoot "/data/web/default/root"
ServerName 127.0.0.1
ErrorLog "/data/web/default/logs/error.log"
CustomLog "/data/web/default/logs/custom.log" common
</VirtualHost>
EOF
#启动apache
service httpd start
#------------------------nginx-------------------------
#安装nginx依赖库
yum install -y gcc make gcc-c++ zlib-devel
#安装nginx
tar zxvf $script_path/lib/nginx-1.7.5.tar.gz -C /tmp/
cd /tmp/nginx-1.7.5
./configure
make && make install
#开放防火墙端口
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
service iptables save
#配置nginx
mkdir -p /usr/local/nginx/conf/vhost
ln -s /usr/local/lib/libpcre.so.1 /lib64/
ln -s /usr/local/nginx/sbin/* /bin/
rm -f /usr/local/nginx/conf/nginx.conf
cat >>/usr/local/nginx/conf/nginx.conf<<EOF
user  www;
worker_processes  8;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
	include vhost/*.conf;
}
EOF
car >>/usr/local/nginx/conf/vhost/0000-default.conf<<EOF
server{
    listen 80;
    server_name 127.0.0.1;
    root   /data/web/default/root;
    index  index.html index.htm index.php;
    location / {
            try_files \$uri @apache;
    }

    location @apache {
            internal;
            proxy_pass http://127.0.0.1:88;
            include apache.conf;
    }

    location ~ \.php$ {
            proxy_pass http://127.0.0.1:88;
            include apache.conf;
    }

    access_log  /data/web/default/logs/access.log;
}
EOF
cat >>/usr/local/nginx/conf/apache.conf<<EOF
proxy_connect_timeout 300s;
proxy_send_timeout   900;
proxy_read_timeout   900;
proxy_buffer_size    32k;
proxy_buffers     4 32k;
proxy_busy_buffers_size 64k;
proxy_redirect     off;
proxy_hide_header  Vary;
proxy_set_header   Accept-Encoding '';
proxy_set_header   Host   \$http_host;
proxy_set_header   Referer \$http_referer;
proxy_set_header   Cookie \$http_cookie;
proxy_set_header   X-Real-IP  \$remote_addr;
proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF
#启动nginx
nginx
#-----------------------php------------------------------
#安装php依赖库
yum install -y libxml2-devel gd gd-devel curl curl-devel openssl* unzip
#安装php
cd $download_path
tar zxvf $php_v.tar.gz
cd $php_v
./configure --prefix=/usr/local/php \
--with-apxs2=/usr/local/apache2/bin/apxs \
--with-mysql=/usr/local/mysql \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-iconv-dir \
--with-zlib \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--with-pdo-mysql \
--enable-maintainer-zts \
--with-pdo-oci=instantclient,/usr,11.2 \
--with-oci8=instantclient,/usr/lib/oracle/11.2/client64/lib/
make && make install
cp php.ini-development /usr/local/php/lib/php.ini
