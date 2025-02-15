# Utiliza una imagen base de OpenJDK
FROM openjdk:11-jre-slim

# Copia el archivo WAR de la aplicación
COPY target/investigacion-marina.war /investigacion-marina.war

# Expón el puerto en el que la aplicación estará disponible
EXPOSE 8080

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-war", "/investigacion-marina.war"]
