#!/bin/bash

# Make nvm available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

OS_BITS="$(getconf LONG_BIT)"

# Test the server architecture
if [ !"$OS_BITS" == "64" ]; then
   echo "GeoNature must be installed on a 64-bits operating system ; your is $OS_BITS-bits" 1>&2
   exit 1
fi

# Check dependencies (binary used by local user)
# TODO: check binary used by root (logrotate, supervisorctl)
# TODO: move nvm and npm install before check
commands=("find" "sed" "pip3" "python3")
for cmd in "${commands[@]}"; do
  if ! command -v "${cmd}" > /dev/null 2>&1; then
	  echo "Missing dependency. Please install: ${cmd}"
	  exit 1
  fi
done
echo "All dependencies found for $(basename $BASH_SOURCE)."

# settings.ini file path. Default value overwriten by settings-path parameter
cd ../
SETTINGS='config/settings.ini'
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--settings-path)
    SETTINGS="$2"
    shift # Past argument
    shift # Past value
    ;;
    -d|--dev)
    MODE='dev'
    shift # Past argument
    shift # Past value
    ;;
    -h|--help)
    echo ""
    echo "Help for install_app.sh command script."
    echo ""
    echo ""
    echo "Option order matters. Give it in this exact order. All options are optional."
    echo ""
    echo "-s OR --settings-path to give the path of the settings file. "
    echo ""
    echo "-d OR --dev to additionnally install python dev requirements."
    echo ""
    exit
    shift # Past argument
    shift # Past value
    ;;
    *)    # Unknown option
    POSITIONAL+=("$1") # Save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # Restore positional parameters

# Import settings file
. ${SETTINGS}

BASE_DIR=$(readlink -e "${0%/*}")


if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
  chmod -R 775 var/log/
fi


if [ -f config/geonature_config.toml ]; then
  rm config/geonature_config.toml
fi

echo "Création du fichier de configuration ..."
cp config/geonature_config.toml.sample config/geonature_config.toml
echo "Préparation du fichier de configuration..."
echo $my_url
my_url="${my_url//\//\\/}"
echo $my_url
sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"/" config/geonature_config.toml
sed -i "s/URL_APPLICATION = .*$/URL_APPLICATION = '${my_url}geonature' /g" config/geonature_config.toml
sed -i "s/API_ENDPOINT = .*$/API_ENDPOINT = '${my_url}geonature\/api'/g" config/geonature_config.toml
sed -i "s/API_TAXHUB = .*$/API_TAXHUB = '${my_url}taxhub\/api'/g" config/geonature_config.toml
sed -i "s/DEFAULT_LANGUAGE = .*$/DEFAULT_LANGUAGE = '${default_language}'/g" config/geonature_config.toml
sed -i "s/LOCAL_SRID = .*$/LOCAL_SRID = '${srid_local}'/g" config/geonature_config.toml


cd backend


# Installation du virtual env
# Suppression du venv s'il existe
if [ -d 'venv/' ]
then
  echo "Suppression du virtual env existant..."
  sudo rm -rf venv
fi

pip3 install virtualenv

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  python3 -m virtualenv -p $python_path venv
else
  python3 -m virtualenv venv
fi


echo "Ajout de l'autocomplétion de la commande GeoNature au virtual env..."
readonly bin_venv_dir="${BASE_DIR}/backend/venv/bin"
readonly activate_file="${bin_venv_dir}/activate"
readonly assets_install_dir="${BASE_DIR}/install/assets"
readonly src_completion_file="${assets_install_dir}/geonature_bash_completion.sh"
readonly completion_file_name="geonature_completion"
readonly completion_code="\n# GeoNature command completion\nsource \"\${VIRTUAL_ENV}/bin/${completion_file_name}\""
if ! grep -q "${completion_code}" "${activate_file}" ; then
    cp "${src_completion_file}" "${bin_venv_dir}/${completion_file_name}"
    cp "${activate_file}" "${activate_file}.save-$(date +'%F')"
    echo -e "${completion_code}" >> "${activate_file}"
fi


echo "Activation du virtual env..."
source venv/bin/activate


echo "Installation des dépendances Python..."
pip install --upgrade pip
pip install -r requirements.txt
if [[ $MODE == "dev" ]]
then
  pip install -r requirements-dev.txt
fi

echo "Installation du backend geonature..."
pip install --editable "${BASE_DIR}"  # geonature ne support pas encore autre chose que editable

echo "Création de la configuration du frontend depuis 'config/geonature_config.toml'..."
geonature generate_frontend_config --conf-file ${BASE_DIR}/config/geonature_config.toml --build=false


echo "Création du fichier de log des erreurs GeoNature"
# Cela évite sa création par Supervisor avec des droits root
# Voir : https://github.com/Supervisor/supervisor/issues/123
touch "${BASE_DIR}/var/log/gn_errors.log"


# Store path to backend directory
DIR=$(readlink -e "${0%/*}")

echo "Création de la rotation des logs à l'aide de Logrotate"
sudo cp "${assets_install_dir}/log_rotate" "/etc/logrotate.d/geonature"
sudo -s sed -i "s%{{APP_PATH}}%${BASE_DIR}%" "/etc/logrotate.d/geonature"
sudo -s sed -i "s%{{USER}}%${USER:=$(/usr/bin/id -run)}%" "/etc/logrotate.d/geonature"
sudo -s sed -i "s%{{GROUP}}%${USER}%" "/etc/logrotate.d/geonature"
sudo logrotate -f "/etc/logrotate.conf"

echo "Configuration de l'application api backend dans Supervisor..."
sudo -s cp "${assets_install_dir}/geonature-service.conf" "/etc/supervisor/conf.d/"
sudo -s sed -i "s%{{APP_PATH}}%${DIR}%" "/etc/supervisor/conf.d/geonature-service.conf"
sudo -s sed -i "s%{{ROOT_DIR}}%${BASE_DIR}%" "/etc/supervisor/conf.d/geonature-service.conf"
sudo -s sed -i "s%{{USER}}%${USER}%" "/etc/supervisor/conf.d/geonature-service.conf"

echo "Lancement de l'application api backend..."
sudo -s supervisorctl reread
sudo -s supervisorctl reload


# Préparation du frontend

# Lien symbolique vers le dossier static du backend (pour le backoffice)
ln -sf "${BASE_DIR}/frontend/node_modules" "${BASE_DIR}/backend/static"

cd "${GEONATURE}/frontend"

# Creation du dossier des assets externes
mkdir -p "src/external_assets"


# Copy the custom components
echo "Création des fichiers de customisation du frontend..."
if [ ! -f src/custom/custom.scss ]; then
  cp -n src/custom/custom.scss.sample src/custom/custom.scss
fi
custom_component_dir="src/custom/components/"
for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
	if [[ ! -f "${file%.sample}" ]]; then
		cp "${file}" "${file%.sample}"
	fi
done

# Generate the tsconfig.json
geonature generate_frontend_tsconfig
# Generate the src/tsconfig.app.json
geonature generate_frontend_tsconfig_app
# Generate the modules routing file by templating
geonature generate_frontend_modules_route

# Retour à la racine de GeoNature
cd "${BASE_DIR}"

# Installation du module Occtax et OccHab
geonature install_gn_module "${BASE_DIR}/contrib/occtax" /occtax --build=false

if [ "$install_module_occhab" = true ];
  then
  echo "Installation du module OccHab en cours..."
  geonature install_gn_module "${BASE_DIR}/contrib/gn_module_occhab" /occhab --build=false
fi

if [ "$install_module_validation" = true ];
  then
    echo "Installation du module Validation en cours..."
    geonature install_gn_module "${BASE_DIR}/contrib/gn_module_validation" /validation --build=false
fi

echo "Désactiver le virtual env"
deactivate

# Frontend installation
echo "Installation de Node et Npm"
cd "${BASE_DIR}/frontend"
nvm install
nvm use

echo " ############"
echo "Installation des paquets Npm"
npm ci --only=prod


if [[ $MODE != "dev" ]]
then
  echo "Build du frontend..."
  cd "${BASE_DIR}/frontend"
  npm rebuild node-sass --force
  npm run build
fi
