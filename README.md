# Despliegue de una aplicación en Kubernetes

## Índice
1. [Introducción](#introducción)
2. [Descripción y Funcionalidad de la API](#descripción-y-funcionalidad-de-la-api)
3. [Arquitectura de la Aplicación](#arquitectura-de-la-aplicación)
4. [Prerrequisitos](#prerrequisitos)
5. [Instalaciones](#instalaciones)
   - [Instalación de Docker](#instalación-de-docker)
   - [Instalación de Kubernetes](#instalación-de-kubernetes)
6. [Creación y Despliegue](#creación-y-despliegue)
   - [Creación imagen de Spring Boot](#creación-imagen-spring-boot)
   - [Creación y configuración de MySQL](#creación-y-configuración-mysql)
   - [Despliegue de la Aplicación](#despliegue-de-la-aplicación)
7. [Verificación y Pruebas](#verificación-y-pruebas)
9. [Miembros del Equipo](#miembros-del-equipo)


---

## Introducción
En este documento, vamos a explicar cómo desplegar una API REST construida con Spring Boot en un clúster de Kubernetes. A lo largo de los pasos, cubriremos cómo empaquetar la aplicación, crear los recursos necesarios de Kubernetes (como Pods, Deployments y Services) y cómo exponer tu API para que sea accesible desde el exterior.

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
- **Frontend:** Integrable con React o Angular a través de APIs RESTful.

### Seguridad y Roles
- **JWT (JSON Web Tokens)** para autenticación.
- **Roles:**
  - `ADMIN`: Gestión completa.
  - `USER`: Acceso restringido a sus propios datos.

## Prerrequisitos
- Docker y Kubernetes instalados.
- Conocimiento de Pods, Deployments y Services.
- Aplicación Spring Boot lista para desplegar.
- Máquinas Virtuales con Ubuntu (mínimo dos).

## Instalaciones

### Instalación de Docker
- Para instalar Docker en nuestra máquina virtual basta con utilizar los siguientes comandos:
```bash
sudo apt update
sudo apt install -y docker.io
```
- Actualizamos los repositorios y paquetes con apt update y seguidamente instalamos docker con el apt install. Podemos ver si Docker ha sido instalado correctamente mirando su versión con el siguiente comando:
```bash
docker --version
```

### Instalación de Kubernetes
-Nuevamente actualizamos los paquetes y repositorios por si acaso y seguidamente realizamos estos comandos:
```bash
sudo apt install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt update
sudo apt install -y kubeadm kubelet kubectl
```
- El curl nos ayudará a obtener los paquetes necesarios para poder instalar tanto kubeadm, kubelet y kubectl; realizaremos este paso dentro de las máquinas virtuales a las que queramos añadir al pod.
- Nos aseguramos de que Docker y Kubernetes se mantienen encendidos en todo momento con el siguiente comando
```bash
sudo systemctl enable docker
sudo systemctl enable kubelet
```
- Ahora dentro del nodo maestro (la máquina virtual en la que queramos controlar el cluster) usamos este comando.
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
- Nos debería de devolver un token con el cual podremos añadir las otras máquinas al cluster.
- Este paso es opcional, pero si queremos utilizar kubectl sin necesidad de sudo hemos de ejecutar los siguientes comandos
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
- Ya solo necesitamos instalar una red de pods, usaremos Flannel.
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
## Creación y Despliegue

### Creación Imagen Spring Boot
- Para empezar debemos de empaquetar nuestra aplicación como un archivo .war, para esto podemos utilizar Intellij, ya que la aplicación contiene Gradle, el cual nos permite crear el archivo .war con facilidad. Ejecutamos la Task de Gradle para construir el war.

- Una vez obtenido el .war, lo introducimos en nuestro nodo maestro utilizando una aplicación como FileZilla.

- Ahora que tenemos el war en la máquina virtual, hemos de asegurarnos de que tenemos el archivo Dockerfile también, vendrá en este repositorio, lo podemos introducir en el nodo maestro utilizando FileZilla también. El Dockerfile se va así:

```bash
# Utiliza una imagen base de OpenJDK
FROM openjdk:11-jre-slim

# Copia el archivo WAR de la aplicación
COPY target/investigacion-marina.war /investigacion-marina.war

# Expón el puerto en el que la aplicación estará disponible
EXPOSE 8080

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-war", "/investigacion-marina.war"]

```

- Una vez tenemos el war y el Dockerfile, podemos construir la imagen de la aplicación con el siguiente comando

```bash
docker build -t investigacion-marina .

```
- Con esto deberíamos tener la imagen creada, podemos verificarlo usando el siguiente comando para ver todas las imágenes actuales.

```bash
docker images
```
### Creación y Configuración MySQL
- Usaremos el archivo docker-compose.yml, el cual contiene la información necesaria para levantar un contenedor de MySQL usando docker-compose up, esto lo realizaremos en otra de las máquinas del cluster para tenerlo desplegado fuera del nodo maestro.

```bash
version: '3.8'

services:
  mysql:
    image: mysql:5.7
    container_name: mysql-db
    environment:
      MYSQL_ROOT_PASSWORD:
      MYSQL_DATABASE: investigacion_marina_bd
      MYSQL_USER: root
      MYSQL_PASSWORD:
    ports:
      - "3306:3306"
    networks:
      - app-network
    volumes:
      - mysql-data:/var/lib/mysql
    restart: always

  springboot-app:
    image: investigacion_marina:latest
    container_name: investigacion_marina_app
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql-db:3306/investigacion_marina_bd
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: 
    ports:
      - "8080:8080"
    depends_on:
      - mysql
    networks:
      - app-network
    restart: always

networks:
  app-network:
    driver: bridge

volumes:
  mysql-data:
    driver: local

```

- Después tendremos que utilizar el archivo mysql-deployment.yaml, debe de estar en el mismo nodo con la imagen de MySQL, puedes introducirlo con FileZilla

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-db
  template:
    metadata:
      labels:
        app: mysql-db
    spec:
      containers:
      - name: mysql-db
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: 
        - name: MYSQL_DATABASE
          value: "investigacion_marina_bd"
        ports:
        - containerPort: 3306

```

- Una vez hecho podemos realizar el siguiente comando:

```bash
kubectl apply -f mysql-deployment.yaml
```
- Con este comando aplicaremos el deployment de MySQL y la aplicación.

### Despliegue de la Aplicación
- Con el archivo investigacion-marina-deployment.yaml que viene en el repositorio, introdúcelo en el nodo maestro con FileZilla, este deployment nos permitirá desplegar la aplicación adecuadamente.

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: investigacion_marina_app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: investigacion_marina_app
  template:
    metadata:
      labels:
        app: investigacion_marina_app
    spec:
      containers:
      - name: investigacion_marina
        image: investigacion_marina:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: jdbc:mysql://mysql-db:3306/investigacion_marina_bd
        - name: SPRING_DATASOURCE_USERNAME
          value: root
        - name: SPRING_DATASOURCE_PASSWORD
          value:

```

- Ahora podemos ejecutar el siguiente comando:

```bash
kubectl apply -f investigacion-marina-deployment.yaml
```

## Verificación y Pruebas

- Con esto hecho, podemos verificar el despliegue con kubectl get pods y kubectl get svc, si todo está correcto la aplicación debería estar correctamente desplegada en el cluster.
```bash
kubectl get pods
kubectl get svc
```

## Miembros del Equipo
- **Manuel Amaya Orozco**
- **Lautaro Enrique Kruck Ponce**
- **Rubén Ramos Iglesias**
