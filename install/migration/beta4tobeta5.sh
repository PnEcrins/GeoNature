#/bin/bash

BASE_DIR=$(readlink -e "${0%/*}")

inter="$(dirname "$BASE_DIR")"
geonature_dir="$(dirname "$inter")"

mkdir $geonature_dir/var
mkdir $geonature_dir/var/log


cp /home/$USER/geonature_old/config/settings.ini /home/$USER/geonature/config/settings.ini
cp /home/$USER/geonature_old/frontend/src/conf/map.config.ts /home/$USER/geonature/frontend/src/conf/map.config.ts
cp -r /home/$USER/geonature_old/frontend/src/custom/* /home/$USER/geonature/frontend/src/custom/
cp -r /home/$USER/geonature_old/external_modules/* /home/$USER/geonature/external_modules
mkdir frontend/src/external_assets
cp -r /home/$USER/geonature_old/frontend/src/external_assets/* frontend/src/external_assets/

##### Migration SQL #######

. $geonature_dir/config/settings.ini

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $geonature_dir/data/migrations/2.0.0beta4to2.00beta5.sql  &>> var/log/migration2.0.0beta4_beta5.log

cp $geonature_dir/data/core/synthese.sql /tmp/synthese.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/synthese.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/synthese.sql  &>> var/log/migration2.0.0beta4_beta5.log

cp $geonature_dir/contrib/occtax/data/migration_2.0.0.beta4to2.0.0.beta5.sql /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql  &>> var/log/migration2.0.0beta4_beta5.log

# Suppression des fonctions obselètes qui étaient utilisés dans occtax
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DROP FUNCTION ref_nomenclatures.get_default_nomenclature_value(integer, integer);DROP FUNCTION ref_nomenclatures.get_id_nomenclature(integer, character varying);"

##### Migration arborescence #######

ln -s $geonature_dir/contrib/occtax $geonature_dir/external_modules/occtax

cp /etc/geonature/geonature_config.toml $geonature_dir/config/geonature_config.toml
cp /etc/geonature/mods-enabled/occtax/conf_gn_module.toml $geonature_dir/external_modules/occtax/config/conf_gn_module.toml


sudo cp -r /var/log/geonature $geonature_dir/var/log
sudo chown -R $USER $geonature_dir/var/log/*

cp $geonature_dir/backend/gunicorn_start.sh.sample $geonature_dir/backend/gunicorn_start.sh

rm /tmp/synthese.sql


## Regérération des dépendances et migration des fichiers de conf et dossiers gitignorés

# Création du répertoitre static et rapattriement des médias
if [ ! -d 'backend/static/' ]
then
  mkdir /home/$USER/geonature/backend/static
fi

if [ ! -d 'backend/static/medias/' ]
then
  mkdir /home/$USER/geonature/backend/static/medias
fi
cp -r /home/$USER/geonature_old/backend/static/medias/* mkdir /home/$USER/geonature/backend/static/medias

if [ ! -d 'backend/static/shapefiles/' ]
then
  mkdir /home/$USER/geonature/backend/static/shapefiles
fi


cd /home/$USER/geonature/frontend
npm install

cd /home/$USER/geonature/backend

if [ -d 'venv/' ]
then
  sudo rm -r venv
fi

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  virtualenv -p $python_path venv
else
  virtualenv venv
fi


source venv/bin/activate
pip install -r requirements.txt

pip install --editable .

echo "Update configurations "
geonature update_configuration --build=false
geonature generate_frontend_config --build=false
geonature generate_frontend_modules_route
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax --build=false


echo "Rebuild du frontend"
cd ../frontend
npm run build
cd ../

sudo supervisorctl reload

deactivate
