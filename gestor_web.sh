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

    echo "Usuario creado: $NEW_USER"
    echo "Contraseña: $PASSWORD"
    echo "Base de datos creada: $DB_NAME"
    echo "Accede en: http://$DOMAIN/~$NEW_USER/"
}

eliminar_usuario() {
    echo "Ingresa el nombre del usuario a eliminar (ejemplo: usuario01):"
    read USUARIO_ELIMINAR

    sudo mysql -e "DROP DATABASE db_$USUARIO_ELIMINAR;"
    sudo mysql -e "DROP USER '$USUARIO_ELIMINAR'@'localhost';"

    sudo rm -rf "$BASE_DIR/$USUARIO_ELIMINAR"

    # Si usaras configuración individual por usuario:
    sudo rm -f "/etc/nginx/sites-available/$USUARIO_ELIMINAR"
    sudo rm -f "/etc/nginx/sites-enabled/$USUARIO_ELIMINAR"

    sudo systemctl reload nginx

    echo "Usuario $USUARIO_ELIMINAR eliminado correctamente."
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

