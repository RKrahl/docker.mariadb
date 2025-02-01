FROM rkrahl/opensuse:15.6

RUN zypper --non-interactive refresh

RUN zypper --non-interactive removelock python3-base

RUN zypper --non-interactive addrepo https://download.opensuse.org/repositories/home:/Rotkraut:/HZB-RDM/15.6/home:Rotkraut:HZB-RDM.repo && \
    zypper --non-interactive --gpg-auto-import-keys refresh home_Rotkraut_HZB-RDM && \
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
