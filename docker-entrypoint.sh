#!/bin/bash

datadir=/var/lib/mysql

die() {
    echo "$1"
    exit 1
}

mysql_wait() {
    [[ -z "$1" ]] || socket="$1"
    echo "Waiting for MySQL to start"
    for i in {1..60}; do
	/usr/bin/mysqladmin --socket="$socket" ping > /dev/null 2>&1 && break
	sleep 1
    done
    if /usr/bin/mysqladmin --socket="$socket" ping > /dev/null 2>&1; then
	echo "MySQL is alive"
	return 0
    else
	echo "MySQL is still dead"
	return 1
    fi
}

mysql_init() {
    rootpw="$(pwgen -s 32 1)"

    echo "Creating MySQL privilege database... "
    mysql_install_db --user=mysql --datadir=$datadir || \
	die "Creation of MySQL databse in $datadir failed"

    protected="$(mktemp -d -p /var/tmp mysql-protected.XXXXXX)"
    [ -n "$protected" ] || \
	die "Can't create a tmp dir '$protected'"
    chown --no-dereference mysql:mysql "$protected" || \
	die "Failed to set group/user to '$protected'"

    echo "Running protected MySQL... "
    /usr/sbin/mysqld \
	--defaults-file=/etc/my.cnf \
	--user=mysql \
	--skip-networking \
	--log-error=$protected/log_init_run \
	--socket=$protected/mysql.sock \
	--pid-file=$protected/mysqld.pid &

    mysql_wait $protected/mysql.sock || \
	die "MySQL didn't start, can't continue"

    echo "Sanitize privileges"
    /usr/bin/mysql --socket=$protected/mysql.sock <<EOSQL
	DELETE FROM mysql.user ;
	CREATE USER 'root'@'%' IDENTIFIED BY '${rootpw}' ;
	GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
	DROP DATABASE IF EXISTS test ;
	FLUSH PRIVILEGES ;
EOSQL
    /usr/bin/cat > /root/.my.cnf <<EOF
[client]
host = localhost
user = root
password = ${rootpw}
EOF
    chmod 600 /root/.my.cnf

    for f in /etc/mysql.d/*; do
	case "$f" in 
	    *.sql)   echo "running $f"
	             /usr/bin/mysql --socket=$protected/mysql.sock < $f ;;
	    *)       echo "ignoring $f" ;;
	esac
    done

    echo "Shuting down protected MySQL"
    kill "$(cat $protected/mysqld.pid)"
    for i in {1..30}; do
	/usr/bin/mysqladmin --socket="$protected/mysql.sock" ping > /dev/null 2>&1 || \
	    break
    done
    /usr/bin/mysqladmin --socket="$protected/mysql.sock" ping > /dev/null 2>&1 && \
	kill -9 "$(cat $protected/mysqld.pid)"

    echo "Final cleanup"
    rm -rf $protected
}

mkdir -p /var/run/mysql
chown --no-dereference mysql:mysql /var/run/mysql

if [[ ! -d $datadir/mysql ]]; then
    mysql_init
fi

exec /usr/sbin/mysqld --defaults-file=/etc/my.cnf --user=mysql
