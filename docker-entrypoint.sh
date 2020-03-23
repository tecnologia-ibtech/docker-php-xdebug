#!/bin/bash


# THANKS https://github.com/SocialEngine/docker-php-apache :)


randname() {
    local LC_ALL=C
    tr -dc '[:lower:]' < /dev/urandom |
        dd count=1 bs=16 2>/dev/null
}

create_user_from_directory_owner() {
    if [ $MODE = "dev" ]; then
        owner=www-data
        group=www-data
    else
        if [ $# -ne 1 ]; then
            echo "Creates a user (and group) from the owner of a given directory, if it doesn't exist."
            echo "Usage: create_user_from_directory_owner <path>"

            return 1
        fi

        local owner group owner_id group_id path
        path=$1

        owner=$(stat -c '%U' $path)
        group=$(stat -c '%G' $path)
        owner_id=$(stat -c '%u' $path)
        group_id=$(stat -c '%g' $path)
        
        if [ $owner = "UNKNOWN" ]; then
            owner=$(randname)
            if [ $group = "UNKNOWN" ]; then
                group=$owner
                addgroup --system --gid "$group_id" "$group" > /dev/null
            fi
            adduser --no-create-home --system --uid=$owner_id --gid=$group_id "$owner" > /dev/null
            echo "[Apache User] Created user for uid ($owner_id), and named it '$owner'"
        fi
    fi

    cat << EOF > /usr/local/etc/php-fpm.conf
[global]
error_log = /proc/self/fd/2
daemonize = no
[www]
; if we send this to /proc/self/fd/1, it never appears
access.log = /proc/self/fd/2
user = $owner
group = $group
listen = [::]:9000
pm = ondemand
pm.max_children = 1024
pm.process_idle_timeout = 10s
pm.start_servers = 5
clear_env = no
; Ensure worker stdout and stderr are sent to the main error log.
catch_workers_output = yes
EOF

    export APACHE_RUN_USER=$owner
    export APACHE_RUN_GROUP=$group
    echo "[Apache User] Set APACHE_RUN_USER to $owner and APACHE_RUN_GROUP to $group"

    return 0
}


create_user_from_directory_owner "/var/www/html"

set -e
echo "[ ****************** ] Starting Endpoint of Application"

echo "[ ****************** ] Downloading composer "

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

echo "[ ****************** ] Installing composer "
php composer-setup.php

echo "[ ****************** ] Unlinking and moving composer to '/usr/local/bin/' directory"
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

# X-Debug

if ! [ -v $XDEBUG_REMOTE_ENABLE ] ; then
	pecl shell-test xdebug && echo "Package xdebug Installed" || (
	    echo "[ ****************** ] Starting install of XDebug and dependencies."
	    yes | pecl install xdebug
	    echo "zend_extension="`find /usr/local/lib/php/extensions/ -iname 'xdebug.so'` > $XDEBUGINI_PATH
	    echo "xdebug.remote_enable=$XDEBUG_REMOTE_ENABLE" >> $XDEBUGINI_PATH

	    if ! [ -v $XDEBUG_REMOTE_AUTOSTART ] ; then
	        echo "xdebug.remote_autostart=$XDEBUG_REMOTE_AUTOSTART" >> $XDEBUGINI_PATH
	    fi
	    if ! [ -v $XDEBUG_REMOTE_CONNECT_BACK ] ; then
	        echo "xdebug.remote_connect_back=$XDEBUG_REMOTE_CONNECT_BACK" >> $XDEBUGINI_PATH
	    fi
	    if ! [ -v $XDEBUG_REMOTE_HANDLER ] ; then
	        echo "xdebug.remote_handler=$XDEBUG_REMOTE_HANDLER" >> $XDEBUGINI_PATH
	    fi
	    if ! [ -v $XDEBUG_PROFILER_ENABLE ] ; then
	        echo "xdebug.profiler_enable=$XDEBUG_PROFILER_ENABLE" >> $XDEBUGINI_PATH
	    fi
	    if ! [ -v $XDEBUG_PROFILER_OUTPUT_DIR ] ; then
	        echo "xdebug.profiler_output_dir=$XDEBUG_PROFILER_OUTPUT_DIR" >> $XDEBUGINI_PATH
	    fi
	    if ! [ -v $XDEBUG_REMOTE_PORT ] ; then
	        echo "xdebug.remote_port=$XDEBUG_REMOTE_PORT" >> $XDEBUGINI_PATH
	    fi

	    echo "xdebug.remote_host="`/sbin/ip route|awk '/default/ { print $3 }'` >> $XDEBUGINI_PATH
	    echo "[ ****************** ] Ending install of XDebug and dependencies."

	)
fi

echo "[ ****************** ] Ending Endpoint of Application"
exec "$@"
