#!/bin/bash
# This script will install dependencies for laravel projects on blank server
# Pull this file down, make it executable and run it with sudo
#
# sudo chmod u+x prepare_ubuntu_server.sh
# sudo ./prepare_ubuntu_server.sh
#
# Version: 1.0.0-beta


if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi

PS3='you would like to update system: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
			apt-get -y update
			apt-get -y upgrade
			break
            ;;
        "No")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

if systemctl --all --type service | grep -q "nginx";then
    echo "nginx service exists."
else
	# Install Nginx web server
	apt-get -y install nginx
	systemctl enable nginx
	systemctl start nginx  
fi

if ! type "git" > /dev/null; then
	# Install Git version manager
	apt-get -y install git
else
	echo "Git - version manager installed"
fi

if ! type "php" > /dev/null; then
	# Install PHP and packages
	apt-get -y install php php-{mbstring,fpm,gd,json,zip,soap,mbstring,xml,xmlrpc,opcache,gd}
else
	echo "PHP installed"

	PS3='you would like to install generic php packages '
	options=("Yes" "No")
	select opt in "${options[@]}"
	do
		case $opt in
			"Yes")
				apt-get -y install php-{mbstring,fpm,gd,json,zip,soap,mbstring,xml,xmlrpc,opcache,gd}
				break
				;;
			"No")
				break
				;;
			*) echo "invalid option $REPLY";;
		esac
	done
fi

if ! type "composer" > /dev/null; then
	#Install Composer
	apt-get -y install composer
else
	echo "Composer installed"
fi

PS3='Please choice your database: '
options=("MariaDB" "PostgreSQL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "MariaDB")
			if systemctl --all --type service | grep -q "mariadb";then
				echo "mariadb service exists."
			else
				#Install MariaDB database server
				apt-get -y install mariadb-server
				apt-get -y install php-mysql
				systemctl enable mariadb
				systemctl start mariadb
			fi
            break
            ;;
        "PostgreSQL")
			if systemctl --all --type service | grep -q "postgresql";then
				echo "postgresql service exists."
			else
				#Install PostgreSQL database server
				apt-get -y install postgresql postgresql-contrib
				apt-get -y install php-pgsql
				systemctl enable postgresql
				systemctl start postgresql
			fi
            break
            ;;
		"Quit")
			break
			;;
        *) echo "invalid option $REPLY";;
    esac
done

echo please enable and start php-fpm service depends on your version