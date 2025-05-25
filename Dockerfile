# 🏗️ Stage 1: Build the application
FROM maven:3.8.5-openjdk-17 AS build

WORKDIR /app

# Copy only necessary files to improve caching
COPY pom.xml .
COPY src ./src

# Ensure Maven wrapper is executable

# Package the application (skip tests for faster build)
RUN mvn clean package -DskipTests

# 🚀 Stage 2: Run the application
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy the built JAR file from the previous stage
COPY --from=build /app/target/MatchUp-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 9095

# Start the application
CMD ["java", "-jar", "app.jar"]
