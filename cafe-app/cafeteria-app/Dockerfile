# ---- Build stage ----
FROM gradle:8.14.3-jdk17-alpine AS build
WORKDIR /app
COPY . .
# Compila el fat JAR (salta tests para rapidez)
RUN gradle clean bootJar -x test

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Usuario no-root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copia el jar generado (ajusta el nombre si cambia)
COPY --from=build /app/build/libs/*.jar /app/app.jar

EXPOSE 8080
# Opcional: tweaks para contenedores
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java","-jar","/app/app.jar"]
