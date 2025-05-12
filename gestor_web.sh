#!/bin/bash

# Configuraciones generales
BASE_DIR="/home"
FTP_USER_PREFIX="usuario"
HTML_DIR="html_public"
DB_PREFIX="db_"
DOMAIN="172.17.42.125"
PORT=80

# URLs de los archivos a descargar desde el repositorio de GitHub
GITHUB_REPO_URL_HTML="https://raw.githubusercontent.com/BOOTEABLE/pagina-web/refs/heads/main/paginadefault.html"
GITHUB_REPO_URL_VIDEO="https://raw.githubusercontent.com/BOOTEABLE/pagina-web/refs/heads/main/robot.webm"

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
    # Descargar archivo HTML desde GitHub
    echo "Descargando archivo HTML desde GitHub..."
    sudo wget -O "$BASE_DIR/$NEW_USER/$HTML_DIR/index.html" "$GITHUB_REPO_URL_HTML"
    
    # Descargar archivo de video desde GitHub
    echo "Descargando archivo de video desde GitHub..."
    sudo wget -O "$BASE_DIR/$NEW_USER/$HTML_DIR/robot.webm" "$GITHUB_REPO_URL_VIDEO"

    # Asegurarse de que el propietario de los archivos sea el usuario correspondiente
    sudo chown "$NEW_USER:$NEW_USER" "$BASE_DIR/$NEW_USER/$HTML_DIR/index.html"
    sudo chown "$NEW_USER:$NEW_USER" "$BASE_DIR/$NEW_USER/$HTML_DIR/robot.webm"
    
    # Reemplazar {{USUARIO}} en el archivo HTML por el nombre real del usuario
    sudo sed -i "s/{{USUARIO}}/$NEW_USER/g" "$BASE_DIR/$NEW_USER/$HTML_DIR/index.html"

    # Crear base de datos y usuario en MySQL
    DB_NAME="${DB_PREFIX}${NEW_USER}"
    sudo mysql -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -e "CREATE USER '$NEW_USER'@'localhost' IDENTIFIED BY '$PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$NEW_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # Configuración para NGINX
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
    # Configuración para phpmyadmin
    location /phpmyadmin {
        root /usr/share/;
        index index.php index.html index.htm;

        location ~ ^/phpmyadmin/(.*\.php)$ { 
            try_files $uri =404;
            fastcgi_pass unix:/run/php/php8.1-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME /usr/share/phpmyadmin/$1;
            include fastcgi_params;
        }

        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }
}
EOF

    [ ! -e "/etc/nginx/sites-enabled/ftp_users" ] && sudo ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/ftp_users"

    sudo nginx -t && sudo systemctl reload nginx

    # Cambiar permisos y propietarios
    sudo chown -R $NEW_USER:www-data "$BASE_DIR/$NEW_USER/$HTML_DIR"
    sudo chmod -R 755 "$BASE_DIR/$NEW_USER/$HTML_DIR"
    sudo chmod 755 "$BASE_DIR/$NEW_USER"

    # Configuración de VSFTPD
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

    # Eliminar archivos de configuración personalizados de nginx si se usaron
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
