FROM rkrahl/opensuse:15.0

RUN zypper --non-interactive install \
	mariadb

RUN mkdir -p /etc/mysql /etc/mysql.d
COPY start-mysql.sh /etc/mysql
RUN chmod 0755 /etc/mysql/start-mysql.sh

CMD ["/etc/mysql/start-mysql.sh"]

VOLUME ["/var/lib/mysql"]

EXPOSE 3306
