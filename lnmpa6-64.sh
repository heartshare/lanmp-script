#!/bin/sh
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
#配置脚本需要环境
download_path=/tmp/lnmpa
install_path=/data/webserver
web_root=/data/web
cmake_v=cmake-2.8.11.2
mysql_v=mysql-5.6.13
libunwind_v=libunwind-1.1
gperftools_v=gperftools-2.1
apr_v=apr-1.4.8
apr_util_v=apr-util-1.5.2
pcre_v=pcre-8.33
httpd_v=httpd-2.4.6
nginx_v=nginx-1.5.4
php_v=php-5.4.26
mkdir -p $install_path
mkdir -p $download_path
yum install -y wget
#下载安装包
cd $download_path
#mysql
wget http://soft.gjj.name/$cmake_v.tar.gz
wget http://soft.gjj.name/$mysql_v.tar.gz
wget http://soft.gjj.name/$libunwind_v.tar.gz
wget http://soft.gjj.name/$gperftools_v.tar.gz
#apache
wget http://soft.gjj.name/$apr_v.tar.gz
wget http://soft.gjj.name/$apr_util_v.tar.gz
wget http://soft.gjj.name/$pcre_v.tar.bz2
wget http://soft.gjj.name/$httpd_v.tar.gz
#nginx
wget http://soft.gjj.name/$nginx_v.tar.gz
#php
wget http://soft.gjj.name/$php_v.tar.gz
wget http://soft.gjj.name/pthreads-master.zip
wget http://soft.gjj.name/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
wget http://soft.gjj.name/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
wget http://soft.gjj.name/oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm
#------------------------------安装mysql------------------------------
#依赖库
yum install -y wget gcc gcc-c++ make ncurses-devel qt-devel bison perl
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
#安装工具
cd $download_path
tar zxvf $cmake_v.tar.gz
cd $cmake_v
./configure
make && make install
#安装mysql
cd $download_path
tar zxvf $mysql_v.tar.gz
cd $mysql_v
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/usr/local/mysql_data -DENABLE_DOWNLOADS=1
make && make install
#开放防火墙端口
iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
service iptables save
#配置mysql
groupadd mysql
useradd -r -g mysql mysql
chown -R mysql:mysql /usr/local/mysql
cd /usr/local/mysql/scripts
./mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql_data
cd /usr/local/mysql/support-files
\cp -f mysql.server /etc/rc.d/init.d/mysqld
\cp -f my-default.cnf /etc/my.cnf
chkconfig --add mysqld
chkconfig mysqld on
ln -s /usr/local/mysql/lib/lib* /usr/lib/
ln -s /usr/local/mysql/bin/mysql /bin
sed -i '/executing mysqld_safe/ a export LD_PRELOAD=/usr/local/lib/libtcmalloc.so' /usr/local/mysql/bin/mysqld_safe
#启动mysql
service mysqld start
#--------------------apache--------------------------
#安装apache依赖库
yum install -y gcc libtool make gcc-c++ lynx
#安装软件
cd $download_path
tar zxvf $apr_v.tar.gz
cd $apr_v
./configure
make && make install
cd $download_path
tar zxvf $apr_util_v.tar.gz
cd $apr_util_v
./configure --with-apr=/usr/local/apr/
make && make install
cd $download_path
tar jxvf $pcre_v.tar.bz2
cd $pcre_v
./configure
make && make install
cd $download_path
tar zxvf $httpd_v.tar.gz
cd $httpd_v
./configure --enable-so --prefix=/usr/local/apache2
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
cat >>/usr/local/apache2/conf/vhost/default.conf<<EOF
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
yum install gcc make gcc-c++ zlib-devel -y
#安装nginx
cd $download_path
tar zxvf $nginx_v.tar.gz
cd $nginx_v
./configure --prefix=/usr/local/nginx
make && make install
#开放防火墙端口
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
service iptables save
#配置nginx
mkdir /usr/local/nginx/conf/vhost
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
	include vhost/*.conf;
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
#安装oracle插件
cd $download_path
yum install -y oracle-instantclient11.2*
echo "/usr/lib/oracle/11.2/client64/lib/">>/etc/ld.so.conf
ldconfig
echo "export ORACLE_HOME=/usr/lib/oracle/11.2/client64">>/etc/profile
echo "export LD_LIBRARY_PATH=/usr/lib/oracle/11.2/client64/lib/:$LD_LIBRARY_PATH">>/etc/profile
echo "export NLS_LANG=\"SIMPLIFIED CHINESE_CHINA.ZHS16GBK\"">>/etc/profile
#安装php
cd $download_path
tar zxvf $php_v.tar.gz
cd $php_v
./configure --prefix=/usr/local/php --with-apxs2=/usr/local/apache2/bin/apxs --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-iconv-dir --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-fpm --enable-mbstring --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pdo-mysql --enable-maintainer-zts --with-pdo-oci=instantclient,/usr,11.2 --with-oci8=instantclient,/usr/lib/oracle/11.2/client64/lib/
make && make install
cp php.ini-development /usr/local/php/lib/php.ini
#配置php多线程
cd $download_path
unzip pthreads-master.zip
cd pthreads-master
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
sed -i "/CLI Server/ iextension=/usr/local\/php\/lib\/php\/extensions\/no-debug-zts-20100525\/pthreads.so" /usr/local/php/lib/php.ini
cat>>/data/script/add_website.sh<<FOE
#!/bin/bash
if [ "\$1" != "" ] && [ "\$2" != "" ];then
	root_path=/data/web/\$1/root
	log_path=/data/web/\$1/logs
	if [ -d "\$root_path" ] || [ -d "\$log_path" ]; then
		echo -e "\033[33m The WebSite Has Create,Nothing To Do \033[0m"
		exit 1
	fi
	mkdir -p \$root_path
	mkdir -p \$log_path
	cat>>/usr/local/apache2/conf/vhost/\$1.conf<<EOF
<VirtualHost *:88>
	ServerAdmin dggugjj@163.com
	DocumentRoot "\$root_path"
	ServerName \$2
	ErrorLog "\$log_path/error.log"
	CustomLog "\$log_path/custom.log" common
</VirtualHost>
EOF
	cat>>/usr/local/nginx/conf/vhost/\$1.conf<<EOF
server{
	listen 80;
	server_name \$2;
	location / {
		root   \$root_path;
		index  index.html index.htm index.php;
	}
	location ~ \.php\$ {
		proxy_pass http://127.0.0.1:88;
		include apache.conf;
	}
	access_log  \$log_path/access.log;
}
EOF
nginx -s reload
service httpd restart
echo "WebSite Create Success"
exit 1
fi
function clear_ping()
{
	clear
	echo "====================================================================="
	echo -e "\033[32m WebSite Name: \033[0m"
	echo \$website_name
	echo -e "\033[32m Domain List: \033[0m"
	for line in \${domain_list[@]}; do
	echo -e "\$line"
	done
	echo -e "\033[32m Jump Domain List: \033[0m"
	for line in \${jump_list[@]}; do
	echo "\$line"
	done
	echo "====================================================================="
}
clear
read -p "Please Input WebSite Name:" website_name
read -p "Please Input Domain:" master_domain
domain_list[0]=\$master_domain
jump_list[0]=""
jump_index=0
salve_index=1
while [ "\$add_salve" != "true" ];do
	clear_ping
	read -p "Add Domain?(y|n)" chose
	case "\$chose" in
		y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
		clear_ping
		confirm="false"
		add_salve="false"
		while [ "\$confirm" != "true" ];do
			read -p "Please Input Domain:" salve_domain
			read -p "Confirm Input?(y|n):" chose
			case "\$chose" in
				y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
				domain_list[salve_index]=\$salve_domain
				salve_index=`expr \$salve_index + 1`
				confirm="true"
				;;
				n|N|No|NO|no|nO)
				clear_ping
				confirm="false"
				;;
			esac
		done
		;;
		n|N|No|NO|no|nO)
		clear_ping
		add_salve="true"
		;;
	esac
done
#添加跳转
add_salve="false"
while [ "\$add_salve" != "true" ];do
	clear_ping
	read -p "Add Jump Domain?(y|n)" chose
	case "\$chose" in
		y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
		clear_ping
		confirm="false"
		add_salve="false"
		while [ "\$confirm" != "true" ];do
			read -p "Please Input Jump Domain:" domain
			read -p "Confirm Input?(y|n):" chose
			case "\$chose" in
				y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
				jump_list[jump_index]=\$domain
				jump_index=`expr \$jump_index + 1`
				confirm="true"
				;;
				n|N|No|NO|no|nO)
				clear_ping
				confirm="false"
				;;
			esac
		done
		;;
		n|N|No|NO|no|nO)
		clear_ping
		add_salve="true"
		;;
	esac
done
read -p "Sure Create WebSite?(y|n):" chose
case "\$chose" in
	y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        ;;
        n|N|No|NO|no|nO)
	exit 1
        ;;
esac
#开始创建
root_path=/data/web/\$website_name/root
log_path=/data/web/\$website_name/logs
if [ -d "\$root_path" ] || [ -d "\$log_path" ]; then
	echo -e "\033[33m The WebSite Has Create,Nothing To Do \033[0m"
	exit 1
fi
mkdir -p \$root_path
mkdir -p \$log_path
domain_str=""
for line in \${domain_list[@]}; do
	domain_str=\$domain_str" \$line"
done
cat>>/usr/local/apache2/conf/vhost/\$website_name.conf<<EOF
<VirtualHost *:88>
	ServerAdmin dggugjj@163.com
	DocumentRoot "\$root_path"
	ServerName \$domain_str
	ErrorLog "\$log_path/error.log"
	CustomLog "\$log_path/custom.log" common
</VirtualHost>
EOF
cat>>/usr/local/nginx/conf/vhost/\$website_name.conf<<EOF
server{
	listen 80;
	server_name \$domain_str;
	location / {
		root   \$root_path;
		index  index.html index.htm index.php;
	}
	location ~ \.php\$ {
		proxy_pass http://127.0.0.1:88;
		include apache.conf;
	}
	access_log  \$log_path/access.log;
}
EOF
for line in \${jump_list[@]}; do
	cat>>/usr/local/nginx/conf/vhost/\$website_name.conf<<EOF
server{
	server_name \$line;
	rewrite ^(.*) http://\$master_domain\\\$1 permanent;
}
EOF
done
nginx -s reload
service httpd restart
echo "WebSite Create Success"
FOE
chmod +x /data/script/add_website.sh
service httpd stop
service httpd start