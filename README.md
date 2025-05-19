# 🎉 Gestión Automática de Usuarios FTP con Sitio Web y Base de Datos 🚀

Este **script en Bash** automatiza la creación y eliminación de **usuarios FTP** en tu servidor Linux, junto con la configuración de su propio sitio web, base de datos MySQL y ajustes de NGINX y VSFTPD para acceso seguro y personalizado.

---

## ✨ Características principales

- 👤 **Creación automática de usuario FTP**
  - Usuario con prefijo y número secuencial (ej: `usuario01`)
  - 🔐 Contraseña segura generada aleatoriamente (base64, 12 caracteres)
  - 📂 Directorio personal con permisos configurados
  - 🌐 Descarga automática de archivos HTML y video desde GitHub
  - 📝 Personalización del archivo HTML con el nombre del usuario
  - 🛢️ Creación y configuración automática de base de datos MySQL
  - ⚙️ Configuración de NGINX para servir el contenido en `/home/usuarioXX/html_public`
  - 🔒 Configuración segura de VSFTPD para acceso FTP con chroot

- ❌ **Eliminación completa de usuario FTP**
  - Eliminación del usuario del sistema y su directorio
  - Eliminación de base de datos y permisos MySQL
  - Limpieza de configuraciones personalizadas en NGINX
  - Reinicio de servicios para aplicar cambios

---

## 🛠️ Requisitos

- Sistema operativo **Linux** con `bash`
- Servidor **MySQL** funcionando
- Servidor **NGINX** instalado y configurado
- Servidor **VSFTPD** instalado y configurado
- Comandos: `wget`, `openssl`, y permisos `sudo`

---

## 🚦 Uso

Ejecuta el script y selecciona la opción deseada:

```bash
./nombre_del_script.sh o ./gestor_web.sh
