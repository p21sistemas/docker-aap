FROM amazonlinux:2018.03
# Comments
# groupinstall "Development Tools" is necessary for xdebug

# update amazon software repo
RUN yum -y update && yum -y install shadow-utils yum-utils\
    && yum-config-manager --enable remi-php74 && yum -y update

#configure time zone
RUN ln -f -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

#Intall utilites
RUN yum -y install vim wget git && yum -y groupinstall "Development Tools"

#Install apache
RUN yum install -y httpd24 httpd24-tools mod24_ssl
#Auto start service
RUN chkconfig httpd on
RUN service httpd start

#Install php
RUN yum install -y php74 php74-devel php74-cli php74-common php74-gd php74-intl php74-jsonc php-pear\
    php74-mbstring php74-mcrypt php74-mysqlnd php74-pdo php74-pecl-redis php74-soap php74-xml php74-xmlrpc

#Configurações adicionais do php
RUN echo 'include_path = ".:/usr/local/etc/php/"' >> /etc/php.ini

#Install XDebug
RUN pecl install xdebug-3.0.4

#Configuration XDebug
RUN echo 'zend_extension=/usr/lib64/php/7.4/modules/xdebug.so' >> /etc/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Quality tools
RUN USERNAME=$('whoami') && composer global require squizlabs/php_codesniffer=*  phpcompatibility/php-compatibility=* \
       friendsofphp/php-cs-fixer=* phpmd/phpmd=* \
    && export PATH=/$USERNAME/.composer/vendor/bin:$PATH \
    && phpcs --config-set installed_paths /$USERNAME/.composer/vendor/phpcompatibility/php-compatibility/ \
    && phpcs -i

#Blackfire.io
RUN mkdir "/conf.d" && version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /etc/php/7.4/fpm/conf.d/blackfire.ini

EXPOSE  80

ENTRYPOINT ["/usr/sbin/httpd","-D","FOREGROUND"]