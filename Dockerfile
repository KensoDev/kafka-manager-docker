FROM oraclelinux:6.8

MAINTAINER Avi Zurel <avi@kensodev.com>

RUN yum update -y
RUN yum install -y wget unzip tar git

ENV JDK_VERSION jdk-8u121-linux-x64.rpm
ENV TMP_INSTALL_LOCATION /tmp/kafka-manager
ENV DOWNLOAD_LOCATION /tmp/kafka-manager/jdk-8u121-linux-x64.rpm
ENV MANAGER_VERSION 1.3.1.8
ENV JAVA_HOME /usr/java/jdk1.8.0_121
ENV PATH "${JAVA_HOME}:${PATH}"
ENV MANAGER_CONFIG conf/application.conf

RUN mkdir -p ${TMP_INSTALL_LOCATION} && wget -nv --no-cookies --no-check-certificate \
      --header "Cookie: oraclelicense=accept-securebackup-cookie" \
      "http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/${JDK_VERSION}" \
      -O ${DOWNLOAD_LOCATION}

RUN yum localinstall -y ${DOWNLOAD_LOCATION}

RUN yum install -y curl

ADD kafka-manager-${MANAGER_VERSION} /tmp/kafka-manager-${MANAGER_VERSION}

# For some reason, the `sbt` script is not doing this part correctly
RUN mkdir -p /root/.sbt/launchers/0.13.9
RUN wget http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.9/sbt-launch.jar -O /root/.sbt/launchers/0.13.9/sbt-launch.jar
# END patch

RUN cd /tmp/kafka-manager-$MANAGER_VERSION && ./sbt clean dist
RUN mkdir -p /tmp/extracted
RUN unzip -d /tmp/extracted /tmp/kafka-manager-$MANAGER_VERSION/target/universal/kafka-manager-$MANAGER_VERSION.zip

RUN cd /tmp/extracted/kafka-manager-$MANAGER_VERSION && rm -rf README.md bin/*.bat share/
RUN yes | mv /tmp/extracted/kafka-manager-$MANAGER_VERSION /opt

RUN sed -i -e 's|INFO|ERROR|g' /opt/kafka-manager-$MANAGER_VERSION/conf/logback.xml && \
    sed -i -e 's|WARN|ERROR|g' /opt/kafka-manager-$MANAGER_VERSION/conf/logback.xml && \
    sed -i -e 's|INFO|ERROR|g' /opt/kafka-manager-$MANAGER_VERSION/conf/logger.xml

RUN yum clean all && \
    rm -fr /tmp/* /root/.sbt /root/.ivy2

COPY manager-start.sh /tmp/
RUN mv /tmp/manager-start.sh /opt/kafka-manager-$MANAGER_VERSION/ && \
    chmod +x /opt/kafka-manager-$MANAGER_VERSION/manager-start.sh

WORKDIR /opt/kafka-manager-$MANAGER_VERSION

EXPOSE 9000

ENTRYPOINT ["./manager-start.sh"]
