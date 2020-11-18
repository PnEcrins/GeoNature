#!/bin/bash

. config/settings.ini

if [ ! -d '/tmp/geonature/' ]
then
  mkdir /tmp/geonature
  chmod -R 775 /tmp/geonature
fi

if [ ! -d '/tmp/taxhub/' ]
then
  mkdir /tmp/taxhub
  chmod -R 775 /tmp/taxhub
fi

if [ ! -d '/tmp/usershub/' ]
then
  mkdir /tmp/usershub
  chmod -R 775 /tmp/usershub
fi

if [ ! -d '/var/log/geonature/' ]
then
  sudo mkdir /var/log/geonature
  sudo chown "$(id -u)" /var/log/geonature
  chmod -R 775 /var/log/geonature
fi

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [ -z $1 ]
        then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -n -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}


function schema_exists () {
    a=`export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$1';" |grep $1`
    echo $a
    if [ $a ]
        then
        echo "schema $1 exists"
        return 0
    else
        echo "schema  $1 not exists"
        return 1
    fi
}

if ! database_exists $db_name
then
    echo "GeoNature database doesn't exists..."
    echo "Install the database befire"
    exit
fi

if database_exists $db_name
then

    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp data/grant.sql /tmp/geonature/grant.sql
    sudo sed -i "s/MYPGUSER/$user_pg/g" /tmp/geonature/grant.sql
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "GRANT" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f /tmp/geonature/grant.sql &>> /var/log/geonature/install_db.log

    echo "Creating 'public' functions..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'public' functions" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/public.sql  &>> /var/log/geonature/install_db.log

    if ! schema_exists "ref_nomenclatures"
    then
        echo "Creating 'nomenclatures' schema..."
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "Creating 'nomenclatures' schema" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/nomenclatures.sql  &>> /var/log/geonature/install_db.log

        echo "Inserting 'nomenclatures' data..."
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "Inserting 'nomenclatures' data" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        cp data/core/data_nomenclatures.sql /tmp/geonature/data_nomenclatures.sql
        sudo sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" /tmp/geonature/data_nomenclatures.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/data_nomenclatures.sql  &>> /var/log/geonature/install_db.log
    fi


    if ! schema_exists "gn_meta"
    then
        echo "Creating 'meta' schema..."
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "CreatingInstall_ 'meta' schema" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> /var/log/geonature/install_db.log
    fi

    if ! schema_exists "gn_commons"
    then
        echo "Creating 'commons' schema..."
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "Creating 'commons' schema" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/commons.sql  &>> /var/log/geonature/install_db.log
    fi

    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DROP SCHEMA IF EXISTS gn_synthese CASCADE;"  &>> /var/log/geonature/install_db.log
    echo "Creating 'synthese' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'synthese' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    cp data/core/synthese.sql /tmp/geonature/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/geonature/synthese.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/synthese.sql  &>> /var/log/geonature/install_db.log


    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DROP SCHEMA IF EXISTS gn_exports CASCADE;"  &>> /var/log/geonature/install_db.log
    echo "Creating 'exports' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'exports' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/exports.sql  &>> /var/log/geonature/install_db.log


    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DROP SCHEMA IF EXISTS gn_monitoring CASCADE;"  &>> /var/log/geonature/install_db.log
    echo "Creating 'monitoring' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'monitoring' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/monitoring.sql  &>> /var/log/geonature/install_db.log


    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DROP SCHEMA IF EXISTS gn_profiles CASCADE;"  &>> /var/log/geonature/install_db.log
    echo "Creating 'pofiles' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'profiles' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/profiles.sql  &>> /var/log/geonature/install_db.log

    # Suppression des fichiers : on ne conserve que les fichiers compressés
    echo "Cleaning files..."
    sudo rm /tmp/geonature/*.sql
    sudo rm /tmp/usershub/*.sql
    sudo rm /tmp/taxhub/*.txt
    sudo rm /tmp/taxhub/*.sql
    sudo rm /tmp/taxhub/*.csv

fi
