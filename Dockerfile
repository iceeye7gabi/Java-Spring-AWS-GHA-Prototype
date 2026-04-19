FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY target/application.jar application.jar

EXPOSE 8080

ENV JAVA_OPTS=""

ENTRYPOINT exec java $JAVA_OPTS -jar application.jar
