SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- DROP SCHEMA gn_permissions CASCADE;
CREATE SCHEMA gn_permissions;

SET search_path = gn_permissions, pg_catalog;
SET default_with_oids = false;

-- -------------------------------------------------------------------------------------------------
-- FUNCTIONS

CREATE OR REPLACE FUNCTION does_user_have_scope_permission(
    userId integer,
    moduleCode character varying,
    actionCode character varying,
    filterValue integer
)
    RETURNS boolean 
AS $BODY$
    -- The function say if the given user can do the requested action in 
    -- the requested module with its property level (=SCOPE).
    -- WARNING: NO heritage between parent and child module.
    -- USAGE: SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
    -- SAMPLE: SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
    BEGIN
        IF actionCode IN (
            SELECT code_action
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = userId 
                AND module_code = moduleCode 
                AND code_action = actionCode 
                AND value_filter::int >= filterValue 
                AND code_filter_type = 'SCOPE'
        ) THEN
            RETURN true;
        END IF;
        RETURN false;
    END;
$BODY$
LANGUAGE plpgsql IMMUTABLE
COST 100 ;


CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module(
    userId integer,
    actionCode character varying,
    moduleCode character varying
)
    RETURNS integer 
AS $BODY$
    DECLARE
        maxPropertyLevel integer;

    -- The function return the max accessible extend of data the given user can access in the requested module
    -- warning: NO inheritance between parent and child module
    -- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
    -- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
    BEGIN
        SELECT max(value_filter::int) INTO maxPropertyLevel
        FROM gn_permissions.v_roles_permissions
        WHERE id_role = userId 
            AND module_code = moduleCode 
            AND code_action = actionCode
            AND code_filter_type = 'SCOPE' ;
        RETURN maxPropertyLevel;
    END;
$BODY$
LANGUAGE plpgsql IMMUTABLE
COST 100 ;


CREATE OR REPLACE FUNCTION cruved_for_user_in_module(
    userId integer,
    moduleCode character varying
)
    RETURNS json 
AS $BODY$
    -- The function return user's CRUVED in the requested module
    -- WARNING: the function not return the parent CRUVED but only the module CRUVED - no inheritance.
    -- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
    -- SAMPLE : SELECT utilisateurs.cruved_for_user_in_module(2,3);
    DECLARE
        cruved json;
    BEGIN
        SELECT array_to_json(array_agg(row)) INTO cruved
        FROM (
            SELECT code_action AS action, max(value_filter::int) AS level
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = userId 
                AND module_code = moduleCode 
                AND code_filter_type = 'SCOPE'
            GROUP BY code_action
        ) AS row;
        RETURN cruved;
    END;
$BODY$
LANGUAGE plpgsql IMMUTABLE
COST 100 ;


CREATE OR REPLACE FUNCTION gn_permissions.get_id_action(actionCode character varying)
    RETURNS integer
AS $BODY$
    -- Function to get action id by code
    BEGIN
        RETURN (
            SELECT id_action
            FROM gn_permissions.t_actions
            WHERE code_action = actionCode
        );
    END;
$BODY$ 
LANGUAGE plpgsql IMMUTABLE 
COST 100 ;


CREATE OR REPLACE FUNCTION gn_permissions.get_id_filter_type(filterTypeCode character varying)
    RETURNS integer
AS $BODY$
    -- Function to get filter_type id by code
    BEGIN
        RETURN (
            SELECT id_filter_type
            FROM gn_permissions.bib_filters_type
            WHERE code_filter_type = filterTypeCode
        );
    END;
$BODY$ 
LANGUAGE plpgsql IMMUTABLE 
COST 100 ;


CREATE OR REPLACE FUNCTION gn_permissions.get_id_object(objectCode character varying)
    RETURNS integer 
AS $BODY$
    -- Function to get object id by code
    BEGIN
        RETURN (
            SELECT id_object
            FROM gn_permissions.t_objects
            WHERE code_object = objectCode
        );
    END;
$BODY$
LANGUAGE plpgsql IMMUTABLE
COST 100 ;


-- Function for trigger to force only one filter type by permission (gathering)
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

-- Function for trigger to update column "meta_update_date"
CREATE OR REPLACE FUNCTION gn_permissions.tri_func_modify_meta_update_date()
    RETURNS trigger
    LANGUAGE plpgsql
AS $BODY$
    BEGIN
        NEW.meta_update_date := now();
        RETURN NEW;
    END;
$BODY$ ;

-- -------------------------------------------------------------------------------------------------
-- SEQUENCES

-- Add sequence for new table "bib_filters_values" primary key
CREATE SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

COMMENT ON SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq IS 
    E'Auto-incrément de la clé primaire de la table bib_filters_values.' ;

-- Add sequence for new table "t_requests" primary key
CREATE SEQUENCE gn_permissions.t_requests_id_request_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

COMMENT ON SEQUENCE gn_permissions.t_requests_id_request_seq IS 
    E'Auto-incrément de la clé primaire de la table t_requests.' ;

-- Add sequence for new table "cor_module_action_object_filter" primary key
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
-- ENUM 

-- Enum for table "bib_filters_values"
CREATE TYPE filter_value_formats AS ENUM ('string', 'integer', 'boolean', 'geometry', 'csvint') ;

-- Enum for table "t_requests"
CREATE TYPE request_states AS ENUM ('pending', 'refused', 'accepted') ;

-- -------------------------------------------------------------------------------------------------
-- TABLES

CREATE TABLE t_actions (
    id_action serial NOT NULL,
    code_action character varying(50) NOT NULL,
    description_action text
);

CREATE TABLE bib_filters_type (
    id_filter_type serial NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    label_filter_type character varying(255) NOT NULL,
    description_filter_type text
);


CREATE TABLE t_objects (
    id_object serial NOT NULL,
    code_object character varying(50) NOT NULL,
    description_object text
);


CREATE TABLE cor_role_action_filter_module_object (
    id_permission serial NOT NULL,
    id_role integer NOT NULL,
    id_module integer NOT NULL,
    id_action integer NOT NULL,
    id_object integer NOT NULL DEFAULT gn_permissions.get_id_object('ALL'),
    gathering uuid DEFAULT public.uuid_generate_v4(),
    end_date timestamp NULL,
    id_filter_type int4 NOT NULL,
    -- TODO: not used today. Remove ? See if really usefull or not !
    -- id_filter_value int4 NULL,
    value_filter text NOT NULL,
    id_request int4 NULL 
);

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

-- Add new table "cor_module_action_object_filter" (AKA "t_permissions_available")
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

-- Table "cor_role_action_filter_module_object"
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

-- Table "bib_filters_values"
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

-- Table "t_requests"
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

-- Table "cor_module_action_object_filter"
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
-- PRIMARY KEY

ALTER TABLE ONLY t_actions
    ADD CONSTRAINT pk_t_actions 
    PRIMARY KEY (id_action);

ALTER TABLE ONLY bib_filters_type
    ADD CONSTRAINT pk_bib_filters_type 
    PRIMARY KEY (id_filter_type);

ALTER TABLE ONLY t_objects
    ADD CONSTRAINT pk_t_objects 
    PRIMARY KEY (id_object);

ALTER TABLE ONLY cor_role_action_filter_module_object
    ADD CONSTRAINT pk_cor_r_a_f_m_o 
    PRIMARY KEY (id_permission) ;


-- -------------------------------------------------------------------------------------------------
-- FOREIGN KEY

ALTER TABLE ONLY cor_role_action_filter_module_object
    ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_role FOREIGN KEY (id_role) 
    REFERENCES utilisateurs.t_roles (id_role) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE ONLY cor_role_action_filter_module_object
    ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_action FOREIGN KEY (id_action) 
    REFERENCES t_actions (id_action) 
    ON UPDATE CASCADE ;

ALTER TABLE ONLY cor_role_action_filter_module_object
    ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_object FOREIGN KEY (id_object) 
    REFERENCES t_objects (id_object) 
    ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_request FOREIGN KEY (id_request)
	REFERENCES gn_permissions.t_requests (id_request) MATCH FULL
	ON UPDATE CASCADE ;

-- Constraints for table "bib_filters_values"
ALTER TABLE gn_permissions.bib_filters_values 
    ADD CONSTRAINT fk_bib_filters_values_id_filter_type FOREIGN KEY (id_filter_type)
    REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
    ON UPDATE CASCADE ;

-- Constraints for table "t_requests"
ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_id_role FOREIGN KEY (id_role)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_processed_by FOREIGN KEY (processed_by)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;

-- Constraints for table "cor_module_action_object_filter"
ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_action FOREIGN KEY (id_action)
	REFERENCES gn_permissions.t_actions (id_action) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_object FOREIGN KEY (id_object)
	REFERENCES gn_permissions.t_objects (id_object) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;

-- TODO: not used today. Remove ?
-- ALTER TABLE gn_permissions.cor_module_action_object_filter
-- 	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_value FOREIGN KEY (id_filter_value)
-- 	REFERENCES gn_permissions.bib_filters_values (id_filter_value) MATCH FULL
-- 	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- UNIQUE INDEXES

-- bib_filters_type
CREATE UNIQUE INDEX unique_bib_filters_type_code ON gn_permissions.bib_filters_type 
    USING btree(UPPER(code_filter_type)) ;

-- bib_filters_values
CREATE UNIQUE INDEX unique_bib_filters_values ON gn_permissions.bib_filters_values  
    USING btree(id_filter_type, UPPER(value_or_field)) ;

-- cor_module_action_object_filter
CREATE UNIQUE INDEX unique_cor_m_a_o_f_ids ON gn_permissions.cor_module_action_object_filter 
    USING btree(id_module, id_action, id_object, id_filter_type);

CREATE UNIQUE INDEX unique_cor_m_a_o_f_code ON gn_permissions.cor_module_action_object_filter 
    USING btree(UPPER(code));

-- t_actions
CREATE UNIQUE INDEX unique_t_actions_code ON gn_permissions.t_actions 
    USING btree(UPPER(code_action)) ;

-- t_objects
CREATE UNIQUE INDEX unique_t_objects_code ON gn_permissions.t_objects 
    USING btree(UPPER(code_object)) ;

-- -------------------------------------------------------------------------------------------------
-- VIEWS

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
-- TRIGGERS 

CREATE TRIGGER tri_check_no_multiple_filter_type 
    BEFORE INSERT OR UPDATE
    ON gn_permissions.cor_role_action_filter_module_object 
    FOR EACH ROW 
    EXECUTE PROCEDURE gn_permissions.fct_tri_only_one_filter_type_by_permission() ;

CREATE TRIGGER tri_modify_meta_update_date_t_requests
    AFTER UPDATE
    ON gn_permissions.t_requests
    FOR EACH ROW
        EXECUTE PROCEDURE gn_permissions.tri_func_modify_meta_update_date();
