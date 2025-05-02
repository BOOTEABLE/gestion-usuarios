#!/bin/bash

# Configuraciones generales
BASE_DIR="/home"
FTP_USER_PREFIX="usuario"
HTML_DIR="html_public"
DB_PREFIX="db_"
DOMAIN="172.17.42.125"
PORT=80

crear_usuario() {
    USER_COUNT=$(ls $BASE_DIR | grep -E "^$FTP_USER_PREFIX[0-9]{2}$" | wc -l)
    NEW_USER_NUM=$(printf "%02d" $((USER_COUNT + 1)))
    NEW_USER="$FTP_USER_PREFIX$NEW_USER_NUM"
    PASSWORD=$(openssl rand -base64 12)

    sudo useradd -m -d "$BASE_DIR/$NEW_USER" -s /bin/bash "$NEW_USER"
    echo "$NEW_USER:$PASSWORD" | sudo chpasswd

    sudo mkdir -p "$BASE_DIR/$NEW_USER/$HTML_DIR"
    sudo chown -R $NEW_USER:$NEW_USER "$BASE_DIR/$NEW_USER"
    sudo chmod 755 "$BASE_DIR/$NEW_USER"
    sudo chmod 755 "$BASE_DIR/$NEW_USER/$HTML_DIR"

    sudo tee "$BASE_DIR/$NEW_USER/$HTML_DIR/index.html" > /dev/null <<EOF
<html>
  <head><title>Bienvenido a $NEW_USER</title></head>
  <body>
    <h1>Hola desde $NEW_USER</h1>
  </body>
</html>
EOF
    sudo chown "$NEW_USER:$NEW_USER" "$BASE_DIR/$NEW_USER/$HTML_DIR/index.html"

    DB_NAME="${DB_PREFIX}${NEW_USER}"
    sudo mysql -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -e "CREATE USER '$NEW_USER'@'localhost' IDENTIFIED BY '$PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$NEW_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    NGINX_CONF="/etc/nginx/sites-available/ftp_users"
    sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location ~ ^/~(\w+)(/.*)?$ {
        alias /home/\$1/html_public\$2;
        index index.html index.htm;
        autoindex on;
    }
}
EOF

    [ ! -e "/etc/nginx/sites-enabled/ftp_users" ] && sudo ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/ftp_users"

    sudo nginx -t && sudo systemctl reload nginx

    sudo chown -R www-data:www-data "$BASE_DIR/$NEW_USER/$HTML_DIR"
    sudo chmod -R 755 "$BASE_DIR/$NEW_USER/$HTML_DIR"
    sudo chmod 755 "$BASE_DIR/$NEW_USER"

    sudo tee -a /etc/vsftpd.conf > /dev/null <<EOF
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
EOF

    sudo systemctl restart vsftpd

    echo -e "\n\033[1;32m✅ Usuario creado exitosamente:\033[0m"
    echo -e "\033[1;34m👤 Usuario:\033[0m $NEW_USER"
    echo -e "\033[1;34m🔑 Contraseña:\033[0m $PASSWORD"
    echo -e "\033[1;34m📊 Base de datos:\033[0m $DB_NAME"
    echo -e "\033[1;34m🌍 Sitio web:\033[0m http://$DOMAIN/~$NEW_USER/"
    echo -e "\033[1;32m-------------------------------------------\033[0m"    
}

eliminar_usuario() {
    echo "Ingresa el nombre del usuario a eliminar (ejemplo: usuario01):"
    read USUARIO_ELIMINAR
    # Eliminar base de datos y usuario de MySQL
    sudo mysql -e "DROP DATABASE db_$USUARIO_ELIMINAR;"
    sudo mysql -e "DROP USER '$USUARIO_ELIMINAR'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Eliminar el directorio del usuario
    sudo rm -rf "$BASE_DIR/$USUARIO_ELIMINAR"
    # Eliminar usuario del sistema
    sudo userdel "$USUARIO_ELIMINAR"
    # Eliminar el grupo si existe
    if getent group "$USUARIO_ELIMINAR" > /dev/null; then
        sudo groupdel "$USUARIO_ELIMINAR"
    fi
    
    # Eliminar archivos de configuración personalizados de nginx si se usaran
    sudo rm -f "/etc/nginx/sites-available/$USUARIO_ELIMINAR"
    sudo rm -f "/etc/nginx/sites-enabled/$USUARIO_ELIMINAR"
    # Reiniciar nginx
    sudo systemctl reload nginx
    echo -e "\n\033[1;31m❌ El usuario ha sido eliminado correctamente:\033[0m"
    echo -e "\033[1;34m👤 Usuario eliminado:\033[0m $USUARIO_ELIMINAR"
    echo -e "\033[1;32m-------------------------------------------\033[0m"    
}

# Menú principal
echo "Seleccione una opción:"
echo "1. Crear usuario"
echo "2. Eliminar usuario"
read OPCION

case $OPCION in
    1) crear_usuario ;;
    2) eliminar_usuario ;;
    *) echo "Opción no válida." ;;
esac

