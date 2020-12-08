#!/bin/bash
# This script will install dependencies for laravel projects on blank server
# Pull this file down, make it executable and run it with sudo
#
# sudo chmod u+x prepare_centos_server.sh
# sudo ./prepare_centos_server.sh
#
# Version: 1.0.0-beta

if [ $(id -u) != "0" ]; then
  echo "You must be the superuser to run this script" >&2
  exit 1
fi

PS3='you would like to update system: '
options=("Yes" "No")
select opt in "${options[@]}"; do
  case $opt in
  "Yes")
    yum -y update
    break
    ;;
  "No")
    break
    ;;
  *) echo "invalid option $REPLY" ;;
  esac
done

if systemctl --all --type service | grep -q "nginx"; then
  echo "nginx service exists."
else
  # Install Nginx web server
  echo "installing nginx service"
  yum -y install nginx
  systemctl enable nginx
  systemctl start nginx
  echo "nginx web server, ok! "
fi

PS3='You would like add http/s rules on firewall: '
options=("http" "https" "both" "Quit")
select opt in "${options[@]}"; do
  case $opt in
  "http")
    firewall-cmd --zone=public --permanent --add-service=http
    firewall-cmd --reload
    break
    ;;
  "https")
    firewall-cmd --zone=public --permanent --add-service=https
    firewall-cmd --reload
    break
    ;;
  "both")
    firewall-cmd --zone=public --permanent --add-service=http
    firewall-cmd --zone=public --permanent --add-service=https
    firewall-cmd --reload
    break
    ;;
  "Quit")
    break
    ;;
  *) echo "invalid option $REPLY" ;;
  esac
done

PS3='You would like add web server rules on selinux: '
options=("yes" "no")
select opt in "${options[@]}"; do
  case $opt in
  "yes")

    if ! type "semanage" >/dev/null; then
      case $(eval "rpm --eval '%{centos_ver}'") in
      "7")
        yum install -y policycoreutils-python
        source ~/.bashrc
        semanage permissive -a httpd_t
        break
        ;;
      "8")
        yum install -y policycoreutils-python-utils
        break
        ;;
      *) break ;;
      esac
    fi

    break
    ;;
  "no")
    break
    ;;
  *) echo "invalid option $REPLY" ;;
  esac
done

if ! type "git" >/dev/null; then
  echo "installing git version manager"
  yum -y install git
  echo "Git - version manager, ok!"
else
  echo "Git version manager exists"
fi

if ! type "php" >/dev/null; then
  yum -y install php php-{mbstring,fpm,gd,json,zip,soap,xml,xmlrpc,opcache,gd}
else
  echo "PHP installed"

  PS3='you would like to install generic php packages: '
  options=("Yes" "No")
  select opt in "${options[@]}"; do
    case $opt in
    "Yes")
      yum -y install php-{mbstring,fpm,gd,json,zip,soap,xml,xmlrpc,opcache,gd}
      break
      ;;
    "No")
      break
      ;;
    *) echo "invalid option $REPLY" ;;
    esac
  done
fi

PS3='Please choice php driver connection: '
options=("MariaDB" "PostgreSQL" "Quit")
select opt in "${options[@]}"; do
  case $opt in
  "MariaDB")
    yum -y install php-mysqlnd
    break
    ;;
  "PostgreSQL")
    yum -y install php-pgsql
    break
    ;;
  "Quit")
    break
    ;;
  *) echo "invalid option $REPLY" ;;
  esac
done

if ! type "/usr/local/bin/composer" >/dev/null; then
  echo "installing composer"
  PS3='you would like to intall composer php package manager: '
  options=("Yes" "No")
  select opt in "${options[@]}"; do
    case $opt in
    "Yes")

      EXPECTED_CHECKSUM="$(curl https://composer.github.io/installer.sig)"
      php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

      if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo >&2 'ERROR: Invalid installer checksum'
        rm composer-setup.php
        exit 1
      fi

      php composer-setup.php
      rm composer-setup.php
      mv $PWD/composer.phar /usr/local/bin/composer
      sudo chmod +x /usr/local/bin/composer

      break
      ;;
    "No") break ;;
    *) echo "invalid option $REPLY" ;;
    esac
  done
  echo "Composer - php package manager, installed!"
else
  echo "Composer - php package manager, ok!"
fi

PS3='Please choice your database: '
options=("MariaDB" "PostgreSQL" "Quit")
select opt in "${options[@]}"; do
  case $opt in
  "MariaDB")
    if systemctl --all --type service | grep -q "mariadb"; then
      echo "mariadb service exists."
    else
      #Install MariaDB database server
      yum -y install mariadb-server
      systemctl enable mariadb
      systemctl start mariadb
      echo "mariadb service installed."
    fi
    break
    ;;
  "PostgreSQL")
    if systemctl --all --type service | grep -q "postgresql"; then
      echo "postgresql service exists."
    else
      #Install PostgreSQL database server
      yum -y install postgresql postgresql-server
      systemctl enable postgresql
      postgresql-setup initdb
      systemctl start postgresql
      echo "postgresql service installed."
    fi
    break
    ;;
  "Quit")
    break
    ;;
  *) echo "invalid option $REPLY" ;;
  esac
done

echo please enable and start php-fpm service depends on your version
