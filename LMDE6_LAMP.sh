#!/bin/bash
# l'utilisation de l'argument --uninstall (-u) permet de désinstaller tous les composants
# l'utilisation de l'argument --purge-full (-p) permet de désinstaller tous les composants et supprimer les configurations résiduelles
# l'utilisation de l'argument --strict (-s) pour arrêter le script si une commande échoue
# Todo implémentation du mode --quiet (-q)


# gestion des arguments
UNINSTALL=false
PURGE_FULL=false
STRICT=false

for arg in "$@"; do
  case "$arg" in
    -u|--uninstall)   UNINSTALL=true   ;;
    -p|--purge-full)  PURGE_FULL=true  ;;
    -s|--strict)      STRICT=true      ;;
    -q|--quiet)       QUIET=true       ;;
  esac
done


# Mode strict
if $STRICT; then 
  echo "MODE STRICT ACTIVÉ"
  set -e
fi

# --purge-full : nettoyage complet, puis exit
if $PURGE_FULL; then
  echo " ! ! !  MODE PURGE TOTALE ACTIVÉ ! ! ! "
  read -p "Écrasez-vous TOUT (config, données, logs) ? (y/N) : " CONF
  [[ ! "$CONF" =~ ^[Yy]$ ]] && { echo "Annulé."; exit 1; }

  echo "Purge des paquets LAMP et outils dev"
  sudo apt purge --autoremove -y \
    apache2 apache2-bin apache2-utils apache2-data \
    mariadb-server mariadb-client \
    php* libapache2-mod-php \
    unzip git curl make gcc

  echo "Nettoyage manuel de toutes les configs et données résiduelles"
  sudo rm -rf \
    /etc/php /var/lib/php /var/log/php* \
    /etc/mysql /var/lib/mysql /var/log/mysql \
    /etc/apache2 /var/lib/apache2 /var/log/apache2 \
    /var/www/html \
    /usr/local/bin/composer /usr/local/bin/symfony ~/.symfony*

  echo "Suppression des dépôts et clés VSCode/VSCodium/DBeaver"
  sudo rm -f /usr/share/keyrings/{vscode.gpg,packages.microsoft.gpg,dbeaver.gpg,vscodium-archive-keyring.gpg}
  sudo rm -f /etc/apt/sources.list.d/{vscode.list,vscodium.list,dbeaver.list}

  echo "Purge complète terminée."
  exit 0
fi

# --uninstall : désinstallation simple, puis exit
if $UNINSTALL; then
  echo "MODE DÉSINSTALLATION ACTIVÉ"

  echo "Purge des paquets LAMP et outils dev"
  sudo apt purge --autoremove -y \
    apache2 apache2-bin apache2-utils apache2-data \
    mariadb-server mariadb-client \
    php* libapache2-mod-php \
    unzip git curl make gcc

  echo "Nettoyage manuel des configs PHP/Apache résiduelles"
  sudo rm -rf /etc/php/*/mods-available /etc/php/* /etc/apache2 /var/lib/apache2

  echo "Suppression de Composer et Symfony CLI"
  sudo rm -f /usr/local/bin/composer /usr/local/bin/symfony
  rm -rf ~/.symfony*

  echo "Nettoyage des données MariaDB"
  sudo rm -rf /var/lib/mysql /etc/mysql /var/log/mysql

  echo "Nettoyage du webroot et des logs Apache"
  sudo rm -rf /var/www/html /var/log/apache2

  echo "Suppression conditionnelle de VSCode, VSCodium et DBeaver"
  for pkg in code codium dbeaver-ce; do
    if dpkg -l | grep -q "^ii\s\+$pkg\s"; then
      echo "  → Suppression $pkg"
      sudo apt purge --autoremove -y "$pkg"
    else
      echo "  • $pkg non installé"
    fi
  done

  echo "Suppression des clés & dépôts"
  sudo rm -f /usr/share/keyrings/{vscode.gpg,packages.microsoft.gpg,dbeaver.gpg,vscodium-archive-keyring.gpg}
  sudo rm -f /etc/apt/sources.list.d/{vscode.list,vscodium.list,dbeaver.list}

  echo "Nettoyage final APT"
  sudo apt autoremove --purge -y
  sudo apt clean

  echo "Désinstallation terminée."
  exit 0
fi



echo "MODE INSTALLATION"

echo "PURGE COMPLÈTE DE PHP, MARIADB, MYSQL ET APACHE2"
sudo apt purge --autoremove -y 'php*' 'libphp*' 'mysql*' 'mariadb*' 'libmysql*' 'libmariadb*' apache2 apache2-bin apache2-utils apache2-data

echo "NETTOYAGE DES FICHIERS DE CONFIGURATION RÉSIDUELS"
sudo apt autoremove --purge -y
sudo apt clean

echo "SUPPRESSION DES DONNÉES ET DES LOGS MARIADB/MYSQL"
sudo rm -rf /var/lib/mysql /etc/mysql /var/log/mysql

echo "MISE À JOUR DES DÉPÔTS"
sudo apt update

echo "INSTALLATION DE LA PILE LAMP (Apache, MariaDB, PHP)"
sudo apt install -y \
  apache2 \
  mariadb-server \
  mariadb-client \
  php-cli \
  php-curl \
  php-dev \
  php-gd \
  php-gmp \
  php-imagick \
  php-imap \
  php-intl \
  php-json \
  php-mbstring \
  php-mysql \
  php-pdo \
  php-soap \
  php-sqlite3 \
  php-xml \
  php-xmlrpc \
  php-zip \
  libapache2-mod-php

echo "INSTALLATION DES OUTILS DE DÉVELOPPEMENT"
sudo apt install -y unzip git curl make gcc wget gpg

echo "INSTALLATION DE COMPOSER"
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "
\$expected = '$EXPECTED_SIGNATURE';
\$actual = hash_file('sha384', 'composer-setup.php');
if (\$actual === \$expected) {
    echo 'Installer verified'.PHP_EOL;
} else {
    echo 'Installer corrupt'.PHP_EOL;
    unlink('composer-setup.php');
    exit(1);
}
"

php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

echo "REDÉMARRAGE ET ACTIVATION DES SERVICES"
sudo systemctl restart apache2 mariadb
sudo systemctl enable apache2 mariadb

echo
echo "CONFIGURATION SÉCURISÉE DE MARIADB"

MAX_ATTEMPTS=3
ATTEMPT=1

while true; do
  read -s -p "Mot de passe root MariaDB : " MYSQL_ROOT_PASSWORD
  echo
  read -s -p "Confirmer le mot de passe : " MYSQL_ROOT_PASSWORD_CONFIRM
  echo

  if [[ "$MYSQL_ROOT_PASSWORD" == "$MYSQL_ROOT_PASSWORD_CONFIRM" ]]; then
    break
  else
    echo "❌ Les mots de passe ne correspondent pas."
    ((ATTEMPT++))
    if [[ $ATTEMPT -gt $MAX_ATTEMPTS ]]; then
      echo "Trop de tentatives échouées. Abandon."
      exit 1
    fi
  fi
done

sudo mariadb <<EOF
-- Supprimer tous les comptes anonymes
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';

-- Interdire le login root à distance
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Supprimer la base de test
DROP DATABASE IF EXISTS test;

-- Réinitialiser les privilèges
FLUSH PRIVILEGES;
EOF



echo
read -p "Souhaitez-vous créer un utilisateur MariaDB non-root pour un projet Symfony ? (y/n) : " CREATE_USER_CHOICE
if [[ "$CREATE_USER_CHOICE" =~ ^[Yy]$ ]]; then
  echo
  echo "Création d'un utilisateur MariaDB non-root pour Symfony"

  # Récupération des paramètres
  read -p "Nom de l'utilisateur MariaDB à créer : " MYSQL_USER
  read -s -p "Mot de passe de l'utilisateur : " MYSQL_USER_PASSWORD
  echo
  read -p "Nom de la base de données à créer : " MYSQL_DATABASE
  echo

  # Exécution des commandes SQL en une seule passe
  sudo mariadb <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

  echo
  echo "Utilisateur MariaDB '${MYSQL_USER}' créé avec accès complet à la base '${MYSQL_DATABASE}'."
  echo
else
  echo "Création d'utilisateur MariaDB non-root ignorée."
  echo
fi


echo "INSTALLATION DE LA SYMFONY CLI"
curl -sS https://get.symfony.com/cli/installer | bash
sudo mv ~/.symfony*/bin/symfony /usr/local/bin/symfony

echo "SUPPRESSION CONDITIONNELLE DE VSCODE, VSCODIUM ET DBEAVER"

# Liste des paquets à tester et désinstaller
PACKAGES=("code" "codium" "dbeaver-ce")

for pkg in "${PACKAGES[@]}"; do
  if dpkg -l | grep -q "^ii\s\+$pkg\s"; then
    echo "Suppression du paquet : $pkg"
    sudo apt purge --autoremove -y "$pkg"
  else
    echo "Paquet non installé : $pkg"
  fi
done

# Suppression des fichiers de configuration s'ils existent
sudo rm -f /usr/share/keyrings/vscode.gpg
sudo rm -f /usr/share/keyrings/packages.microsoft.gpg
sudo rm -f /usr/share/keyrings/dbeaver.gpg
sudo rm -f /usr/share/keyrings/vscodium-archive-keyring.gpg

sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /etc/apt/sources.list.d/vscodium.list
sudo rm -f /etc/apt/sources.list.d/dbeaver.list

echo "CONFIGURATION ET INSTALLATION DE DBEAVER CE"
# Ajout du dépôt DBeaver
sudo  wget -O /usr/share/keyrings/dbeaver.gpg.key https://dbeaver.io/debs/dbeaver.gpg.key
echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg.key] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list

# Installation de DBeaver CE
sudo apt update && sudo apt install dbeaver-ce -y

echo "CHOIX DE L'EDITEUR DE CODE"
echo "1) VS Code (Microsoft)"
echo "2) VSCodium (libre, sans télémétrie)"
echo "3) Je ne souhaites pas installer d'éditeur de code"
read -p "Quel éditeur voulez-vous installer ? (1, 2 ou 3) : " CHOICE

if [[ "$CHOICE" == "1" ]]; then

# Installation de VS Code et vérification de la présence de gpg
echo "CONFIGURATION ET INSTALLATION DE VS CODE"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg


sudo apt install apt-transport-https
sudo apt update && sudo apt install code -y

elif [[ "$CHOICE" == "2" ]]; then

#VSCodium
echo "CONFIGURATION ET INSTALLATION DE VSCODIUM"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list


sudo apt update && sudo apt install codium

  echo "AJOUT D'UN ALIAS 'code' → 'codium' DANS ~/.bashrc"
  if ! grep -Fxq "alias code='codium'" ~/.bashrc; then
    echo "alias code='codium'" >> ~/.bashrc
    echo "Redémarrez votre terminal ou exécutez 'source ~/.bashrc' pour activer l'alias."
  else
    echo "Alias déjà présent dans ~/.bashrc"
  fi

else
  echo "Aucun éditeur ne sera installé"
fi

# Codes couleurs pour la lisibilité (vert, rouge, reset)
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_RESET="\033[0m"

# Liste des commandes à tester
COMMANDS=(
	"curl"
	"wget"
	"gpg"
 	"git"
 	"php"
 	"mysql"
 	"code"
    "codium"
 	"composer"
 	"symfony"
 	"dbeaver-ce"
)

for cmd in "${COMMANDS[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "***** $cmd -> ${COLOR_GREEN}TRUE${COLOR_RESET} *****"
  else
    echo -e "***** $cmd -> ${COLOR_RED}FALSE${COLOR_RESET} *****"
  fi
done

echo "PHP : $(php -v | head -n1)"
echo "MariaDB : $(mysql --version)"
echo "Composer : $(composer --version)"
echo "Symfony CLI : $(symfony version)"

echo -e "${COLOR_GREEN}✅ Tous les composants sont installés et prêts à l'emploi.${COLOR_RESET}"

echo "INSTALLATION TERMINÉE"
