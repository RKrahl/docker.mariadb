FROM opensuse

RUN zypper --non-interactive modifyrepo --disable non-oss update-non-oss
RUN zypper --non-interactive install \
	mariadb \
	pwgen \
	timezone

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/lib/mysql
RUN chmod 0755 /usr/lib/mysql/docker-entrypoint.sh

ENTRYPOINT ["/usr/lib/mysql/docker-entrypoint.sh"]
