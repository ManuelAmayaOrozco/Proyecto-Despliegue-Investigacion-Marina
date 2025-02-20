# Usa una imagen base de OpenJDK
FROM openjdk:17-jdk-slim

# Copia el archivo JAR al contenedor
COPY investigacion-marina.jar /app/investigacion-marina.jar

# Exponer el puerto que tu aplicación usará
EXPOSE 8080

# Comando para ejecutar el JAR
ENTRYPOINT ["java", "-jar", "/app/investigacion-marina.jar"]
