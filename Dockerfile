FROM opensuse

RUN zypper --non-interactive modifyrepo --disable non-oss update-non-oss
RUN zypper --non-interactive install \
	mariadb \
	pwgen \
	timezone

VOLUME /var/lib/mysql

RUN mkdir -p /etc/mysql /etc/mysql.d
COPY docker-entrypoint.sh /etc/mysql
RUN chmod 0755 /etc/mysql/docker-entrypoint.sh

ENTRYPOINT ["/etc/mysql/docker-entrypoint.sh"]
