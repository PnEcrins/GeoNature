#!/bin/bash


sudo sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$db_user:$db_pass@test.ecrins-parcnational.net:5432\/$db_name\"/" $TRAVIS_BUILD_DIR/backend/tests/travis_test/geonature_config_tests.toml

sudo cp $TRAVIS_BUILD_DIR/backend/tests/travis_test/geonature_config_tests.toml $TRAVIS_BUILD_DIR/config/geonature_config.toml

export PGPASSWORD=$db_pass;psql -U $db_user -h test.ecrins-parcnational.net -d $db_name -c "TRUNCATE gn_synthese.synthese CASCADE;"
export PGPASSWORD=$db_pass;psql -U $db_user -h test.ecrins-parcnational.net -d $db_name -c "DELETE FROM gn_commons.cor_module_dataset WHERE id_module in (select id_module from gn_commons.t_modules where module_code = 'OCCTAX' )"
export PGPASSWORD=$db_pass;psql -U $db_user -h test.ecrins-parcnational.net -d $db_name -c "DELETE FROM gn_commons.t_modules WHERE module_code = 'OCCTAX';"
export PGPASSWORD=$db_pass;psql -U $db_user -h test.ecrins-parcnational.net -d $db_name -c "INSERT into gn_commons.cor_module_dataset(id_module, id_dataset) SELECT gn_commons.get_id_module_bycode('OCCTAX'), t.id_dataset FROM gn_meta.t_datasets t WHERE t.active = true;"


python ../../setup.py install

geonature install_gn_module $TRAVIS_BUILD_DIR/contrib/occtax occtax --build=false

cd ../../../frontend

cp src/custom/custom.scss.sample src/custom/custom.scss
cp src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
cp src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
cp src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
cp src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html


geonature generate_frontend_tsconfig
geonature generate_frontend_modules_route
geonature update_configuration --build=false





