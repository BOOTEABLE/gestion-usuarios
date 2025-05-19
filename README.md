# Gestión Automática de Usuarios FTP con Sitio Web y Base de Datos

Este script en Bash automatiza la creación y eliminación de usuarios FTP en un servidor Linux. Para cada usuario creado, se configura un entorno web personalizado, una base de datos MySQL, y ajustes en NGINX y VSFTPD para permitir acceso web y FTP.

---

## Características principales

- **Crear usuario FTP automáticamente:**
  - Nombre de usuario autogenerado con prefijo y numeración incremental.
  - Contraseña segura generada aleatoriamente.
  - Directorio personal creado con permisos adecuados.
  - Descarga automática de archivos HTML y video desde un repositorio GitHub.
  - Personalización del archivo HTML con el nombre del usuario.
  - Creación de base de datos y usuario MySQL con permisos completos.
  - Configuración dinámica de NGINX para servir el contenido web desde `/home/usuarioXX/html_public`.
  - Configuración de VSFTPD para acceso FTP seguro y chroot.

- **Eliminar usuario FTP:**
  - Elimina el usuario del sistema, su directorio, la base de datos MySQL y permisos asociados.
  - Limpieza de configuraciones personalizadas en NGINX.
  - Recarga los servicios afectados para aplicar cambios.

---

## Requisitos

- Sistema operativo Linux con `bash`.
- MySQL instalado y corriendo.
- NGINX instalado y configurado.
- VSFTPD instalado y configurado.
- `wget`, `openssl` y privilegios sudo para ejecutar comandos administrativos.

---

## Uso

Ejecuta el script y selecciona la opción deseada:

```bash
./gestor_web.sh o el nombre que colocaste
