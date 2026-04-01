# stage 1: Prepare FE
FROM node:20-alpine AS frontend
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend ./
RUN npm run build

# stage 2: Prepare BE
FROM gradle:9.2.1-jdk21 AS backend

WORKDIR /app
COPY build.gradle.kts settings.gradle.kts versions.properties gradlew gradlew.bat ./
COPY gradle ./gradle/
RUN ./gradlew dependencies --no-daemon

COPY . .
COPY --from=frontend /app/dist/ src/main/resources/static
RUN ./gradlew build --no-daemon -x test

# stage 3: Prepare runtime
FROM eclipse-temurin:21-jre-alpine AS app
WORKDIR /app
RUN addgroup -S app_user && adduser -S app_user -G app_user
COPY --from=backend /app/build/libs/project-devops-deploy-0.0.1-SNAPSHOT.jar app.jar
USER app_user
EXPOSE 8080 9090
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
