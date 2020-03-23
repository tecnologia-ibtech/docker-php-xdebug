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

exec "$@"
