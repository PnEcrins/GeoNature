DROP SCHEMA IF EXISTS pr_occhab CASCADE;
CREATE SCHEMA pr_occhab;

SET search_path = pr_occhab, pg_catalog;



-------------
--FUNCTIONS--
-------------

CREATE OR REPLACE FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0) RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM pr_occhab.defaults_nomenclatures_value
      WHERE mnemonique_type = mytype
      AND (id_organism = 0 OR id_organism = myidorganism)
      ORDER BY id_organism DESC LIMIT 1;
    IF (thenomenclatureid IS NOT NULL) THEN
      RETURN thenomenclatureid;
    END IF;
    RETURN NULL;
  END;
$$;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE pr_occhab.t_stations(
  id_station serial NOT NULL,
  unique_id_sinp_station uuid NOT NULL DEFAULT public.uuid_generate_v4(),
  id_dataset integer NOT NULL,
  date_min timestamp without time zone DEFAULT now() NOT NULL,
  date_max timestamp without time zone DEFAULT now() NOT NULL,
  observers_txt varchar(500),
  station_name varchar(1000),
  is_habitat_complex boolean,
  id_nomenclature_exposure integer,
  altitude_min integer,
  altitude_max integer,
  depth_min integer,
  depth_max integer,
  area bigint,
  id_nomenclature_area_surface_calculation integer,
  comment text,
  geom_local public.geometry(Geometry, :MYLOCALSRID),
  geom_4326 public.geometry(Geometry,4326) NOT NULL,
  precision integer,
  id_digitiser integer,
  numerization_scale character varying (15),
  id_nomenclature_geographic_object integer NOT NULL,
  CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
  CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
  CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
  CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = :MYLOCALSRID))
);

COMMENT ON COLUMN t_stations.id_nomenclature_exposure IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';

COMMENT ON COLUMN t_stations.id_nomenclature_area_surface_calculation IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';


CREATE TABLE pr_occhab.t_habitats(
  id_habitat serial NOT NULL,
  id_station integer NOT NULL,
  unique_id_sinp_hab uuid NOT NULL DEFAULT public.uuid_generate_v4(),
  cd_hab integer NOT NULL,
  nom_cite character varying(500) NOT NULL,
  id_nomenclature_determination_type integer,
  determiner character varying(500),
  id_nomenclature_collection_technique integer NOT NULL,
  recovery_percentage decimal,
  id_nomenclature_abundance integer,
  technical_precision character varying(500),
  unique_id_sinp_grp_occtax uuid,
  unique_id_sinp_grp_phyto uuid,
  id_nomenclature_sensitvity integer,
  id_nomenclature_community_interest integer
);

CREATE TABLE pr_occhab.cor_station_observer(
  id_cor_station_observer serial NOT NULL,
  id_station integer NOT NULL,
  id_role integer NOT NULL
);

CREATE TABLE pr_occhab.defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    id_nomenclature integer NOT NULL
);



----------------
--PRIMARY KEYS--
----------------

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT pk_t_stations PRIMARY KEY (id_station);

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT pk_t_habitats PRIMARY KEY (id_habitat);

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT pk_cor_station_observer PRIMARY KEY (id_cor_station_observer);

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occhab_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism);

----------------
--FOREIGN KEYS--
----------------
   
ALTER TABLE ONLY pr_occhab.t_stations
ADD CONSTRAINT fk_t_releves_occtax_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;


ALTER TABLE ONLY pr_occhab.t_stations
ADD CONSTRAINT fk_t_stations_id_nomenclature_exposure FOREIGN KEY (id_nomenclature_exposure) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
ADD CONSTRAINT fk_t_stations_id_nomenclature_area_surface_calculation FOREIGN KEY (id_nomenclature_area_surface_calculation) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY pr_occhab.t_stations
ADD CONSTRAINT fk_t_stations_id_nomenclature_geographic_object FOREIGN KEY (id_nomenclature_geographic_object) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
ADD CONSTRAINT fk_t_stations_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_station FOREIGN KEY (id_station) REFERENCES pr_occhab.t_stations(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_nomenclature_determination_type FOREIGN KEY (id_nomenclature_determination_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_nomenclature_collection_technique FOREIGN KEY (id_nomenclature_collection_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_nomenclature_abundance FOREIGN KEY (id_nomenclature_abundance) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_nomenclature_sensitvity FOREIGN KEY (id_nomenclature_sensitvity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
ADD CONSTRAINT fk_t_habitats_id_nomenclature_community_interest FOREIGN KEY (id_nomenclature_community_interest) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY pr_occhab.cor_station_observer
ADD CONSTRAINT fk_cor_station_observer_t_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.cor_station_observer
ADD CONSTRAINT fk_cor_station_observer_id_station FOREIGN KEY (id_station) REFERENCES pr_occhab.t_stations(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;



---------------
--CONSTRAINTS--
---------------

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT unique_cor_station_observer UNIQUE (id_station, id_role);

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_date_max CHECK (date_min <= date_max);

ALTER TABLE pr_occhab.t_stations
  ADD CONSTRAINT check_t_stations_exposure CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exposure,'EXPOSITION')) NOT VALID;

ALTER TABLE pr_occhab.t_stations
  ADD CONSTRAINT check_t_stations_geographic_object CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geographic_object,'NAT_OBJ_GEO')) NOT VALID;

ALTER TABLE pr_occhab.t_stations
  ADD CONSTRAINT check_t_stations_area_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_area_surface_calculation,'METHOD_CALCUL_SURFACE')) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
ADD CONSTRAINT check_t_habitats_determini_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_type,'DETERMINATION_TYP_HAB')) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
  ADD CONSTRAINT check_t_habitats_collection_techn CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_collection_technique,'TECHNIQUE_COLLECT_HAB')) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
  ADD CONSTRAINT check_t_habitats_abondance CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_abundance,'ABONDANCE_HAB')) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
  ADD CONSTRAINT check_t_habitats_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitvity,'SENSIBILITE')) NOT VALID;

----------------------
----- INDEX ----------
----------------------
CREATE INDEX i_t_stations_id_dataset
  ON pr_occhab.t_stations
  USING btree
  (id_dataset);

CREATE INDEX i_t_stations_occhab_geom_4326
  ON pr_occhab.t_stations
  USING gist
  (geom_4326);

CREATE INDEX i_t_habitats_id_station
  ON pr_occhab.t_habitats
  USING btree
  (id_station);

CREATE INDEX i_t_habitats_cd_hab
  ON pr_occhab.t_habitats
  USING btree
  (cd_hab);

------------
--TRIGGERS--
------------

CREATE TRIGGER tri_calculate_geom_local
  BEFORE INSERT OR UPDATE
  ON pr_occhab.t_stations
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');


CREATE TRIGGER tri_log_changes_t_habitats_occhab
  AFTER INSERT OR UPDATE OR DELETE
  ON pr_occhab.t_habitats
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_stations_occhab
  AFTER INSERT OR UPDATE OR DELETE
  ON pr_occhab.t_stations
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

------------
--VIEWS--
------------

CREATE view pr_occhab.v_export_sinp AS
SELECT 
s.id_station,
s.id_dataset,
s.id_digitiser,
s.unique_id_sinp_station as "identifiantStaSINP",
ds.unique_dataset_id as "metadonneeId",
nom1.cd_nomenclature as "dSPublique",
to_char(s.date_min, 'DD/MM/YYYY'::text)as "dateDebut",
to_char(s.date_max, 'DD/MM/YYYY'::text)as "dateFin",
s.observers_txt as "observateur",
nom2.cd_nomenclature as "methodeCalculSurface",
public.st_astext(s.geom_4326) as "geometry", -- Pourquoi rajouter st_astext?
public.st_asgeojson(s.geom_4326) as geojson,
s.geom_local,
nom3.cd_nomenclature as "natureObjetGeo",
h.unique_id_sinp_hab as "identifiantHabSINP",
h.nom_cite as "nomCite",
h.cd_hab as "cdHab",
h.technical_precision as "precisionTechnique"
FROM pr_occhab.t_stations as s
JOIN pr_occhab.t_habitats h on h.id_station = s.id_station
JOIN gn_meta.t_datasets ds on ds.id_dataset = s.id_dataset
LEFT join ref_nomenclatures.t_nomenclatures nom1 on nom1.id_nomenclature = ds.id_nomenclature_data_origin
LEFT join ref_nomenclatures.t_nomenclatures nom2 on nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation
LEFT join ref_nomenclatures.t_nomenclatures nom3 on nom3.id_nomenclature = s.id_nomenclature_geographic_object
LEFT join ref_nomenclatures.t_nomenclatures nom4 on nom4.id_nomenclature = h.id_nomenclature_collection_technique;




------------
----DATA----
------------


INSERT INTO pr_occhab.defaults_nomenclatures_value (mnemonique_type, id_organism, id_nomenclature) VALUES
('METHOD_CALCUL_SURFACE',0, ref_nomenclatures.get_id_nomenclature('METHOD_CALCUL_SURFACE', 'sig')),
('NAT_OBJ_GEO',0, ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'NSP')),
('DETERMINATION_TYP_HAB',0, ref_nomenclatures.get_id_nomenclature('DETERMINATION_TYP_HAB', '1')),
('TECHNIQUE_COLLECT_HAB',0, ref_nomenclatures.get_id_nomenclature('TECHNIQUE_COLLECT_HAB', '1'))
;

INSERT INTO gn_commons.bib_tables_location (table_desc, schema_name, table_name, pk_field, uuid_field_name) VALUES
('occurence d''habitat du module OccHab', 'pr_occhab', 't_habitats', 'id_habitat', 'unique_id_sinp_hab')
,('Station correspondant à un regroupement d''occurence d''habitat du module OccHab', 'pr_occhab', 't_stations', 'id_station', 'unique_id_sinp_station')
;

-- ----------------------------------------------------------------------
-- Add available OccHab permissions

-- OCCHAB - CR--ED - ALL - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('OCCHAB'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'OCCHAB-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans OccHab en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'OCCHAB-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('OCCHAB'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'OCCHAB-R-ALL-SCOPE',
        'Lire les données',
        'Lire les données dans OccHab limitées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'OCCHAB-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('OCCHAB'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'OCCHAB-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans OccHab en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'OCCHAB-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('OCCHAB'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'OCCHAB-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans OccHab en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'OCCHAB-D-ALL-SCOPE'
    ) ;
