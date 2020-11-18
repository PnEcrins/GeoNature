-- Mise en place des profils

----------
--SCHEMA--
----------
CREATE SCHEMA gn_profiles;

----------
--TABLES--
----------

CREATE TABLE gn_profiles.t_parameters(
	id_parameter serial NOT NULL,
	name varchar(100) NOT NULL,
	"desc" text NULL,
	value text NOT NULL
);
COMMENT ON TABLE gn_profiles.t_parameters 
	IS 'Define global parameters for profiles calculation';

CREATE TABLE gn_profiles.cor_taxons_parameters(
	cd_nom integer,
	spatial_precision integer,
	temporal_precision_days integer, 
	active_life_stage boolean DEFAULT false
);
COMMENT ON TABLE gn_profiles.cor_taxons_parameters 
	IS 'Define taxa-dependant parameters for profiles calculation, with a 
	recursive application on children taxa';

---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY gn_profiles.t_parameters 
	ADD CONSTRAINT pk_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters 
	ADD CONSTRAINT pk_taxons_parameters PRIMARY KEY (cd_nom);

-----------------
-- FOREIGN KEY --
-----------------

ALTER TABLE ONLY gn_profiles.cor_taxons_parameters 
	ADD CONSTRAINT fk_cor_taxons_parameters_cd_nom FOREIGN KEY (cd_nom) 
	REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

------------------
-- DEFAULT DATA --
------------------

INSERT INTO gn_profiles.cor_taxons_parameters(
	cd_nom, spatial_precision, temporal_precision_days, active_life_stage
)
SELECT 
	DISTINCT t.cd_nom, 
	2000, 
	10,
	false
FROM taxonomie.taxref t
WHERE id_rang='KD';

-- Ajout d'un paramètre pour définir le niveau de validatation requis pour que les données alimentent
-- le calcul des profils
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
SELECT 
	'id_valid_status_for_profiles', 
	'Liste des id_nomenclature du statut de validation permettant de définir les données à prendre
	en compte dans le calcul des profils d''espèces. A renseigner sous forme de liste id1,id2,id3.',
	string_agg(DISTINCT n.id_nomenclature::text, ','::text)
FROM ref_nomenclatures.t_nomenclatures n
WHERE n.id_type=(
	SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types bnt WHERE mnemonique='STATUT_VALID'
	)
AND n.cd_nomenclature IN ('1','2') -- Commenter pour considérer l'ensemble des données;
; 

-- Ajout d'un paramètre pour définir le niveau de validatation requis pour que les données alimentent
-- le calcul des profils
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
VALUES ( 
	'id_rang_for_profiles', 
	'Liste des id_rang du taxref pour lesquels les profils doivent être calculés. A renseigner sous forme de liste id1,id2,id3.',
	'GN,ES,SSES'
)
;

-- Ajout d'un paramètre pour définir le pourcentage de données à conserver dans le calcul des profils 
-- afin d'exclure les données aux altitudes extrêmes
INSERT INTO gn_profiles.t_parameters(
	name, "desc", value
)
VALUES (
	'proportion_kept_data', 
	'Pourcentage de données à conserver dans le calcul des profils afin d''exclure les données aux 
	altitudes extrêmes. Ce paramètre doit être supérieur à 50 pour que la phénologie soit calculée.',
	95
);

-------------
--FUNCTIONS--
-------------

-- Fonctions dédiées à la comparaison des données avec leur profil d'espèce dans gn_profiles
CREATE OR REPLACE FUNCTION gn_profiles.get_parameters(my_cd_nom integer)
 RETURNS TABLE (
	 cd_ref integer, spatial_precision integer, temporal_precision_days integer, 
	 active_life_stage boolean, distance smallint
	)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- fonction permettant de récupérer les paramètres les plus adaptés 
-- (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
-- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard, 
-- les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce
  DECLARE 
   my_cd_ref integer := t.cd_ref FROM taxonomie.taxref t WHERE t.cd_nom=my_cd_nom;
  BEGIN
  	RETURN QUERY
  		WITH all_parameters AS (
  			SELECT my_cd_ref, param.spatial_precision, param.temporal_precision_days, 
			  param.active_life_stage, parents.distance 
  			FROM gn_profiles.cor_taxons_parameters param
			JOIN taxonomie.find_all_taxons_parents(my_cd_ref) parents ON parents.cd_nom=param.cd_nom)
		SELECT * FROM all_parameters all_param WHERE all_param.distance=(
			SELECT min(all_param2.distance) FROM all_parameters all_param2
		)
			;
  END;
$function$
;


CREATE OR REPLACE FUNCTION gn_profiles.check_profile_distribution(my_id_synthese integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que sa 
--localisation est totalement incluse dans l'aire d'occurrences valide définie par le profil du
--taxon en question
  DECLARE 
    my_cd_ref integer := t.cd_ref 
		FROM taxonomie.taxref t 
		JOIN gn_synthese.synthese s ON s.cd_nom=t.cd_nom 
		WHERE s.id_synthese=my_id_synthese;
    valid_geom geometry := vp.valid_distribution 
		FROM gn_profiles.vm_valid_profiles vp 
		WHERE vp.cd_ref=my_cd_ref;
  	check_geom geometry := s.the_geom_local 
	  FROM gn_synthese.synthese s
	   WHERE s.id_synthese=my_id_synthese ;
  BEGIN
     IF ST_Contains(valid_geom, check_geom) 
    THEN
   	  RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$
;


CREATE OR REPLACE FUNCTION gn_profiles.check_profile_phenology(my_id_synthese integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que 
-- sa phénologie (dates, altitude, stade de vie selon les paramètres) 
--correspond bien à la phénologie valide définie par le profil du taxon en question
--La fonction renvoie 'false' pour les données trop imprécises (durée d'observation supérieure à 
-- la précision temporelle définie dans les paramètres des profils).
  BEGIN
  	IF EXISTS(
		WITH myphenology AS (
  			SELECT DISTINCT
				t.cd_ref AS cd_ref,
				unnest(
					ARRAY[ceiling(EXTRACT(DOY FROM s.date_min)/p.temporal_precision_days)::integer, 
					ceiling(EXTRACT(DOY FROM s.date_max)/p.temporal_precision_days)::integer]
				) AS period,
				CASE 
					WHEN p.active_life_stage=true THEN s.id_nomenclature_life_stage
					ELSE NULL
					END AS id_nomenclature_life_stage,
				s.altitude_min,
				s.altitude_max
			FROM gn_synthese.synthese s
			LEFT JOIN taxonomie.taxref t ON s.cd_nom=t.cd_nom
			CROSS JOIN gn_profiles.get_parameters(s.cd_nom) p
			WHERE s.id_synthese=my_id_synthese
				AND p.temporal_precision_days IS NOT NULL 
				AND p.spatial_precision  IS NOT NULL
				AND p.active_life_stage IS NOT NULL
				AND DATE_part('day', s.date_max-s.date_min)<p.temporal_precision_days
   		 		AND ST_MaxDistance(ST_centroid(s.the_geom_local), s.the_geom_local)<p.spatial_precision 
			GROUP BY t.cd_ref, period, 
			CASE 
				WHEN p.active_life_stage=true THEN s.id_nomenclature_life_stage 
				ELSE NULL 
			END,
			altitude_min,
			altitude_max)
		SELECT * 
		FROM myphenology mp, gn_profiles.vm_cor_taxon_phenology ctp
		WHERE ctp.cd_ref=mp.cd_ref
		AND mp.period=ctp.period
		AND mp.altitude_min >= ctp.calculated_altitude_min
		AND mp.altitude_max <= ctp.calculated_altitude_max
		AND (ctp.id_nomenclature_life_stage=mp.id_nomenclature_life_stage 
		OR (ctp.id_nomenclature_life_stage IS NULL AND mp.id_nomenclature_life_stage IS NULL))
		)
	THEN
   	  RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$
;


CREATE OR REPLACE FUNCTION gn_profiles.check_profile_altitudes(my_id_synthese integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que 
-- son altitude se trouve entièrement comprise dans la fourchette altitudinale valide du taxon en question
  DECLARE 
    my_cd_ref integer := t.cd_ref 
	FROM taxonomie.taxref t 
	JOIN gn_synthese.synthese s ON s.cd_nom=t.cd_nom 
	WHERE s.id_synthese=my_id_synthese;
  BEGIN
     IF (
		 SELECT altitude_min 
		 FROM gn_synthese.synthese 
		 WHERE id_synthese=my_id_synthese
		) >= (
			SELECT altitude_min 
			FROM gn_profiles.vm_valid_profiles 
			WHERE cd_ref=my_cd_ref
		)
     AND  (
		 SELECT altitude_max 
		 FROM gn_synthese.synthese 
		 WHERE id_synthese=my_id_synthese
		) <= (
			SELECT altitude_max 
			FROM gn_profiles.vm_valid_profiles 
			WHERE cd_ref=my_cd_ref
		)
    THEN
   	  RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$
;


CREATE OR REPLACE FUNCTION gn_profiles.get_profile_score(my_id_synthese integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant 
-- que sa localisation est totalement incluse dans l'aire d'occurrences valide définie par le 
-- profil du taxon en question
  DECLARE 
  	score integer;
    BEGIN 
     	SELECT INTO score gn_profiles.check_profile_distribution(my_id_synthese)::int + 
		 gn_profiles.check_profile_phenology(my_id_synthese)::int + 
		 gn_profiles.check_profile_altitudes(my_id_synthese)::int;
     	RETURN score;
  END;
$function$
;

----------------------------------
-- VIEWS AND MATERIALIZED VIEWS --
----------------------------------

CREATE OR REPLACE VIEW gn_profiles.v_synthese_for_profiles AS
SELECT 
	s.id_synthese,
	s.cd_nom,
	s.nom_cite,
	t.cd_ref,
	t.nom_valide,
	t.id_rang,
	s.date_min, 
	s.date_max,
	s.the_geom_local,
	s.the_geom_4326,
	s.altitude_min,
	s.altitude_max,
	s.id_nomenclature_life_stage,
	s.id_nomenclature_valid_status
FROM gn_synthese.synthese s
LEFT JOIN taxonomie.taxref t ON s.cd_nom=t.cd_nom
CROSS JOIN gn_profiles.get_parameters(s.cd_nom) p
WHERE p.spatial_precision IS NOT NULL AND 
	ST_MaxDistance(ST_centroid(s.the_geom_local), s.the_geom_local)<p.spatial_precision 
AND s.id_nomenclature_valid_status IN (
	SELECT regexp_split_to_table(value, ',')::integer 
	FROM gn_profiles.t_parameters 
	WHERE name='id_valid_status_for_profiles'
	)
AND t.id_rang IN (
	SELECT regexp_split_to_table(value, ',')
	FROM gn_profiles.t_parameters 
	WHERE name='id_rang_for_profiles'
	)
;
COMMENT ON VIEW gn_profiles.v_synthese_for_profiles 
	IS 'View containing synthese data feeding profiles calculation. 
	cd_ref, date_min, date_max, the_geom_local, altitude_min, altitude_max and 
	id_nomenclature_life_stage fields are mandatory. 
	WHERE clauses have to apply your t_parameters filters (valid_status)'
;

CREATE MATERIALIZED VIEW gn_profiles.vm_valid_profiles AS
SELECT DISTINCT
	vsfp.cd_ref AS cd_ref,
	st_union(st_buffer(vsfp.the_geom_local, COALESCE(p.spatial_precision, 1))) AS valid_distribution,
	min(vsfp.altitude_min) AS altitude_min,
	max(vsfp.altitude_max) AS altitude_max,
	min(vsfp.date_min) AS first_valid_data,
	max(vsfp.date_max) AS last_valid_data,
	count(vsfp.*) AS count_valid_data
FROM gn_profiles.v_synthese_for_profiles vsfp
CROSS JOIN gn_profiles.get_parameters(vsfp.cd_nom) p
GROUP BY vsfp.cd_ref
WITH DATA
;
COMMENT ON MATERIALIZED VIEW gn_profiles.vm_valid_profiles 
	IS 'View containing unique valid information per taxon : first/last obs, 
	distribution, extreme altitudes'
;

CREATE UNIQUE INDEX ON gn_profiles.vm_valid_profiles (cd_ref);

CREATE MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology AS 
WITH classified_data AS (
SELECT DISTINCT
	vsfp.cd_ref AS cd_ref,
	unnest(
		ARRAY[ceiling(EXTRACT(DOY FROM vsfp.date_min)/p.temporal_precision_days)::integer, 
		ceiling(EXTRACT(DOY FROM vsfp.date_max)/p.temporal_precision_days)::integer]
	) AS period,
	CASE 
		WHEN p.active_life_stage=true 
			THEN vsfp.id_nomenclature_life_stage
		ELSE NULL
		END AS id_nomenclature_life_stage,
	count(vsfp.*) AS count_valid_data,
	min(vsfp.altitude_min) as extreme_altitude_min,
	array_agg(vsfp.altitude_min order by vsfp.altitude_min ASC) as my_alt_min,
	max(vsfp.altitude_max) as extreme_altitude_max,
	array_agg(vsfp.altitude_max order by vsfp.altitude_max DESC) as my_alt_max
FROM gn_profiles.v_synthese_for_profiles vsfp
CROSS JOIN gn_profiles.get_parameters(vsfp.cd_nom) p
WHERE p.temporal_precision_days IS NOT NULL 
	AND p.spatial_precision  IS NOT NULL
	AND p.active_life_stage IS NOT NULL
	AND DATE_part('day', vsfp.date_max-vsfp.date_min)<p.temporal_precision_days
    AND vsfp.altitude_min IS NOT NULL
    AND vsfp.altitude_max IS NOT NULL
GROUP BY vsfp.cd_ref, period, CASE WHEN p.active_life_stage=true THEN vsfp.id_nomenclature_life_stage 
	ELSE NULL end)
SELECT 
cd_ref,
period,
id_nomenclature_life_stage,
count_valid_data,
extreme_altitude_min,
CASE WHEN (count_valid_data*(SELECT (1-value::integer/100::float)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))
		  >=(count_valid_data*(SELECT (value::integer/100::float)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))THEN NULL
		-- Case when "Removed data" more than kept data, not enough data to calculate alt_min
	ELSE my_alt_min[round(count_valid_data*(SELECT ((1-value::integer/100::float)/2)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))] 
		-- Else, calculated alt_min removing X firsts data depending on the parameter
	END as calculated_altitude_min,
extreme_altitude_max,
CASE WHEN (count_valid_data*(SELECT (1-value::integer/100::float)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))
		  >=(count_valid_data*(SELECT (value::integer/100::float)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))THEN NULL
		-- Case when "Removed data" more than kept data, not enough data to calculate alt_min
	ELSE my_alt_max[round(count_valid_data*(SELECT ((1-value::integer/100::float)/2)
									FROM gn_profiles.t_parameters 
									WHERE name='proportion_kept_data'))] 
		-- Else, calculated alt_min removing X firsts data depending on the parameter
	END as calculated_altitude_max
FROM classified_data
WITH DATA
;
COMMENT ON MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology 
	IS 'View containing phenological combinations and corresponding valid data for each taxa';

CREATE UNIQUE INDEX ON gn_profiles.vm_cor_taxon_phenology (cd_ref, period, id_nomenclature_life_stage);

CREATE VIEW gn_profiles.v_consistancy_data AS
SELECT 
	s.id_synthese AS id_synthese,
	s.unique_id_sinp AS id_sinp,
	t.cd_ref AS cd_ref,
	t.lb_nom AS valid_name,
	gn_profiles.check_profile_distribution(id_synthese) AS valid_distribution, 
	gn_profiles.check_profile_phenology(id_synthese) AS valid_phenology, 
	gn_profiles.check_profile_altitudes(id_synthese) AS valid_altitude,
	gn_profiles.get_profile_score(id_synthese) AS score,
	n.label_default AS valid_status
FROM gn_synthese.synthese s
LEFT JOIN ref_nomenclatures.t_nomenclatures n ON s.id_nomenclature_valid_status = n.id_nomenclature
LEFT JOIN taxonomie.taxref t ON s.cd_nom=t.cd_nom;
COMMENT ON VIEW gn_profiles.v_consistancy_data
	IS 'View containing consistancy checks and score for each synthese data';

CREATE VIEW gn_profiles.v_decode_profiles_parameters AS
SELECT
	t.cd_ref,
	t.lb_nom,
	t.id_rang,
	p.spatial_precision,
	p.temporal_precision_days,
	p.active_life_stage
FROM gn_profiles.cor_taxons_parameters p
LEFT JOIN taxonomie.taxref t ON p.cd_nom=t.cd_nom;
COMMENT ON VIEW gn_profiles.v_decode_profiles_parameters
	IS 'View containing rules applied for each decoded taxa';


CREATE OR REPLACE FUNCTION gn_profiles.refresh_profiles()
RETURNS VOID AS $$
-- Rafraichissement des vues matérialisées des profils
-- USAGE : SELECT gn_profiles.refresh_profiles()
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_valid_profiles;
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_cor_taxon_phenology;
END
$$ LANGUAGE plpgsql;

-----------
-- INDEX --
-----------

CREATE INDEX index_vm_valid_profiles_cd_ref
  ON gn_profiles.vm_valid_profiles (cd_ref);

CREATE INDEX index_vm_cor_taxon_phenology_cd_ref
  ON gn_profiles.vm_cor_taxon_phenology (cd_ref);


-- Suppression des anciennes VM et fonctions similaires
DROP MATERIALIZED VIEW gn_synthese.vm_min_max_for_taxons; 
DROP FUNCTION gn_synthese.fct_calculate_min_max_for_taxon; 
DROP FUNCTION gn_synthese.fct_tri_refresh_vm_min_max_for_taxons;