# syntax=docker/dockerfile:1
# ---- Build stage: compile + package the Spring Boot jar (tests skipped; run in CI) ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
# Cache dependencies first — only re-downloads when pom.xml changes.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---- Runtime stage: slim JRE with just the jar ----
FROM eclipse-temurin:21-jre
WORKDIR /app
# Run as a non-root user.
RUN useradd -r -u 1001 khoga
COPY --from=build /app/target/*.jar app.jar
USER khoga
EXPOSE 8080
ENV JAVA_OPTS="" SPRING_PROFILES_ACTIVE=prod
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
