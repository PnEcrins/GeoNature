IMPORT NIVEAU 1
===============

Dans cet exemple, nous allons importer un fichier CSV (ou SHP) d'observations dans la base de données de GeoNature, 
pour ensuite intégrer ces données dans la synthèse de GeoNature.

On utilisera le fichier d'exemple 
https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/import-basique/01-observations-faune-2008-2010.csv.

Importer la donnée source dans la BDD avec QGIS
-----------------------------------------------

PS : Si vous utilisez un CSV, vous pouvez aussi utiliser la fonction ``gn_imports.load_csv_file``.

**1.** Connecter la BDD dans QGIS :

* QGIS 
* PostGIS / Clic droit / New connection
* Nom / Hôte (IP) / Base de données (geonaturedb) / Authentification de base (utilisateur / mot de passe)
* Parcourir les tables géométriques

Si vous devez ouvrir les connexions externes à votre BDD, 
voir la documentation https://github.com/PnEcrins/GeoNature-atlas/blob/master/docs/installation.rst#acc%C3%A9der-%C3%A0-votre-bdd

**2.** Importer le fichier dans la BDD :

* Ouvrir SHP ou CSV dans QGIS
* Bases de données / Gestionnaire de base de données
* Sélectionner la BDD et son schéma
* Importer une couche/un fichier
* Choisir la couche à importer et définir le nom de table de destination

Créer les métadonnées
---------------------

**1.** Ajouter une source (si elle n'existe pas déjà)

En l'ajoutant manuellement dans la table ``gn_synthese.t_sources`` ou en SQL : 

.. code:: sql

  INSERT INTO gn_synthese.t_sources(name_source, desc_source)
  VALUES
  ('Historique', 'Données historiques intégrées manuellement dans la BDD')

**2.** Ajouter un jeu de données (si il n'existe pas déja)

Avec l'admin de GeoNature, dans la BDD avec pgAdmin ou en SQL. Et avant ça un CA si il n'en existe pas déjà un auquel associer le JDD.

.. code:: sql

  INSERT INTO gn_meta.t_datasets(id_acquisition_framework, dataset_name, dataset_shortname, dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain, active)
  VALUES
  (1, 'Données Faune 2008-2010', 'Faune 2008-2010', 'Données faune du PNE entre 2008 et 2010', 326, 'Faune, PNE', FALSE, TRUE, TRUE)

Pour retrouver les valeurs d'un type de nomenclature, vous pouvez utiliser les vues qui les rendent plus lisibles. 
Par exemple ici ``ref_nomenclatures.v_data_typ``.
Ou bien l'Admin des nomenclatures disponible dans GeoNature.

Il est aussi possible d'utiliser les codes des nomenclatures pour retrouver leurs id (ceci étant variables d'une instance à l'autre), 
en utilisant la fonction ``ref_nomencltaure.get_id_nomenclature``.

Insertion des données dans la Synthèse
--------------------------------------

.. code:: sql

  INSERT INTO gn_synthese.synthese(
  unique_id_sinp,
  id_source,
  id_dataset,
  id_nomenclature_obs_meth,
  count_min,
  count_max,
  cd_nom,
  nom_cite,
  altitude_min,
  altitude_max,
  the_geom_4326,
  the_geom_point,
  the_geom_local,
  date_min,
  date_max,
  observers,
  comments,
  last_action
  )
   SELECT
	uuid_generate_v4(),
	2 AS id_source,
	3 AS id_dataset,
	CASE
	  WHEN critere = 'Vu' THEN (41) -- Ou bien ref_nomencltaure.get_id_nomenclature
	  WHEN critere = 'Entendu' THEN (42)
	  ELSE (gn_synthese.get_default_nomenclature_value('METH_OBS'))
	END AS id_nomenclature_obs_meth,
	effectif::integer,
	effectif::integer,
	cd_nom::integer,
	taxon_latin,
	altitude::integer, -- On pourrait calculer les valeurs manquantes avec la fonction ref_geo.fct_get_altitude_intersection
	altitude::integer,
	ST_SetSRID(ST_MakePoint("x_WGS84"::numeric, "y_WGS84"::numeric),4326) AS the_geom_4326,
	ST_Centroid(ST_SetSRID(ST_MakePoint("x_WGS84"::numeric, "y_WGS84"::numeric),4326)) AS the_geom_point,
	ST_Transform(ST_SetSRID(ST_MakePoint("x_WGS84"::numeric, "y_WGS84"::numeric),4326),2154) AS the_geom_local,
	dateobs::date,
	dateobs::date,
	observateurs,
	remarques,
	'I' AS last_action
   FROM gn_imports.obs_faune_2008_2010
   ORDER BY dateobs
  ;

A creuser pour calculer les altitudes non renseignées : 

.. code:: sql

  SELECT b.toto->'altitude_min' 
  FROM(SELECT row_to_json(a.alts) AS toto 
  FROM (SELECT (ref_geo.fct_get_altitude_intersection(geom_local)) AS alts 
  FROM pr_occtax.t_releves_occtax) a) b

Gil propose de rajouter une PK et de faire un lien entre ta table et la synthese avec ``entity_source_pk_value`` :

.. code:: sql

  -- Clé primaire
  ALTER TABLE gn_imports.obs_faune_2008_2010
     ADD COLUMN gid serial;

  ALTER TABLE gn_imports.obs_faune_2008_2010
     ADD CONSTRAINT pk_obs_faune_2008_2010 PRIMARY KEY(gid);

Ajouter le champ ``entity_source_pk_value`` dans ton INSERT et ``gid`` dans le SELECT

On pourrait aussi remplir ``cor_observers_synthese`` si on le veut et si on a les observateurs présents dans les données, 
en les faisant correspondre avec leurs ``id_role``.

Insertion depuis un shapefile
-----------------------------

L'exercice est similaire si on part depuis un fichier Shape 
(https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/import-basique/01-observations-faune-2008-2010-SHP.zip)

La seule différence est que la géométrie est calculée lors de l'import de QGIS vers PostGIS.

Ainsi la partie Géométrie de la requête d'insertion dans la Synthèse serait : 

.. code:: sql

  ST_Transform(ST_SetSRID(geom,2154),4326 AS the_geom_4326,
  ST_Centroid(ST_SetSRID(geom,2154) AS the_geom_point,
  geom AS the_geom_local,
