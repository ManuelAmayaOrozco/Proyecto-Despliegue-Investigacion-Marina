# Despliegue de una aplicación en Kubernetes

## Índice
- [Despliegue de una aplicación en Kubernetes](#despliegue-de-una-aplicación-en-kubernetes)
  - [Índice](#índice)
  - [Introducción](#introducción)
  - [Descripción y Funcionalidad de la API](#descripción-y-funcionalidad-de-la-api)
    - [Funcionalidades principales:](#funcionalidades-principales)
    - [Endpoints](#endpoints)
      - [Usuarios](#usuarios)
      - [Peces](#peces)
      - [Investigaciones](#investigaciones)
  - [Arquitectura de la Aplicación](#arquitectura-de-la-aplicación)
    - [Arquitectura General](#arquitectura-general)
    - [Tecnologías Utilizadas](#tecnologías-utilizadas)
    - [Seguridad y Roles](#seguridad-y-roles)
  - [Prerrequisitos](#prerrequisitos)
  - [Instalaciones](#instalaciones)
    - [Instalación de Docker Desktop](#instalación-de-docker-desktop)
    - [Instalación de Kubernetes dentro de Docker Desktop](#instalación-de-kubernetes-dentro-de-docker-desktop)
  - [Creación y Despliegue](#creación-y-despliegue)
    - [Creación Imagen Spring Boot](#creación-imagen-spring-boot)
    - [Creación y Configuración MySQL](#creación-y-configuración-mysql)
    - [Despliegue de la Aplicación](#despliegue-de-la-aplicación)
  - [Verificación y Pruebas](#verificación-y-pruebas)
    - [Comprobar el estado de los Pods y los Servicios](#comprobar-el-estado-de-los-pods-y-los-servicios)
  - [Miembros del Equipo](#miembros-del-equipo)


---

## Introducción
En este documento, vamos a explicar cómo desplegar una API REST construida con Spring Boot en un clúster de Kubernetes en Docker Desktop. A lo largo de los pasos, cubriremos cómo empaquetar la aplicación, crear los recursos necesarios de Kubernetes (como Pods, Deployments y Services) y cómo exponer tu API para que sea accesible desde el exterior.

El objetivo es proporcionar una guía detallada para que puedas llevar tu aplicación Spring Boot a un entorno de producción, aprovechando la escalabilidad y la gestión de contenedores que ofrece Kubernetes.

## Descripción y Funcionalidad de la API

La API de **Investigación Marina** es un proyecto desarrollado en Spring Boot que permite gestionar información relacionada con biología marina. Los usuarios registrados pueden documentar especies de peces descubiertas y generar resúmenes sobre investigaciones realizadas. Este sistema es flexible y puede adaptarse a otros temas más allá de la biología marina.

### Funcionalidades principales:
- Registro y gestión de usuarios (con roles `USER` y `ADMIN`).
- Documentación de especies de peces, incluyendo datos como nombre común, nombre científico, dieta y estado de peligro de extinción.
- Creación y gestión de investigaciones que documentan peces vistos en un lugar y tiempo específicos.

### Endpoints

#### Usuarios
```
GET /usuarios/{idUser}      - Obtener información de un usuario específico (protección por roles).
GET /usuarios/              - Listar todos los usuarios registrados (solo rol ADMIN).
POST /usuarios/login        - Iniciar sesión y obtener un token de autenticación.
POST /usuarios/register     - Registrar un nuevo usuario.
PUT /usuarios/{idUser}      - Actualizar información de un usuario (solo rol ADMIN).
DELETE /usuarios/{idUser}   - Eliminar un usuario (solo rol ADMIN).
```
#### Peces
```
GET /peces/{idPez}      - Obtener información de un pez específico (requiere autenticación).
GET /peces/             - Listar todos los peces registrados (requiere autenticación).
POST /peces/            - Registrar un nuevo pez (solo rol ADMIN).
PUT /peces/{idPez}      - Actualizar información de un pez (solo rol ADMIN).
DELETE /peces/{idPez}   - Eliminar un pez (solo rol ADMIN).
```
#### Investigaciones
```
GET /investigaciones/{idInvestigacion} - Obtener información de una investigación específica (protección por roles).
GET /investigaciones/                  - Listar todas las investigaciones (solo rol ADMIN).
POST /investigaciones/                  - Registrar una nueva investigación (requiere autenticación).
PUT /investigaciones/{idInvestigacion}  - Actualizar información de una investigación (protección por roles).
```

## Arquitectura de la Aplicación

### Arquitectura General
La aplicación sigue una arquitectura de tres capas:
- **Capa de Presentación (Frontend):** Maneja la interacción con el usuario.
- **Capa de Negocio (Backend):** Contiene la lógica de negocio y maneja autenticación y validaciones.
- **Capa de Datos (Base de Datos):** Almacena y gestiona la información de usuarios, peces e investigaciones.

### Tecnologías Utilizadas
- **Backend:** Java con Spring Boot, seguridad mediante Spring Security y tokens JWT.
- **Base de Datos:** MySQL.
- **Despligue:** Docker Desktop

### Seguridad y Roles
- **JWT (JSON Web Tokens)** para autenticación.
- **Roles:**
  - `ADMIN`: Gestión completa.
  - `USER`: Acceso restringido a sus propios datos.

## Prerrequisitos
- **Docker Desktop** instalado, con Kubernetes habilitado dentro de Docker Desktop.
- Conocimientos básicos sobre **Pods**, **Deployments** y **Services** en Kubernetes.
- Aplicación **Spring Boot** lista para ser desplegada, empaquetada como archivo `.jar`.

## Instalaciones

### Instalación de Docker Desktop

### Instalación de Kubernetes dentro de Docker Desktop
- Docker Desktop incluye soporte nativo para Kubernetes. 
- Para habilitar Kubernetes, abre Docker Desktop y ve a Settings > Kubernetes y marca la opción Enable Kubernetes. 
- Esto instalará y configurará un clúster de Kubernetes dentro de Docker.

- Verifica que Kubernetes esté funcionando correctamente ejecutando:
```bash
kubectl version --client  # Muestra la versión del cliente de kubectl
```

## Creación y Despliegue

### Creación Imagen Spring Boot
- Para empaquetar nuestra aplicación Spring Boot como un archivo .jar, puedes usar Gradle. En Intellij, abre la terminal en tu proyecto y ejecuta el siguiente comando:

```bash
./gradlew bootJar
```
- Esto generará el archivo .jar en la carpeta build/libs.
- Verifica que el archivo .jar se haya generado correctamente y, a continuación, colócalo en la carpeta de tu aplicación.
- Asegúrate de que el archivo Dockerfile esté presente en tu repositorio. El contenido del Dockerfile es el siguiente:

```bash
# Usa una imagen base de OpenJDK
FROM openjdk:17-jdk-slim

# Copia el archivo JAR al contenedor
COPY investigacion-marina.jar /app/investigacion-marina.jar

# Exponer el puerto que tu aplicación usará
EXPOSE 8080

# Comando para ejecutar el JAR
ENTRYPOINT ["java", "-jar", "/app/investigacion-marina.jar"]

```

- Con el archivo .jar y el Dockerfile listos, construye la imagen Docker de la aplicación con el siguiente comando:

```bash
docker build -t investigacion-marina .

```
- Con esto la imagen está creada, verifica que la imagen se haya creado correctamente ejecutando:

```bash
docker images
```

### Creación y Configuración MySQL
- Usaremos el archivo mysql-deployment.yaml para configurar el despliegue de MySQL en Kubernetes. Este archivo contiene toda la configuración necesaria para crear el contenedor de MySQL y montar un volumen persistente.
  
- El contenido de mysql-deployment.yaml es el siguiente:

```bash
# Persistent Volume Claim (PVC) para almacenar los datos de MySQL
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc  # Nombre del PVC
spec:
  accessModes:
    - ReadWriteOnce  # El PVC será accesible en modo lectura-escritura por un solo nodo
  resources:
    requests:
      storage: 1Gi  # Se solicita 1GB de almacenamiento

---
# Servicio de Kubernetes para acceder a MySQL
apiVersion: v1
kind: Service
metadata:
  name: mysql  # Nombre del servicio de MySQL
spec:
  ports:
    - port: 3306  # Puerto en el que MySQL está disponible
  selector:
    app: mysql  # Selecciona los pods con la etiqueta 'app: mysql'
  clusterIP: None  # Usamos None porque MySQL será un servicio sin IP estática en el clúster, se necesita acceso desde dentro del clúster

---
# Despliegue de MySQL en Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql  # Nombre del deployment
spec:
  replicas: 1  # Solo se ejecutará una réplica del contenedor MySQL
  selector:
    matchLabels:
      app: mysql  # Coincide con los pods etiquetados con 'app: mysql'
  template:
    metadata:
      labels:
        app: mysql  # Etiqueta del pod para asociarlo con el servicio y el deployment
    spec:
      containers:
        - name: mysql  # Nombre del contenedor
          image: mysql:8  # Imagen de Docker de MySQL versión 8
          env:
            - name: MYSQL_ROOT_PASSWORD  # Variable de entorno para la contraseña del usuario root de MySQL
              value: root  # Contraseña 'root' (deberías cambiarla en un entorno de producción)
            - name: MYSQL_DATABASE  # Variable de entorno para crear la base de datos por defecto
              value: investigacion_marina_bd  # Nombre de la base de datos a crear
          ports:
            - containerPort: 3306  # Puerto en el contenedor donde MySQL estará escuchando
          volumeMounts:
            - name: mysql-storage  # Nombre del volumen que montaremos en el contenedor
              mountPath: /var/lib/mysql  # Ruta dentro del contenedor donde se almacenarán los datos de MySQL
      volumes:
        - name: mysql-storage  # Definimos el volumen
          persistentVolumeClaim:
            claimName: mysql-pvc  # El PVC que debe usarse para este volumen


```

- Aplica el archivo de despliegue con el siguiente comando:

```bash
kubectl apply -f mysql-deployment.yaml
```
- Con este comando aplicaremos el deployment de MySQL y la aplicación.

### Despliegue de la Aplicación
- Para desplegar la aplicación Spring Boot, debes usar el archivo api-deployment.yaml, el cual está incluido en este repositorio. Este archivo contiene la configuración necesaria para el despliegue de la API en Kubernetes.
  
- El contenido de api-deployment.yaml es el siguiente:

```bash
# Despliegue de la API de investigación marina en Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-investigacion-marina  # Nombre del deployment
spec:
  replicas: 1  # Número de réplicas del pod (en este caso solo una)
  selector:
    matchLabels:
      app: api-investigacion-marina  # Selecciona los pods que tengan esta etiqueta
  template:
    metadata:
      labels:
        app: api-investigacion-marina  # Etiqueta para los pods creados por este deployment
    spec:
      containers:
        - name: api-investigacion-marina  # Nombre del contenedor
          image: investigacion-marina:latest  # Imagen Docker a usar (tu API)
          imagePullPolicy: Never  # No intentará descargar la imagen, ya que se asume que ya está presente en el nodo
          ports:
            - containerPort: 8080  # Puerto en el contenedor donde la API escuchará (normalmente 8080 para aplicaciones Spring Boot)
          env:
            # Variables de entorno para configurar la base de datos de la API
            - name: SPRING_DATASOURCE_URL
              value: jdbc:mysql://mysql:3306/investigacion_marina_bd  # URL de conexión a la base de datos MySQL
            - name: SPRING_DATASOURCE_USERNAME
              value: root  # Nombre de usuario para la base de datos
            - name: SPRING_DATASOURCE_PASSWORD
              value: root  # Contraseña para la base de datos

---
# Servicio de Kubernetes para exponer la API
apiVersion: v1
kind: Service
metadata:
  name: api-investigacion-marina  # Nombre del servicio
spec:
  selector:
    app: api-investigacion-marina  # Este servicio se conecta a los pods con la etiqueta 'app: api-investigacion-marina'
  ports:
    - protocol: TCP  # El protocolo utilizado será TCP
      port: 8080  # Puerto en el servicio para acceder a la API
      targetPort: 8080  # Puerto en el contenedor donde la API está escuchando
      nodePort: 31295  # Puerto expuesto en el nodo (se usa para acceder desde fuera del clúster)
  type: NodePort  # El servicio se configura como NodePort, lo que permite el acceso desde fuera del clúster



```

- Aplica el archivo de despliegue con el siguiente comando:

```bash
kubectl apply -f investigacion-marina-deployment.yaml
```

## Verificación y Pruebas

Una vez que hayas desplegado la aplicación y la base de datos en Kubernetes, es importante verificar que todo está funcionando correctamente y que puedes acceder a los endpoints de la API.

### Comprobar el estado de los Pods y los Servicios

1. **Verifica que los Pods estén funcionando correctamente**. Ejecuta el siguiente comando:
```bash
kubectl get pods  # Muestra el estado de todos los pods en el clúster
```

2. **Verifica que los Servicios estén correctamente configurados**. Ejecuta:
```bash
kubectl get pods  # Muestra el estado de todos los pods en el clúster
```
 - Deberías ver algo como esto:
```bash
NAME                        TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
api-investigacion-marina     NodePort   10.110.1.100     <none>        8080:31295/TCP   5m
mysql                        ClusterIP  10.110.1.101     <none>        3306/TCP         5m
```

3. **Obtener la IP de acceso**: En el resultado del comando anterior, busca la columna PORT(S) para tu servicio api-investigacion-marina. El formato será algo como 8080:31295/TCP. Aquí, el puerto 31295 es el puerto en el nodo que se ha expuesto, y puedes acceder a la aplicación a través de este puerto.

4. **Acceder al servicio**: Utilizando la IP de tu nodo y el puerto expuesto, abre tu navegador, Insomnia o Postman y prueba acceder a la API.
   - Si estás usando Docker Desktop con Kubernetes habilitado, puedes acceder a través de localhost o la IP de tu máquina, seguida del puerto 31295. Por ejemplo:
```bash
http://localhost:31295/
```

5. **Probar los Endpoints**: Si la aplicación está correctamente desplegada, deberías poder acceder a los endpoints de la API. Puedes probar las solicitudes con herramientas como Postman o Insomnia.

  - **Ejemplo:**
    - Para realizar un registro de la API, realiza una solicitud POST a:
```bash
 http://localhost:31295/usuarios/register 
```

## Miembros del Equipo
- **Manuel Amaya Orozco**
- **Lautaro Enrique Kruck Ponce**
- **Rubén Ramos Iglesias**
