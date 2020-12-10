#!/bin/bash
parentdir="$(dirname "$(pwd)")"
currentdir=${PWD##*/}
myrootpath=`pwd`/..

echo 'You are executing this script FROM '`pwd`' AND your oldgeonature directory is in '$parentdir'/geonature_old'
read -p "Press any key to exit. Press Y or y to continue."  choice
echo
if [ $choice ]
then
  if [ $choice != 'y' ] && [ $choice != 'Y' ] && [ $choice ]
  then
    echo "Exit"
    exit
  fi
else
  echo "Exit"
  exit
fi

echo "OK, let's migrate GeoNature version..."

. $myrootpath/geonature_old/config/settings.ini

cp $myrootpath/geonature_old/config/settings.ini config/settings.ini
cp $myrootpath/geonature_old/config/geonature_config.toml config/geonature_config.toml
cp -r $myrootpath/geonature_old/frontend/src/custom/* frontend/src/custom/

if [ -d "${myrootpath}/geonature_old/backend/static/images" ]
then
  cp -r $myrootpath/geonature_old/backend/static/images/* backend/static/images
fi

if [ -f "${myrootpath}/geonature_old/backend/static/css/custom.css" ]
then
  cp $myrootpath/geonature_old/backend/static/css/custom.css backend/static/css/custom.css
fi

if [ -d "${myrootpath}/geonature_old/backend/static/mobile" ]
then
  cp -r $myrootpath/geonature_old/backend/static/mobile/* backend/static/mobile
fi
if [ -d "${myrootpath}/geonature_old/backend/static/exports" ]
then
  cp -r $myrootpath/geonature_old/backend/static/exports/* backend/static/exports
fi
cp $myrootpath/geonature_old/frontend/src/favicon.ico frontend/src/favicon.ico
cp -r $myrootpath/geonature_old/external_modules/* external_modules
# On supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax et validation
rm -r external_modules/occtax
rm -r external_modules/validation
rm -r external_modules/occhab
# Rapatrier le fichier de conf de Occtax et de validation
cp $myrootpath/geonature_old/contrib/occtax/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/occtax/config/conf_gn_module.toml
cp $myrootpath/geonature_old/contrib/gn_module_validation/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/gn_module_validation/config/conf_gn_module.toml
cp $myrootpath/geonature_old/contrib/gn_module_occhab/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/gn_module_occhab/config/conf_gn_module.toml

# On recrée le lien symbolique sur le nouveau répertoire de GeoNature
ln -s $myrootpath/$currentdir/contrib/occtax external_modules/occtax
ln -s $myrootpath/$currentdir/contrib/gn_module_validation external_modules/validation
ln -s $myrootpath/$currentdir/contrib/gn_module_occhab external_modules/occhab

cp -r $myrootpath/geonature_old/frontend/src/external_assets/* $myrootpath/$currentdir/frontend/src/external_assets/

# # On recrée le lien symbolique sur le nouveau répertoire geonature
# ln -s $myrootpath/$currentdir/contrib/occtax/frontend/assets $myrootpath/$currentdir/frontend/src/external_assets/occtax

mkdir $myrootpath/$currentdir/var
mkdir $myrootpath/$currentdir/var/log
cp $myrootpath/geonature_old/var/log/gn_errors.log $myrootpath/$currentdir/var/log/


# Création du répertoitre static et rapatriement des médias
if [ ! -d 'backend/static/' ]
then
  mkdir backend/static
fi

if [ ! -d 'backend/static/medias/' ]
then
  mkdir backend/static/medias
fi

if [ -d "${myrootpath}/geonature_old/backend/static/medias" ]
then
  cp -r $myrootpath/geonature_old/backend/static/medias/* backend/static/medias
fi

if [ ! -d 'backend/static/shapefiles/' ]
then
  mkdir backend/static/shapefiles
fi

cd $myrootpath/$currentdir/frontend

export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install
nvm use
npm ci --only=prod

# Lien symbolique vers le dossier static du backend (pour le backoffice)
ln -s $myrootpath/$currentdir/frontend/node_modules $myrootpath/$currentdir/backend/static

cd $myrootpath/$currentdir/backend

if [ -d 'venv/' ]
then
  sudo rm -rf venv
fi

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  python3 -m virtualenv -p $python_path venv
else
  python3 -m virtualenv venv
fi

source venv/bin/activate
pip install -r requirements.txt
# Installation des dépendances des modules
# Boucle sur les liens symboliques de external_modules
for D in $(find ../external_modules  -type l | xargs readlink) ; do
    # si le lien symbolique exisite
    if [ -e "$D" ] ; then
        cd ${D}
        cd backend   
        if [ -f 'requirements.txt' ]
        then
            pip install -r requirements.txt
        fi
    fi
done

cd $myrootpath/$currentdir/
pip install --editable .

echo "Update configurations"
geonature update_configuration --build=false
geonature generate_frontend_modules_route
geonature generate_frontend_tsconfig_app
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax --build=false
geonature update_module_configuration validation --build=false
geonature update_module_configuration occhab --build=false

geonature frontend_build

sudo supervisorctl reload

deactivate
