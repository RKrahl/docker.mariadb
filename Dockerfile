FROM rkrahl/opensuse:15.5

RUN zypper --non-interactive refresh

RUN zypper --non-interactive removelock python3-base

COPY user-mysql.noarch.rpm /usr/src/packages/RPMS/noarch/

RUN zypper --non-interactive addrepo /usr/src/packages/RPMS/ local && \
    zypper --non-interactive modifyrepo --no-gpgcheck local && \
    zypper --non-interactive refresh local && \
    zypper --non-interactive install \
        user-mysql.noarch && \
    zypper --non-interactive install \
	mariadb && \
    sed -i -e 's/^\(bind-address .*\)/#\1/' /etc/my.cnf

RUN mkdir -p /var/run/mysql /etc/mysql /etc/mysql.d && \
    chown mysql:mysql /var/run/mysql
COPY start-mysql.sh /etc/mysql
RUN chmod 0755 /etc/mysql/start-mysql.sh

CMD ["/etc/mysql/start-mysql.sh"]

VOLUME ["/var/lib/mysql"]

EXPOSE 3306
