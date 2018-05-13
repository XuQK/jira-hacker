FROM openjdk:8-alpine

# 环境变量
ENV JIRA_HOME    /var/atlassian/jira
ENV JIRA_INSTALL /opt/atlassian/jira
ENV JIRA_VERSION 7.3.8

# 准备工作
# 1. 创建临时目录
# 2. 将需要的文件上传到临时目录/tmp

COPY ./atlassian-jira-software-7.3.8.tar.gz /tmp/atlassian-jira-software-7.3.8.tar.gz
COPY ./atlassian-extras-3.2.jar             /tmp/atlassian-extras-3.2.jar
COPY ./mysql-connector-java-5.1.39-bin.jar  /tmp/mysql-connector-java-5.1.39-bin.jar
COPY ./postgresql-9.4.1212.jar              /tmp/postgresql-9.4.1212.jar
COPY ./repositories                         /tmp/repositories
#COPY ./docker-entrypoint.sh                 /tmp/docker-entrypoint.sh

RUN set -x \
    && mv /etc/apk/repositories /etc/apk/repositories.bak \
    && mv /tmp/repositories /etc/apk/repositories \
    && chown root:root /etc/apk/repositories \
    && apk update --quiet \
    && apk add --no-cache curl xmlstarlet bash ttf-dejavu libc6-compat \
    && mkdir -p                "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            "${JIRA_HOME}" \
    && chown -R daemon:daemon  "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL}/conf/Catalina" \
    && tar -zxf                "/tmp/atlassian-jira-software-${JIRA_VERSION}.tar.gz" --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
#    && curl -Ls                "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.45.tar.gz" | tar -xz --directory "${JIRA_INSTALL}/atlassian-jira/WEB-INF/lib/" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.45/mysql-connector-java-5.1.45-bin.jar" \
    && mv /tmp/mysql-connector-java-5.1.39-bin.jar "${JIRA_INSTALL}/lib" \
    && rm -f                   "${JIRA_INSTALL}/lib/postgresql-9.1-903.jdbc4-atlassian-hosted.jar" \
    && curl -Ls                "https://jdbc.postgresql.org/download/postgresql-42.2.1.jar" -o "${JIRA_INSTALL}/lib/postgresql-42.2.1.jar" \
    && echo -e                 "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           "${JIRA_INSTALL}/conf/server.xml" \
# 使用补丁包替换掉原来的jar包
    && rm -rf                  "${JIRA_INSTALL}/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar" \
    && cp                      "/tmp/atlassian-extras-3.2.jar" "${JIRA_INSTALL}/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar" \
    && chmod -R 700            "${JIRA_INSTALL}/conf" \
    && chmod -R 700            "${JIRA_INSTALL}/logs" \
    && chmod -R 700            "${JIRA_INSTALL}/temp" \
    && chmod -R 700            "${JIRA_INSTALL}/work" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/conf" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/logs" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/temp" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/work" \
    && sed --in-place          "s/java version/openjdk version/g" "${JIRA_INSTALL}/bin/check-java.sh"

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
USER daemon:daemon

# Expose default HTTP connector port.
EXPOSE 8080

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/jira", "/opt/atlassian/jira/logs"]

# Set the default working directory as the installation directory.
#WORKDIR /var/atlassian/jira

#COPY /tmp/docker-entrypoint.sh "/"
#ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian JIRA as a foreground process by default.
CMD ["/opt/atlassian/jira/bin/start-jira.sh", "-fg"]
