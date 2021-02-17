-- Add tables to store permissions requests and alter permissions tables
BEGIN ;

-- -------------------------------------------------------------------------------------------------
-- Add comments on existing tables, columns and primary key sequences

-- Table "bib_filters_type"
COMMENT ON TABLE gn_permissions.bib_filters_type IS 
    E'Contient les types de filtres de permissions disponibles.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.id_filter_type IS 
    E'Identifiant auto-incrementé d''un type de filtre.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.code_filter_type IS 
    E'Code du type de filtre. Si possible un mot en anglais et en majuscule.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.label_filter_type IS 
    E'Libellé court du type de filtre en français. Se baser sur les existants pour l''uniformité.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.description_filter_type IS 
    E'Description du type de filtre en français. '
     'Décrire l''objet de la limitation, les valeurs possibles.';
COMMENT ON SEQUENCE gn_permissions.bib_filters_type_id_filter_type_seq IS 
    E'Séquence de la clé primaire de la table "bib_filters_type".' ;

-- Table "cor_role_action_filter_module_object"
COMMENT ON TABLE gn_permissions.cor_role_action_filter_module_object IS 
    E'Contient les permissions attribuées aux utilisateurs ou groupes.';
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_permission IS 
	E'Identifiant auto-incrementé d''une permission attribuée' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_role IS 
	E'Identifiant du rôle/groupe de l''utitilisateur concerné par la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_action IS 
	E'Identifiant de l''action (CRUVED) de la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_module IS 
	E'Identifiant du module de la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_object IS 
	E'Identifiant de l''objet de la permission.' ;
COMMENT ON SEQUENCE gn_permissions.cor_role_action_filter_module_object_id_permission_seq IS
    E'Séquence de la clé primaire de la table "cor_role_action_filter_module_object".' ;

-- Table "t_actions"
COMMENT ON TABLE gn_permissions.t_actions IS 
    E'Contient les actions (CRUVED) disponibles.';
COMMENT ON COLUMN gn_permissions.t_actions.id_action IS 
	E'Identifiant auto-incrementé d''une action' ;
COMMENT ON COLUMN gn_permissions.t_actions.code_action IS 
    E'Code de l''action. Si possible une lettre en anglais et en majuscule.';
COMMENT ON COLUMN gn_permissions.t_actions.description_action IS 
    E'Description de l''action en français.';
COMMENT ON SEQUENCE gn_permissions.t_actions_id_action_seq IS
    E'Séquence de la clé primaire de la table "t_actions".' ;

-- Table "t_objects"
COMMENT ON TABLE gn_permissions.t_objects IS 
    E'Contient les objets ou ressources disponibles dans GeoNature. '
     'Les objets sont plus ou moins spécifiques à un module.';
COMMENT ON COLUMN gn_permissions.t_objects.id_object IS 
	E'Identifiant auto-incrementé d''un objet' ;
COMMENT ON COLUMN gn_permissions.t_objects.code_object IS 
    E'Code de l''objet. Si possible un mot ou deux en anglais en majuscule, '
     'avec le tiret bas ("_") comme séparateur de mots.';
COMMENT ON COLUMN gn_permissions.t_objects.description_object IS 
    E'Description détaillée de l''objet en français.';
COMMENT ON SEQUENCE gn_permissions.t_objects_id_object_seq IS
    E'Séquence de la clé primaire de la table "t_objects".' ;


-- -------------------------------------------------------------------------------------------------
-- Add new utilities functions
CREATE OR REPLACE FUNCTION gn_permissions.get_id_action(actionCode character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS $BODY$
    BEGIN
        RETURN (
            SELECT id_action
            FROM gn_permissions.t_actions
            WHERE code_action = actionCode
        );
    END;
$BODY$ ;

CREATE OR REPLACE FUNCTION gn_permissions.get_id_filter_type(filterTypeCode character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS $BODY$
    BEGIN
        RETURN (
            SELECT id_filter_type
            FROM gn_permissions.bib_filters_type
            WHERE code_filter_type = filterTypeCode
        );
    END;
$BODY$ ;


-- -------------------------------------------------------------------------------------------------
-- Add constraint for "id_module" in table "cor_role_action_filter_module_object"
ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_module CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "bib_filters_values" primary key
DROP SEQUENCE IF EXISTS gn_permissions.bib_filters_values_id_filter_value_seq CASCADE ;

CREATE SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

-- ALTER SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq OWNER TO geonatadmin;

COMMENT ON SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq IS 
    E'Auto-incrément de la clé primaire de la table bib_filters_values.' ;

-- -------------------------------------------------------------------------------------------------
-- Create request states enum 
DROP TYPE IF EXISTS filter_value_formats CASCADE ;

CREATE TYPE filter_value_formats AS ENUM ('string', 'integer', 'boolean', 'geometry', 'csvint') ;


-- -------------------------------------------------------------------------------------------------
-- Create filters values types table 
DROP TABLE IF EXISTS gn_permissions.bib_filters_values CASCADE ;

CREATE TABLE gn_permissions.bib_filters_values (
	id_filter_value integer NOT NULL 
        DEFAULT nextval('gn_permissions.bib_filters_values_id_filter_value_seq'::regclass),
	id_filter_type integer,
    value_format filter_value_formats NOT NULL,
    predefined boolean NOT NULL,
    value_or_field varchar(50) NOT NULL,
    label varchar(255) NOT NULL,
    description text,
	CONSTRAINT pk_bib_filters_values PRIMARY KEY (id_filter_value)
) ;
COMMENT ON TABLE gn_permissions.bib_filters_values IS 
    E'Contient les types de valeurs des filtres.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.id_filter_value IS 
    E'Identifiant auto-incrementé d''un type de valeur de filtre.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.id_filter_type IS 
    E'Identifiant du type de filtre auquel la valeur appartient.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.value_format IS 
    E'Format de la valeur : chaine de caractère (="str"), '
     'un nombre entier unique (="int"), '
     'une liste de nombres entiers séparés par des virgules (="csv-int),'
     'une géométrie (="geom").';
COMMENT ON COLUMN gn_permissions.bib_filters_values.predefined IS 
    E'Indique si la valeur est prédinie (=true) en étant limitée par une liste figée de valeurs '
    'ou libre (=false) en dépendant de choix réalisés par l''utilisateur.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.value_or_field IS 
    E'Code alphanumérique représentant une valeur du filtre ou pour le format "csv-int" '
     'le nom du champ correspondant aux nombres entiers séparés par des virgules.'
     'Dans le cas des valeurs prédéfinies, privilégier un mot anglais court.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.label IS 
    E'Nom court représentant la valeur. Surtout utile pour les valeurs prédéfinies.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.description IS 
    E'Description détaillée du type de valeur.';


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "bib_filters_values"
ALTER TABLE gn_permissions.bib_filters_values 
    DROP CONSTRAINT IF EXISTS fk_bib_filters_values_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.bib_filters_values 
    ADD CONSTRAINT fk_bib_filters_values_id_filter_type FOREIGN KEY (id_filter_type)
    REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
    ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Add filters values types knowned
INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '0',
        'À personne',
        'Aucune appartenance. Cette valeur empèche l''accès aux objets.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '0'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '1',
        'À moi',
        'Appartenant à l''utilisateur. '
        'Indique un accès restreint aux objets créés/associés '
        'à l''utilisateur connecté.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '1'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '2',
        'À mon organisme',
        'Appartenant à l''ogranisme de l''utilisateur. '
        'Indique un accès restreint aux objets créés/associés à des utilisateurs '
        'du même organisme que l''utilisateur actuellement connecté.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '2'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '3',
        'À tout le monde',
        'Appartenant à tout le monde. '
        'Indique un accès à tous non restreint par l''appartenance des objets.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '3'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'csvint',
        false,
        'ref_geo.l_areas.id_area',
        'id_area',
        'Liste d''identifiant de zones géographiques séparés par des virgules. '
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('GEOGRAPHIC')
            AND bfv.value_or_field = 'id_area'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'csvint',
        false,
        'taxonomie.taxref.cd_nom',
        'cd_nom',
        'Liste d''identifiant de noms scientifiques séparés par des virgules. '
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('TAXONOMIC')
            AND bfv.value_or_field = 'cd_nom'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('PRECISION'),
        'string',
        true,
        'exact',
        'Exacte',
        'Accès aux objets avec les informations géographiques précises.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('PRECISION')
            AND bfv.value_or_field = 'exact'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('PRECISION'),
        'string',
        true,
        'fuzzy',
        'Floutée',
        'Accès aux objets avec les informations géographiques floutées.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('PRECISION')
            AND bfv.value_or_field = 'fuzzy'
    ) ;


-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "t_requests" primary key
DROP SEQUENCE IF EXISTS gn_permissions.t_requests_id_request_seq CASCADE ;

CREATE SEQUENCE gn_permissions.t_requests_id_request_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

-- ALTER SEQUENCE gn_permissions.t_requests_id_request_seq OWNER TO geonatadmin;

COMMENT ON SEQUENCE gn_permissions.t_requests_id_request_seq IS 
    E'Auto-incrément de la clé primaire de la table t_requests.' ;


-- -------------------------------------------------------------------------------------------------
-- Create request states enum 
DROP TYPE IF EXISTS request_states CASCADE ;

CREATE TYPE request_states AS ENUM ('pending', 'refused', 'accepted') ;


-- -------------------------------------------------------------------------------------------------
-- Create requests table 
DROP TABLE IF EXISTS gn_permissions.t_requests CASCADE ;

CREATE TABLE gn_permissions.t_requests (
	id_request integer NOT NULL DEFAULT nextval('gn_permissions.t_requests_id_request_seq'::regclass),
	id_role integer,
    token uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    end_date date,
	processed_state request_states NOT NULL DEFAULT 'pending',
    processed_date timestamp,
    processed_by integer,
    refusal_reason varchar(1000),
    -- TODO: maybe using a single field "filters" with jsonb could be simplify the code
    geographic_filter text,
    taxonomic_filter text,
    sensitive_access boolean DEFAULT false,
	additional_data jsonb,  
	meta_create_date timestamp NOT NULL DEFAULT now(),
	meta_update_date timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_t_requests PRIMARY KEY (id_request)
) ;
COMMENT ON TABLE gn_permissions.t_requests IS 
    E'Contient les demandes de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.id_request IS 
    E'Identifiant auto-incrementé d''une demande de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.id_role IS 
	E'Identifiant de l''utilisateur (=rôle) réalisant la demande de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.token IS 
	E'Jeton de la demande de permissions. Identifie cette demande lors des appels par web service.';
COMMENT ON COLUMN gn_permissions.t_requests.end_date IS 
	E'Date de fin des permissions demandées. Null indique une demande de permissions permanente.';
COMMENT ON COLUMN gn_permissions.t_requests.processed_state IS 
	E'État de la demande correspondant à un ENUM.\n'
     'Valeurs possibles : acceptée (=accepted), demande refusée (=refused), demande en attente (=pending).';
COMMENT ON COLUMN gn_permissions.t_requests.processed_date IS 
	E'Date et heure de la dernière acceptation ou refus de la demande. Null pour les demandes en attente.';
COMMENT ON COLUMN gn_permissions.t_requests.processed_by IS 
	E'Identifiant du dernier utilisateur (=rôle) ayant accepté/refusé la demande. '
     'Null pour les demandes en attente et les actions via email.';
COMMENT ON COLUMN gn_permissions.t_requests.refusal_reason IS 
	E'Si accepted = false, peut contenir la raison du refus. '
     'Null pour les demandes en attente ou pour les refus sans raison.';
COMMENT ON COLUMN gn_permissions.t_requests.geographic_filter IS 
	E'Contient la liste des id_area du filtre géographique. '
     'Séparer les valeurs par des virgules.';
COMMENT ON COLUMN gn_permissions.t_requests.taxonomic_filter IS 
	E'Contient la liste des cd_nom du filtre taxonomique. '
     'Séparer les valeurs par des virgules.';
COMMENT ON COLUMN gn_permissions.t_requests.sensitive_access IS 
	E'Indique si oui (=true) ou non (=false) l''accès aux données sensibles est demandé.';
COMMENT ON COLUMN gn_permissions.t_requests.additional_data IS 
	E'Contient des données complémentaires liées à la demande de permissions d''accès. '
     'Données du formulaire dynamique. Utiliser un objet JSON.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_create_date IS 
	E'Date et heure de création de l''enregistrement.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_update_date IS 
	E'Date de mise à jour de l''enregistrement. '
     'À la création de l''enregistrement, correspond à la date et heure de création.';

-- ALTER TABLE gn_permissions.t_requests OWNER TO geonatadmin ;


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "t_requests"
ALTER TABLE gn_permissions.t_requests 
    DROP CONSTRAINT IF EXISTS fk_t_requests_id_role CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_id_role FOREIGN KEY (id_role)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.t_requests 
    DROP CONSTRAINT IF EXISTS fk_t_requests_processed_by CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_processed_by FOREIGN KEY (processed_by)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Triggers
CREATE OR REPLACE FUNCTION gn_permissions.tri_func_modify_meta_update_date()
    RETURNS trigger
    LANGUAGE plpgsql
AS $BODY$
BEGIN
    NEW.meta_update_date := now();
    RETURN NEW;
END;
$BODY$ ;


DROP TRIGGER IF EXISTS tri_modify_meta_update_date_t_requests 
    ON gn_permissions.t_requests;

CREATE TRIGGER tri_modify_meta_update_date_t_requests
    AFTER UPDATE
    ON gn_permissions.t_requests
    FOR EACH ROW
        EXECUTE PROCEDURE gn_permissions.tri_func_modify_meta_update_date();


-- -------------------------------------------------------------------------------------------------
-- Update and add new Objects for Admin and Synthese modules
UPDATE gn_permissions.t_objects 
SET description_object = 'Gestion des permissions' 
WHERE code_object = 'PERMISSIONS' ;

INSERT INTO gn_permissions.t_objects (code_object, description_object) 
    SELECT
        'ACCESS_REQUESTS',
        'Gestion des demandes de permissions d''accès'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.t_objects AS o
        WHERE o.code_object = 'ACCESS_REQUESTS'
    ) ;

INSERT INTO gn_permissions.t_objects (code_object, description_object) 
    SELECT
        'PRIVATE_OBSERVATION',
        'Observation privée'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.t_objects AS o
        WHERE o.code_object = 'PRIVATE_OBSERVATION'
    ) ;

INSERT INTO gn_permissions.t_objects (code_object, description_object) 
    SELECT
        'SENSITIVE_OBSERVATION',
        'Observation senssible'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.t_objects AS o
        WHERE o.code_object = 'SENSITIVE_OBSERVATION'
    ) ;


-- -------------------------------------------------------------------------------------------------
-- Rename filter "SENSITIVITY" to "PRECISION" and update others. See #1062.
UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre d''appartenance',
    description_filter_type = E'Permissions limitées par le type d''appartenances des données.\n'
        'Accès à : aucune (=0), les miennes (=1), celles de mon organisme (=2), toutes (=3).'
WHERE code_filter_type = 'SCOPE' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre géographique',
    description_filter_type = E'Permissions limitées par zones géographiques.\n'
        'Utiliser des id_area séparés par des virgules.'
WHERE code_filter_type = 'GEOGRAPHIC' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre taxonomique',
    description_filter_type = E'Permissions limitées par des taxons.\n'
        'Utiliser des cd_nom séparés par des virgules.'
WHERE code_filter_type = 'TAXONOMIC' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    code_filter_type = 'PRECISION',
    label_filter_type = 'Filtre de précision',
    description_filter_type = 'Active (=fuzzy) ou désactive (=exact) le floutage des données (sensibles ou privées).'
WHERE code_filter_type = 'SENSITIVITY' ;


-- -------------------------------------------------------------------------------------------------
-- Drop "v_roles_permissions" before alterate "cor_role_action_filter_module_object"
-- because columns depend on it.
DROP VIEW IF EXISTS gn_permissions.v_roles_permissions ;


-- -------------------------------------------------------------------------------------------------
-- Drop trigger before migrate, recreate it after migrate
DROP TRIGGER IF EXISTS tri_check_no_multiple_filter_type 
    ON gn_permissions.cor_role_action_filter_module_object ;


-- -------------------------------------------------------------------------------------------------
-- Migrate "t_filters" entries in updated cor_role_action_filter_module_object table.
-- TODO: see why this update can be blocked by trigger gn_permissions.fct_tri_only_one_filter_type_by_permission()
DO
$$
DECLARE
    tablesFoundCount INTEGER := 0;
BEGIN
    RAISE NOTICE 'Migrate data if tables t_filters, cor_object_module, cor_filter_type_module exist' ;
    
    SELECT COUNT(*) INTO tablesFoundCount
    FROM information_schema.tables 
    WHERE table_schema = 'gn_permissions' 
        AND table_name IN ('t_filters', 'cor_object_module', 'cor_filter_type_module') ;

    IF tablesFoundCount = 3 THEN
        RAISE NOTICE 'Tables exist ! Let''s start to migrate data...' ;
        
        -- -------------------------------------------------------------------------------------------------
        -- Alter table "cor_role_action_filter_module_object" to group permissions,
        -- manage permissions timing, store value of filters.
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            DROP COLUMN IF EXISTS gathering,
            DROP COLUMN IF EXISTS end_date,
            DROP COLUMN IF EXISTS id_filter_type,
            DROP COLUMN IF EXISTS value_filter,
            DROP COLUMN IF EXISTS id_request ;


        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            ADD COLUMN gathering uuid DEFAULT public.uuid_generate_v4(),
            ADD COLUMN end_date timestamp NULL,
            ADD COLUMN id_filter_type int4 NULL,
            -- TODO: not used today. Remove ? See if really usefull or not !
            -- ADD COLUMN id_filter_value int4 NULL,
            ADD COLUMN value_filter text NULL,
            ADD COLUMN id_request int4 NULL ;


        COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.gathering IS 
            E'Groupe les permissions. Toutes les permissions possédant le même UUID sont à rassembler.'
            'Permet ainsi de cummuler plusieurs filtres distincts.' ;
        COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.end_date IS 
            E'Indique la date à laquelle la permission prend fin la permission. '
            'Répéter cette date pour toutes les permissions d''un même groupe.' ;
        COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_filter_type IS 
            E'Identifiant du type de filtre de la permission.' ;
        -- TODO: not used today. Remove ?
        -- COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_filter_value IS 
        -- 	E'Identifiant du type de valeur du filtre de la permission.'
        --   'Utile pour les filtres non prédéfini pouvant posséder plusieurs types de valeurs.' ;
        COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.value_filter IS 
            E'Contient les valeurs du filtre à appliquer. '
            'Voir la description du type de filtre pour les valeurs possibles.' ;
        COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_request IS 
            E'Identifiant de la requête à l''origine de la création de la permission'
            'Si la permission n''est pas liée à une demande d''accès contient NULL.' ;


        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_filter_type CASCADE ;

        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            ADD CONSTRAINT fk_cor_r_a_f_m_o_id_filter_type FOREIGN KEY (id_filter_type)
            REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
            ON UPDATE CASCADE ;

        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_request CASCADE ;

        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            ADD CONSTRAINT fk_cor_r_a_f_m_o_id_request FOREIGN KEY (id_request)
            REFERENCES gn_permissions.t_requests (id_request) MATCH FULL
            ON UPDATE CASCADE ;

        -- -------------------------------------------------------------------------------------------------
        -- Migrate "t_filters" entries
        UPDATE gn_permissions.cor_role_action_filter_module_object AS c
        SET 
            id_filter_type = f.id_filter_type,
            value_filter = f.value_filter
        FROM gn_permissions.t_filters AS f
        WHERE c.id_filter = f.id_filter 
            AND c.id_filter_type IS NULL
            AND c.value_filter IS NULL ;

        -- -------------------------------------------------------------------------------------------------
        -- Re-alter table "cor_role_action_filter_module_object" to set NOT NULL on columns after migrate
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            ALTER COLUMN id_filter_type SET NOT NULL,
            ALTER COLUMN value_filter SET NOT NULL ;

        -- -------------------------------------------------------------------------------------------------
        -- Remove useless column from cor_role_action_filter_module_object
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object
            DROP COLUMN IF EXISTS id_filter, 
            DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_filter CASCADE ;

    ELSE
        RAISE NOTICE 'Tables NOT exist. Founded tables : %. Migration already passed ?', tablesFoundCount ;
    END IF ;
END ;
$$ ;


-- -------------------------------------------------------------------------------------------------
-- Rename and update trigger to force only one filter type by permission (gathering)
-- TODO: can we replace this trigger by unique index ?
CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_only_one_filter_type_by_permission()
RETURNS trigger AS
$BODY$
    -- Check if a role has not already the same filter type for a permission (= module-action-object).
    -- Use as constraint to force not set multiple same filter type by permission (= module-action-object).
    DECLARE 
        codeFilterType character varying ;
        filterRecordNbr integer ;
    BEGIN
        -- For this filter type, check if there is not already a permission with it for this
        -- role-module-action-object-gathering
        SELECT INTO filterRecordNbr COUNT(id_permission)
        FROM gn_permissions.cor_role_action_filter_module_object
        WHERE id_role = NEW.id_role 
            AND id_module = NEW.id_module 
            AND id_action = NEW.id_action 
            AND id_object = NEW.id_object 
            AND gathering = NEW.gathering
            AND id_filter_type = NEW.id_filter_type ;
       
        -- For INSERT and UPDATE
        IF (filterRecordNbr = 0) THEN
            RETURN NEW;
        END IF;
        BEGIN
            -- Get code filter type
            SELECT INTO codeFilterType code_filter_type
            FROM gn_permissions.bib_filters_type 
            WHERE id_filter_type = NEW.id_filter_type ;

            RAISE EXCEPTION 'ATTENTION: il existe déjà % enregistrement avec : type de filtre % '
                ', role %, module %, action %, objet % et groupement %. Il est interdit de '
                'définir plusieurs fois le même type de filtre pour un même ensemble role, module, '
                'action, objet et groupement (=gathering).', 
                filterRecordNbr,
                codeFilterType, 
                NEW.id_role, 
                NEW.id_module, 
                NEW.id_action, 
                NEW.id_object,
                NEW.gathering ;
        END;
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100 ;

CREATE TRIGGER tri_check_no_multiple_filter_type 
    BEFORE INSERT OR UPDATE
    ON gn_permissions.cor_role_action_filter_module_object 
    FOR EACH ROW 
    EXECUTE PROCEDURE gn_permissions.fct_tri_only_one_filter_type_by_permission() ;

-- Remove old trigger and function (old names)
DROP TRIGGER IF EXISTS tri_check_no_multiple_scope_perm 
    ON gn_permissions.cor_role_action_filter_module_object ;

DROP FUNCTION IF EXISTS gn_permissions.fct_tri_does_user_have_already_scope_filter ;


-- -------------------------------------------------------------------------------------------------
-- Insert new permissions on ACCESS_REQUESTS object for ADMIN module for "group_admin"
-- CRU--D
-- C
INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (id_role, id_action, id_module, id_object, id_filter_type, value_filter)
    SELECT 
        9, 
        gn_permissions.get_id_action('C'), 
        gn_commons.get_id_module_bycode('ADMIN'), 
        gn_permissions.get_id_object('ACCESS_REQUESTS'), 
        gn_permissions.get_id_filter_type('SCOPE'), 
        '3'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_role_action_filter_module_object AS cor
        WHERE cor.id_role = 9
            AND cor.id_action = gn_permissions.get_id_action('C')
            AND cor.id_module = gn_commons.get_id_module_bycode('ADMIN')
            AND cor.id_object = gn_permissions.get_id_object('ACCESS_REQUESTS')
            AND cor.id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND cor.value_filter = '3'
    ) ;
-- R
INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (id_role, id_action, id_module, id_object, id_filter_type, value_filter)
    SELECT 
        9, 
        gn_permissions.get_id_action('R'), 
        gn_commons.get_id_module_bycode('ADMIN'), 
        gn_permissions.get_id_object('ACCESS_REQUESTS'), 
        gn_permissions.get_id_filter_type('SCOPE'), 
        '3'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_role_action_filter_module_object AS cor
        WHERE cor.id_role = 9
            AND cor.id_action = gn_permissions.get_id_action('R')
            AND cor.id_module = gn_commons.get_id_module_bycode('ADMIN')
            AND cor.id_object = gn_permissions.get_id_object('ACCESS_REQUESTS')
            AND cor.id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND cor.value_filter = '3'
    ) ;
-- U
INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (id_role, id_action, id_module, id_object, id_filter_type, value_filter)
    SELECT 
        9, 
        gn_permissions.get_id_action('U'), 
        gn_commons.get_id_module_bycode('ADMIN'), 
        gn_permissions.get_id_object('ACCESS_REQUESTS'), 
        gn_permissions.get_id_filter_type('SCOPE'), 
        '3'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_role_action_filter_module_object AS cor
        WHERE cor.id_role = 9
            AND cor.id_action = gn_permissions.get_id_action('U')
            AND cor.id_module = gn_commons.get_id_module_bycode('ADMIN')
            AND cor.id_object = gn_permissions.get_id_object('ACCESS_REQUESTS')
            AND cor.id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND cor.value_filter = '3'
    ) ;
-- D
INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (id_role, id_action, id_module, id_object, id_filter_type, value_filter)
    SELECT 
        9, 
        gn_permissions.get_id_action('D'), 
        gn_commons.get_id_module_bycode('ADMIN'), 
        gn_permissions.get_id_object('ACCESS_REQUESTS'), 
        gn_permissions.get_id_filter_type('SCOPE'), 
        '3'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_role_action_filter_module_object AS cor
        WHERE cor.id_role = 9
            AND cor.id_action = gn_permissions.get_id_action('D')
            AND cor.id_module = gn_commons.get_id_module_bycode('ADMIN')
            AND cor.id_object = gn_permissions.get_id_object('ACCESS_REQUESTS')
            AND cor.id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND cor.value_filter = '3'
    ) ;


-- -------------------------------------------------------------------------------------------------
-- Triggers and functions for unduplicate permissions
-- CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_check_upsert_no_duplicate_permissions()
--     RETURNS trigger AS
-- $BODY$
--     DECLARE
--     BEGIN
    
--     IF EXISTS (

--         FROM NEW AS updated_rows    
--     ) THEN
--         RETURN NULL ;
--     END;
-- $BODY$
-- LANGUAGE plpgsql VOLATILE
-- COST 100;

-- CREATE TRIGGER tri_check_insert_no_duplicate_permissions
--     BEFORE INSERT ON gn_permissions.cor_role_action_filter_module_object 
--     REFERENCING NEW TABLE AS NEW
--     FOR EACH STATEMENT
--     EXECUTE PROCEDURE gn_permissions.fct_tri_check_upsert_no_duplicate_permissions() ;

-- CREATE TRIGGER tri_check_update_no_duplicate_permissions
--     BEFORE UPDATE ON gn_permissions.cor_role_action_filter_module_object 
--     REFERENCING NEW TABLE AS NEW
--     FOR EACH STATEMENT
--     EXECUTE PROCEDURE gn_permissions.fct_tri_check_upsert_no_duplicate_permissions() ;

-- CREATE TRIGGER tri_check_update_no_duplicate_permissions
--     BEFORE DELETE ON gn_permissions.cor_role_action_filter_module_object 
--     REFERENCING OLD TABLE AS OLD
--     FOR EACH STATEMENT
--     EXECUTE PROCEDURE gn_permissions.fct_tri_check_delete_no_duplicate_permissions() ;


-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "cor_module_action_object_filter" primary key
DROP SEQUENCE IF EXISTS gn_permissions.cor_module_action_object_filter_id_permission_available_seq CASCADE ;

CREATE SEQUENCE gn_permissions.cor_module_action_object_filter_id_permission_available_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

COMMENT ON SEQUENCE gn_permissions.cor_module_action_object_filter_id_permission_available_seq IS 
    E'Auto-incrément de la clé primaire de la table cor_module_action_object_filter.' ;


-- -------------------------------------------------------------------------------------------------
-- Add new table "cor_module_action_object_filter" (AKA "t_permissions_available")
DROP TABLE IF EXISTS gn_permissions.cor_module_action_object_filter CASCADE ;

CREATE TABLE gn_permissions.cor_module_action_object_filter (
	id_permission_available integer NOT NULL DEFAULT nextval('gn_permissions.cor_module_action_object_filter_id_permission_available_seq'::regclass),
	id_module integer NOT NULL,
	id_action integer NOT NULL,
	id_object integer NOT NULL,
	id_filter_type integer NOT NULL,
    code varchar(200) NOT NULL,
    label varchar(250) NOT NULL,
    description text NULL,
    CONSTRAINT pk_cor_module_action_object_filter PRIMARY KEY (id_permission_available)
);

COMMENT ON TABLE gn_permissions.cor_module_action_object_filter IS 
	E'Contient les permissions implémentées au niveau du code des modules.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_permission_available IS 
	E'Identifiant auto-incrémenté d''une permission implémentée.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_module IS 
	E'Identifiant du module concerné par cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_action IS 
	E'Identifiant de l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_object IS 
	E'Identifiant de l''objet sur lequel s''applique l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_filter_type IS 
	E'Identifiant du filtre à appliquer à la permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.code IS 
	E'Code de la permission correspondant à la concaténation des codes (séparés par des tirets) '
     'du module, action, objet et type de filtre.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.label IS 
	E'Intitulé de la permission constitué du verbe (CRUVED) et du complément (object).\n'
     'Cette valeur sera identique pour toutes les lignes ayant les mêmes valeurs '
     'd''action et d''objet.\n'
     'Elle sert à nommer une permission quelque soit son filtre et son module.\n'
     'Ex.: Lire les observations privées';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.description IS 
	E'Description de la permission, de son cadre d''utilisation et des valeurs autorisées '
     'pour le filtre.';


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "cor_module_action_object_filter"
ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_module CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_action CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_action FOREIGN KEY (id_action)
	REFERENCES gn_permissions.t_actions (id_action) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_object CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_object FOREIGN KEY (id_object)
	REFERENCES gn_permissions.t_objects (id_object) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;

-- TODO: not used today. Remove ?
-- ALTER TABLE gn_permissions.cor_module_action_object_filter
-- 	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_filter_value CASCADE ;

-- ALTER TABLE gn_permissions.cor_module_action_object_filter
-- 	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_value FOREIGN KEY (id_filter_value)
-- 	REFERENCES gn_permissions.bib_filters_values (id_filter_value) MATCH FULL
-- 	ON UPDATE CASCADE ;

-- -------------------------------------------------------------------------------------------------
-- UNIQUE INDEXES

-- bib_filters_type
DROP INDEX IF EXISTS gn_permissions.unique_bib_filters_type_code ;

CREATE UNIQUE INDEX unique_bib_filters_type_code ON gn_permissions.bib_filters_type
    USING btree(UPPER(code_filter_type)) ;


-- bib_filters_values
DROP INDEX IF EXISTS gn_permissions.unique_bib_filters_values ;

CREATE UNIQUE INDEX unique_bib_filters_values ON gn_permissions.bib_filters_values 
    USING btree(id_filter_type, UPPER(value_or_field)) ;


-- cor_module_action_object_filter
DROP INDEX IF EXISTS gn_permissions.unique_cor_m_a_o_f_ids ;

CREATE UNIQUE INDEX unique_cor_m_a_o_f_ids ON gn_permissions.cor_module_action_object_filter 
    USING btree(id_module, id_action, id_object, id_filter_type) ;

DROP INDEX IF EXISTS gn_permissions.unique_cor_m_a_o_f_code ;

CREATE UNIQUE INDEX unique_cor_m_a_o_f_code ON gn_permissions.cor_module_action_object_filter 
    USING btree(UPPER(code)) ;


-- t_actions
DROP INDEX IF EXISTS gn_permissions.unique_t_actions_code ;

CREATE UNIQUE INDEX unique_t_actions_code ON gn_permissions.t_actions 
    USING btree(UPPER(code_action)) ;


-- t_objects
DROP INDEX IF EXISTS gn_permissions.unique_t_objects_code ;

CREATE UNIQUE INDEX unique_t_objects_code ON gn_permissions.t_objects 
    USING btree(UPPER(code_object)) ;



-- -------------------------------------------------------------------------------------------------
-- Build view "v_roles_permissions"
CREATE VIEW gn_permissions.v_roles_permissions
AS WITH 
    -- Get users permissions
    p_user_permission AS (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            NULL AS group_name,
            c_1.id_permission,
            c_1.id_module,
            c_1.id_action,
            c_1.id_object,
            c_1.gathering,
            c_1.end_date,
            c_1.id_filter_type,
            c_1.value_filter
        FROM utilisateurs.t_roles AS u 
            JOIN gn_permissions.cor_role_action_filter_module_object AS c_1 
                ON (c_1.id_role = u.id_role)
        WHERE u.groupe = false
    ),
    -- Get permissions of groups AND the user permissions inherited from his group(s)
    -- WARNING : get permissions from groups only if they have users
    p_groupe_permission AS (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            TRIM(TRAILING FROM CONCAT(grp.nom_role, ' ', grp.prenom_role)) AS group_name,
            c_1.id_permission,
            c_1.id_module,
            c_1.id_action,
            c_1.id_object,
            c_1.gathering,
            c_1.end_date,
            c_1.id_filter_type,
            c_1.value_filter
        FROM utilisateurs.t_roles AS u 
            JOIN utilisateurs.cor_roles AS g 
                ON (g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role)
            JOIN utilisateurs.t_roles AS grp 
                ON (g.id_role_groupe = grp.id_role)
            JOIN gn_permissions.cor_role_action_filter_module_object AS c_1 
                ON (c_1.id_role = g.id_role_groupe)
    ), 
    all_user_permission AS (
        -- UNION operator removes all duplicate rows from the combined data set
        SELECT p_user_permission.id_role,
            p_user_permission.nom_role,
            p_user_permission.prenom_role,
            p_user_permission.groupe,
            p_user_permission.id_organisme,
            p_user_permission.group_name,
            p_user_permission.id_permission,
            p_user_permission.id_module,
            p_user_permission.id_action,
            p_user_permission.id_object,
            p_user_permission.gathering,
            p_user_permission.end_date,
            p_user_permission.id_filter_type,
            p_user_permission.value_filter
        FROM p_user_permission
        UNION
        SELECT p_groupe_permission.id_role,
            p_groupe_permission.nom_role,
            p_groupe_permission.prenom_role,
            p_groupe_permission.groupe,
            p_groupe_permission.id_organisme,
            p_groupe_permission.group_name,
            p_groupe_permission.id_permission,
            p_groupe_permission.id_module,
            p_groupe_permission.id_action,
            p_groupe_permission.id_object,
            p_groupe_permission.gathering,
            p_groupe_permission.end_date,
            p_groupe_permission.id_filter_type,
            p_groupe_permission.value_filter
        FROM p_groupe_permission
    )
SELECT v.id_role,
    v.nom_role,
    v.prenom_role,
    v.groupe,
    v.id_organisme,
    v.group_name,
    perm_available.label AS permission_label,
    perm_available.code AS permission_code,
    v.id_module,
    modules.module_code,
    v.id_action,
    actions.code_action,
    actions.description_action,
    obj.code_object,
    v.id_filter_type,
    v.value_filter,
    filter_type.code_filter_type,
    v.gathering,
    v.end_date,
    v.id_permission
FROM all_user_permission AS v
    JOIN gn_permissions.t_actions AS actions 
        ON (actions.id_action = v.id_action)
    JOIN gn_permissions.t_objects AS obj 
        ON (obj.id_object = v.id_object)
    JOIN gn_permissions.bib_filters_type AS filter_type 
        ON (v.id_filter_type = filter_type.id_filter_type)
    JOIN gn_commons.t_modules AS modules 
        ON (modules.id_module = v.id_module)
    LEFT JOIN gn_permissions.cor_module_action_object_filter AS perm_available
        ON (
            v.id_module = perm_available.id_module
            AND v.id_action = perm_available.id_action
            AND v.id_object = perm_available.id_object
            AND v.id_filter_type = perm_available.id_filter_type
        )
-- TODO: check performance issues with order by
ORDER BY nom_role, prenom_role, module_code, gathering, id_action, code_object, code_filter_type, end_date ;



-- -------------------------------------------------------------------------------------------------
-- Helper query to see all distinct permissions used
--
-- SELECT DISTINCT crafmo.id_module, crafmo.id_action, tm.module_code, ta.code_action, to2.code_object, bft.code_filter_type 
-- FROM gn_permissions.cor_role_action_filter_module_object AS crafmo
-- 	JOIN gn_commons.t_modules AS tm  ON crafmo.id_module = tm.id_module 
-- 	JOIN gn_permissions.t_actions AS ta ON crafmo.id_action = ta.id_action 
-- 	JOIN gn_permissions.t_objects AS to2 ON crafmo.id_object = to2.id_object 
-- 	JOIN gn_permissions.bib_filters_type AS bft ON crafmo.id_filter_type = bft.id_filter_type 
-- ORDER BY crafmo.id_module, crafmo.id_action ;


-- -------------------------------------------------------------------------------------------------
-- Insert data into permissions available table

-- GEONATURE - ALL - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans GeoNature en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-R-ALL-SCOPE',
        'Lire les données',
        'Lire les données dans GeoNature limitées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-U-ALL-SCOPE',
        'Mettre à jour des données',
        'Mettre à jour des données dans GeoNature en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-U-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('V'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-V-ALL-SCOPE',
        'Valider des données',
        'Valider des données dans GeoNature en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-V-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans GeoNature en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans GeoNature en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-D-ALL-SCOPE'
    ) ;

-- ----------------------------------------------------------------------
-- ADMIN - C - ALL,NOMENCLATURES,PERMISSIONS,ACCESS_REQUESTS - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-NOMENCLATURES-SCOPE',
        'Créer des nomenclatures',
        'Créer des nomenclatures dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-PERMISSIONS-SCOPE',
        'Créer des permissions',
        'Créer des permissions dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-PERMISSIONS-SCOPE'
    ) ;

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('C'),
--         gn_permissions.get_id_object('ACCESS_REQUESTS'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-C-ACCESS_REQUESTS-SCOPE',
--         'Créer des demandes d''accès',
--         'Créer des demandes d''accès dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-C-ACCESS_REQUESTS-SCOPE'
--     ) ;

-- ADMIN - R - ALL,NOMENCLATURES,PERMISSIONS,ACCESS_REQUESTS - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-ALL-SCOPE',
        'Lire des données',
        'Lire des données dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-NOMENCLATURES-SCOPE',
        'Lire des nomenclatures',
        'Lire des nomenclatures dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-PERMISSIONS-SCOPE',
        'Lire des permissions',
        'Lire des permissions dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ACCESS_REQUESTS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-ACCESS_REQUESTS-SCOPE',
        'Lire des demandes d''accès',
        'Lire des demandes d''accès dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-ACCESS_REQUESTS-SCOPE'
    ) ;

-- ADMIN - U - ALL,NOMENCLATURES,PERMISSIONS,ACCESS_REQUESTS - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-ALL-SCOPE',
        'Mettre à jour des données',
        'Mettre à jour des données dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-NOMENCLATURES-SCOPE',
        'Mettre à jour des nomenclatures',
        'Mettre à jour des nomenclatures dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-PERMISSIONS-SCOPE',
        'Mettre à jour des permissions',
        'Mettre à jour des permissions dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ACCESS_REQUESTS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-ACCESS_REQUESTS-SCOPE',
        'Mettre à jour des demandes d''accès',
        'Mettre à jour des demandes d''accès dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-ACCESS_REQUESTS-SCOPE'
    ) ;

-- ADMIN - V - ALL,NOMENCLATURES,PERMISSIONS,ACCESS_REQUESTS - SCOPE
-- ADMIN-V-ALL-SCOPE : not used !
-- ADMIN-V-NOMENCLATURES-SCOPE : not used !
-- ADMIN-V-PERMISSIONS-SCOPE : not used !
-- ADMIN-V-ACCESS_REQUESTS-SCOPE : not used !

-- ADMIN - E - ALL,NOMENCLATURES,PERMISSIONS,ACCESS_REQUESTS - SCOPE
-- ADMIN-E-ALL-SCOPE : not used !
-- ADMIN-E-NOMENCLATURES-SCOPE : not used !
-- ADMIN-E-PERMISSIONS-SCOPE : not used !
-- ADMIN-E-ACCESS_REQUESTS-SCOPE : not used !
-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('E'),
--         gn_permissions.get_id_object('ALL'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-E-ALL-SCOPE',
--         'Exporter des données',
--         'Exporter des données dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-E-ALL-SCOPE'
--     ) ;

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('E'),
--         gn_permissions.get_id_object('NOMENCLATURES'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-E-NOMENCLATURES-SCOPE',
--         'Exporter des nomenclatures',
--         'Exporter des nomenclatures dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-E-NOMENCLATURES-SCOPE'
--     ) ;

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('E'),
--         gn_permissions.get_id_object('PERMISSIONS'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-E-PERMISSIONS-SCOPE',
--         'Exporter des permissions',
--         'Exporter des permissions dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-E-PERMISSIONS-SCOPE'
--     ) ;

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('E'),
--         gn_permissions.get_id_object('ACCESS_REQUESTS'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-E-ACCESS_REQUESTS-SCOPE',
--         'Exporter des demandes d''accès',
--         'Exporter des demandes d''accès dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-E-ACCESS_REQUESTS-SCOPE'
--     ) ;

-- ADMIN - D - ALL,NOMENCLATURES,PERMISSIONS - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-NOMENCLATURES-SCOPE',
        'Supprimer des nomenclatures',
        'Supprimer des nomenclatures dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-PERMISSIONS-SCOPE',
        'Supprimer des permissions',
        'Supprimer des permissions dans le module Admin en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-PERMISSIONS-SCOPE'
    ) ;

-- ADMIN-D-ACCESS_REQUESTS-SCOPE : not used !
-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('ADMIN'),
--         gn_permissions.get_id_action('D'),
--         gn_permissions.get_id_object('ACCESS_REQUESTS'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'ADMIN-D-ACCESS_REQUESTS-SCOPE',
--         'Supprimer des demandes d''accès',
--         'Supprimer des demandes d''accès dans le module Admin en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'ADMIN-D-ACCESS_REQUESTS-SCOPE'
--     ) ;

-- ----------------------------------------------------------------------
-- METADATA - CR--ED - ALL - SCOPE

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans le module Métadonnées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-R-ALL-SCOPE',
        'Lire les données',
        'Lire les données dans le module Métadonnées limitées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-R-ALL-SCOPE'
    ) ;

-- METADATA-U-ALL-SCOPE : not used !
-- METADATA-V-ALL-SCOPE : not used !

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('METADATA'),
--         gn_permissions.get_id_action('U'),
--         gn_permissions.get_id_object('ALL'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'METADATA-U-ALL-SCOPE',
--         'Mettre à jour des données',
--         'Mettre à jour des données dans le module Métadonnées en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'METADATA-U-ALL-SCOPE'
--     ) ;

-- INSERT INTO gn_permissions.cor_module_action_object_filter (
--     id_module, id_action, id_object, id_filter_type, code, label, description
-- ) 
--     SELECT
--         gn_commons.get_id_module_bycode('METADATA'),
--         gn_permissions.get_id_action('V'),
--         gn_permissions.get_id_object('ALL'),
--         gn_permissions.get_id_filter_type('SCOPE'),
--         'METADATA-V-ALL-SCOPE',
--         'Valider des données',
--         'Valider des données dans le module Métadonnées en étant limité par l''appartenance.'
--     WHERE NOT EXISTS (
--         SELECT 'X'
--         FROM gn_permissions.cor_module_action_object_filter AS cmaof
--         WHERE cmaof.code = 'METADATA-V-ALL-SCOPE'
--     ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans le module Métadonnées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans le module Métadonnées en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-D-ALL-SCOPE'
    ) ;

-- ----------------------------------------------------------------------
-- SYNTHESE - R - ALL - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-ALL-SCOPE',
        'Lire des données',
        'Lire des données dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-TAXONOMIC-SCOPE',
        'Lire des données',
        'Lire des données dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-ALL-TAXONOMIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-R-GEOGRAPHIC-SCOPE',
        'Lire des données',
        'Lire des données dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-ALL-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-R-PRECISION-SCOPE',
        'Lire des données',
        'Lire des données dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-ALL-PRECISION'
    ) ;

-- ----------------------------------------------------------------------
-- SYNTHESE - E - ALL - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-E-ALL-TAXONOMIC',
        'Exporter des données',
        'Exporter des données dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-ALL-TAXONOMIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-E-ALL-GEOGRAPHIC',
        'Exporter des données',
        'Exporter des données dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-ALL-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-E-ALL-PRECISION',
        'Exporter des données',
        'Exporter des données dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-ALL-PRECISION'
    ) ;

-- ----------------------------------------------------------------------
-- SYNTHESE - R - PRIVATE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-PRECISION',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-SCOPE',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-TAXONOMIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-TAXONOMIC'
    ) ;

-- ----------------------------------------------------------------------
-- SYNTHESE - E - PRIVATE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-PRECISION',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-SCOPE',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-GEOGRAPHIC',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-TAXONOMIC',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-TAXONOMIC'
    ) ;

-- ----------------------------------------------------------------------
-- SYNTHESE - R - SENSITIVE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-PRECISION',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-SCOPE',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-TAXONOMIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
-- SYNTHESE - E - SENSITIVE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-PRECISION',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-SCOPE',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-GEOGRAPHIC',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-TAXONOMIC',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-TAXONOMIC'
    ) ;

DO
$$
BEGIN
    RAISE NOTICE 'Add Validation available permissions if module installed' ;

    IF EXISTS (SELECT 1 FROM gn_commons.t_modules WHERE UPPER(module_code) = 'VALIDATION') THEN
        RAISE NOTICE 'Validation module installed - Adding available permissions...' ;

        -- ----------------------------------------------------------------------
        -- VALIDATION - C - ALL - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-C-ALL-PRECISION',
                'Créer des données',
                'Créer des données dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-ALL-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-C-ALL-SCOPE',
                'Créer des données',
                'Créer des données dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-C-ALL-GEOGRAPHIC',
                'Créer des données',
                'Créer des données dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-ALL-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-C-ALL-TAXONOMIC',
                'Créer des données',
                'Créer des données dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-ALL-TAXONOMIC'
            ) ;

        -- ----------------------------------------------------------------------
        -- VALIDATION - R - ALL - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-R-ALL-PRECISION',
                'Lire des données',
                'Lire des données dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-ALL-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-R-ALL-SCOPE',
                'Lire des données',
                'Lire des données dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-R-ALL-GEOGRAPHIC',
                'Lire des données',
                'Lire des données dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-ALL-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-R-ALL-TAXONOMIC',
                'Lire des données',
                'Lire des données dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-ALL-TAXONOMIC'
            ) ;

        -- ----------------------------------------------------------------------
        -- VALIDATION - C - PRIVATE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-C-PRIVATE_OBSERVATION-PRECISION',
                'Créer des observations privées',
                'Créer des observations privées dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-PRIVATE_OBSERVATION-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-C-PRIVATE_OBSERVATION-SCOPE',
                'Créer des observations privées',
                'Créer des observations privées dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-PRIVATE_OBSERVATION-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-C-PRIVATE_OBSERVATION-GEOGRAPHIC',
                'Créer des observations privées',
                'Créer des observations privées dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-PRIVATE_OBSERVATION-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-C-PRIVATE_OBSERVATION-TAXONOMIC',
                'Créer des observations privées',
                'Créer des observations privées dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-PRIVATE_OBSERVATION-TAXONOMIC'
            ) ;


        -- ----------------------------------------------------------------------
        -- VALIDATION - R - PRIVATE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-R-PRIVATE_OBSERVATION-PRECISION',
                'Lire des observations privées',
                'Lire des observations privées dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-R-PRIVATE_OBSERVATION-SCOPE',
                'Lire des observations privées',
                'Lire des observations privées dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-R-PRIVATE_OBSERVATION-GEOGRAPHIC',
                'Lire des observations privées',
                'Lire des observations privées dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-R-PRIVATE_OBSERVATION-TAXONOMIC',
                'Lire des observations privées',
                'Lire des observations privées dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-TAXONOMIC'
            ) ;

        -- ----------------------------------------------------------------------
        -- VALIDATION - C - SENSITIVE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-C-SENSITIVE_OBSERVATION-PRECISION',
                'Créer des observations sensibles',
                'Créer des observations sensibles dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-SENSITIVE_OBSERVATION-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-C-SENSITIVE_OBSERVATION-SCOPE',
                'Créer des observations sensibles',
                'Créer des observations sensibles dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-SENSITIVE_OBSERVATION-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-C-SENSITIVE_OBSERVATION-GEOGRAPHIC',
                'Créer des observations sensibles',
                'Créer des observations sensibles dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-SENSITIVE_OBSERVATION-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-C-SENSITIVE_OBSERVATION-TAXONOMIC',
                'Créer des observations sensibles',
                'Créer des observations sensibles dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-C-SENSITIVE_OBSERVATION-TAXONOMIC'
            ) ;

        -- ----------------------------------------------------------------------
        -- VALIDATION - R - SENSITIVE_OBSERVATION - SCOPE,TAXONOMIC,GEOGRAPHIC,PRECISION
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('PRECISION'),
                'VALIDATION-R-SENSITIVE_OBSERVATION-PRECISION',
                'Lire des observations sensibles',
                'Lire des observations sensibles dans le module Validation en étant limité par la précision.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-PRECISION'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'VALIDATION-R-SENSITIVE_OBSERVATION-SCOPE',
                'Lire des observations sensibles',
                'Lire des observations sensibles dans le module Validation en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('GEOGRAPHIC'),
                'VALIDATION-R-SENSITIVE_OBSERVATION-GEOGRAPHIC',
                'Lire des observations sensibles',
                'Lire des observations sensibles dans le module Validation en étant limité par zones géographiques.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-GEOGRAPHIC'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('VALIDATION'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
                gn_permissions.get_id_filter_type('TAXONOMIC'),
                'VALIDATION-R-SENSITIVE_OBSERVATION-TAXONOMIC',
                'Lire des observations sensibles',
                'Lire des observations sensibles dans le module Validation en étant limité par des taxons.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-TAXONOMIC'
            ) ;
    ELSE
        RAISE NOTICE 'Validation module NOT installed.' ;
    END IF;
END ;
$$ ;

-- ----------------------------------------------------------------------
-- OCCTAX - CRU-ED - ALL - SCOPE
DO
$$
BEGIN
    RAISE NOTICE 'Add OccTax available permissions if module installed' ;

    IF EXISTS (SELECT 1 FROM gn_commons.t_modules WHERE UPPER(module_code) = 'OCCTAX') THEN
        RAISE NOTICE 'OccTax module installed - Adding available permissions...' ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('OCCTAX'),
                gn_permissions.get_id_action('C'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'OCCTAX-C-ALL-SCOPE',
                'Créer des données',
                'Créer des données dans OccTax en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'OCCTAX-C-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('OCCTAX'),
                gn_permissions.get_id_action('R'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'OCCTAX-R-ALL-SCOPE',
                'Lire les données',
                'Lire les données dans OccTax limitées en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'OCCTAX-R-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('OCCTAX'),
                gn_permissions.get_id_action('U'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'OCCTAX-U-ALL-SCOPE',
                'Mettre à jour des données',
                'Mettre à jour des données dans OccTax en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'OCCTAX-U-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('OCCTAX'),
                gn_permissions.get_id_action('E'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'OCCTAX-E-ALL-SCOPE',
                'Exporter des données',
                'Exporter des données dans OccTax en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'OCCTAX-E-ALL-SCOPE'
            ) ;

        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) 
            SELECT
                gn_commons.get_id_module_bycode('OCCTAX'),
                gn_permissions.get_id_action('D'),
                gn_permissions.get_id_object('ALL'),
                gn_permissions.get_id_filter_type('SCOPE'),
                'OCCTAX-D-ALL-SCOPE',
                'Supprimer des données',
                'Supprimer des données dans OccTax en étant limité par l''appartenance.'
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_permissions.cor_module_action_object_filter AS cmaof
                WHERE cmaof.code = 'OCCTAX-D-ALL-SCOPE'
            ) ;
    ELSE
        RAISE NOTICE 'OccTax module NOT installed.' ;
    END IF;
END ;
$$ ;

-- ----------------------------------------------------------------------
-- OCCHAB - CR--ED - ALL - SCOPE
DO
$$
BEGIN
    RAISE NOTICE 'Add OccHab available permissions if module installed' ;

    IF EXISTS (SELECT 1 FROM gn_commons.t_modules WHERE UPPER(module_code) = 'OCCHAB') THEN
        RAISE NOTICE 'OccHab module installed - Adding available permissions...' ;

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
    ELSE
        RAISE NOTICE 'OccHab module NOT installed.' ;
    END IF;
END ;
$$ ;


-- -------------------------------------------------------------------------------------------------
-- Remove table "t_filters"
DROP TABLE IF EXISTS gn_permissions.t_filters ;


-- -------------------------------------------------------------------------------------------------
-- Remove table "cor_object_module"
DROP TABLE IF EXISTS gn_permissions.cor_object_module ;


-- -------------------------------------------------------------------------------------------------
-- Remove table "cor_filter_type_module"
DROP TABLE IF EXISTS gn_permissions.cor_filter_type_module ;


COMMIT ;
