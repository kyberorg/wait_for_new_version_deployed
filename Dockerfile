FROM ghcr.io/graalvm/graalvm-ce:21.0.0 AS build-aot

RUN curl https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -o /tmp/maven.tar.gz
RUN tar xf /tmp/maven.tar.gz -C /opt
RUN ln -s /opt/apache-maven-3.6.3 /opt/maven
RUN ln -s /opt/graalvm-ce-java11-21.0.0 /opt/graalvm
RUN gu install native-image

ENV JAVA_HOME=/opt/graalvm
ENV M2_HOME=/opt/maven
ENV MAVEN_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}
ENV PATH=${JAVA_HOME}/bin:${PATH}

COPY ./pom.xml ./pom.xml
COPY src ./src/
COPY reflect.json /reflect.json

ENV MAVEN_OPTS='-Xmx10g'
RUN mvn clean package

# Create a minimal docker container and copy the app into it
#FROM alpine:latest
FROM debian:buster-slim
WORKDIR /app

ENV javax.net.ssl.trustStore /cacerts
ENV javax.net.ssl.trustAnchors /cacerts

COPY --from=build-aot target/wait4version /app/wait4version
COPY --from=build-aot /opt/graalvm/lib/libsunec.so /libsunec.so
COPY --from=build-aot /opt/graalvm/lib/security/cacerts /cacerts

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
