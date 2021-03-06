#!/bin/bash

datadir=/var/lib/mysql
mysqld=/usr/sbin/mysqld

die() {
    echo "$1"
    exit 1
}

mysql_wait() {
    [[ -z "$1" ]] || socket="$1"
    echo "Waiting for MySQL to start"
    for i in {1..60}
    do
	mysqladmin --socket="$socket" ping > /dev/null 2>&1 && break
	sleep 1
    done
    if mysqladmin --socket="$socket" ping > /dev/null 2>&1
    then
	echo "MySQL is alive"
	return 0
    else
	echo "MySQL is still dead"
	return 1
    fi
}

mysql_init() {
    echo "Creating MySQL privilege database... "
    mysql_install_db --user=mysql --datadir=$datadir || \
	die "Creation of MySQL databse in $datadir failed"

    protected="$(mktemp -d -p /var/tmp mysql-protected.XXXXXX)"
    [ -n "$protected" ] || \
	die "Can't create a tmp dir '$protected'"
    chown --no-dereference mysql:mysql "$protected" || \
	die "Failed to set group/user to '$protected'"

    echo "Running protected MySQL... "
    $mysqld \
	--defaults-file=/etc/my.cnf \
	--user=mysql \
	--skip-networking \
	--log-error=$protected/log_init_run \
	--socket=$protected/mysql.sock \
	--pid-file=$protected/mysqld.pid &

    mysql_wait $protected/mysql.sock || \
	die "MySQL didn't start, can't continue"

    echo "Sanitize privileges"
    mysql --socket=$protected/mysql.sock <<EOSQL
	DELETE FROM mysql.user WHERE User='' ;
	DROP DATABASE IF EXISTS test ;
	DELETE FROM mysql.db ;
	FLUSH PRIVILEGES ;
EOSQL

    for f in /etc/mysql.d/*.sql
    do
	if [[ -f "$f" ]]
	then
	    echo "running $f"
	    mysql --socket=$protected/mysql.sock < $f
	fi
    done

    echo "Shuting down protected MySQL"
    kill "$(cat $protected/mysqld.pid)"
    for i in {1..30}
    do
	mysqladmin --socket="$protected/mysql.sock" ping > /dev/null 2>&1 || \
	    break
    done
    mysqladmin --socket="$protected/mysql.sock" ping > /dev/null 2>&1 && \
	kill -9 "$(cat $protected/mysqld.pid)"

    echo "Final cleanup"
    rm -rf $protected
}

if [[ ! -d $datadir/mysql ]]
then
    mysql_init
fi

$mysqld --defaults-file=/etc/my.cnf --user=mysql &

mysql_wait /var/run/mysql/mysql.sock || \
    die "MySQL didn't start, can't continue"

for f in /etc/mysql.d/*.sh
do
    if [[ -x "$f" ]]
    then
	echo "running $f"
	$f
    fi
done
