SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = gn_permissions, pg_catalog;
SET default_with_oids = false;


-- -------------------------------------------------------------------------------------------------
-- Add filters types
INSERT INTO bib_filters_type
    (code_filter_type, label_filter_type, description_filter_type)
VALUES
    (
        'SCOPE', 
        'Filtre d''appartenance', 
        E'Permissions limitées par le type d''appartenances des données.\n'
            'Accès à : aucune (=0), les miennes (=1), celles de mon organisme (=2), toutes (=3).'
    ),
    (
        'PRECISION', 
        'Filtre de précision', 
        'Active (=fuzzy) ou désactive (=exact) le floutage des données (sensibles ou privées).'
    ),
    (
        'GEOGRAPHIC', 
        'Filtre géographique', 
        E'Permissions limitées par zones géographiques.\n'
            'Utiliser des id_area séparés par des virgules.'
    ),
    (
        'TAXONOMIC', 
        'Filtre taxonomique', 
        E'Permissions limitées par des taxons.\n'
            'Utiliser des cd_nom séparés par des virgules.'
    )
;


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
-- Add actions (=CRUVED)
INSERT INTO t_actions
    (code_action, description_action)
VALUES
    ('C', 'Créer (C)'),
    ('R', 'Lire (R)'),
    ('U', 'Mettre à jour (U)'),
    ('V', 'Valider (V)'),
    ('E', 'Exporter (E)'),
    ('D', 'Supprimer (D)')
;


-- -------------------------------------------------------------------------------------------------
-- Add objects
INSERT INTO t_objects
    (code_object, description_object)
VALUES
    ('ALL', 'Représente tous les objets d''un module'),
    ('PERMISSIONS', 'Gestion des permissions'),
    ('NOMENCLATURES', 'Gestion du backoffice des nomenclatures'),
    ('ACCESS_REQUESTS', 'Gestion des demandes de permissions d''accès'),
    ('PRIVATE_OBSERVATION', 'Observation privée'),
    ('SENSITIVE_OBSERVATION', 'Observation senssible')
;


-- -------------------------------------------------------------------------------------------------
-- Add default permissions
INSERT INTO cor_role_action_filter_module_object
    (id_role, id_action, id_module, id_object, id_filter_type, value_filter)
VALUES
    -- "Groupe admin" a tous les droits sur GEONATURE
    (9, 1, 0, 1, 1, 3),
    (9, 2, 0, 1, 1, 3),
    (9, 3, 0, 1, 1, 3),
    (9, 4, 0, 1, 1, 3),
    (9, 5, 0, 1, 1, 3),
    (9, 6, 0, 1, 1, 3),
    --Validateur général sur tout GEONATURE
    (5, 4, 0, 1, 1, 3),
    --CRUVED du groupe en poste (id=7) sur tout GEONATURE 
    (7, 1, 0, 1, 1, 3),
    (7, 2, 0, 1, 1, 2),
    (7, 3, 0, 1, 1, 1),
    (7, 4, 0, 1, 1, 0),
    (7, 5, 0, 1, 1, 2),
    (7, 6, 0, 1, 1, 1),
    -- "Groupe admin" a tous les droit dans METADATA
    (9, 1, 2, 1, 1, 3),
    (9, 2, 2, 1, 1, 3),
    (9, 3, 2, 1, 1, 3),
    (9, 4, 2, 1, 1, 3),
    (9, 5, 2, 1, 1, 3),
    (9, 6, 2, 1, 1, 3),
    -- "Groupe en poste" acces limité à METADATA
    (7, 1, 2, 1, 1, 0),
    (7, 2, 2, 1, 1, 2),
    (7, 3, 2, 1, 1, 0),
    (7, 4, 2, 1, 1, 0),
    (7, 5, 2, 1, 1, 2),
    (7, 6, 2, 1, 1, 0),
    -- "Groupe en poste" n'a pas accès à l'ADMIN
    (7, 1, 1, 1, 1, 0),
    (7, 2, 1, 1, 1, 0),
    (7, 3, 1, 1, 1, 0),
    (7, 5, 1, 1, 1, 0),
    (7, 6, 1, 1, 1, 0),
    -- "Groupe admin" a tous les droits sur l'ADMIN
    (9, 1, 1, 1, 1, 3), -- C
    (9, 2, 1, 1, 1, 3), -- R
    (9, 3, 1, 1, 1, 3), -- U
    (9, 5, 1, 1, 1, 3), -- E
    (9, 6, 1, 1, 1, 3), -- D
    -- "Groupe admin" peut gérer les PERMISSIONS du module ADMIN (interface de gestion des permissions)
    (9, 1, 1, 2, 1, 3), -- C
    (9, 2, 1, 2, 1, 3), -- R
    (9, 3, 1, 2, 1, 3), -- U
    (9, 5, 1, 2, 1, 3), -- E
    (9, 6, 1, 2, 1, 3), -- D
    -- "Groupe admin" peut gérer les NOMENCLATURES du module ADMIN  (interface de gestion des nomenclatures)
    (9, 1, 1, 3, 1, 3), -- C
    (9, 2, 1, 3, 1, 3), -- R
    (9, 3, 1, 3, 1, 3), -- U
    (9, 5, 1, 3, 1, 3), -- E
    (9, 6, 1, 3, 1, 3), -- D
    -- "Groupe admin" peut gérer les ACCESS_REQUESTS du module ADMIN  (interface de gestion des demandes d'accès)
    (9, 1, 1, 4, 1, 3), -- C
    (9, 2, 1, 4, 1, 3), -- R
    (9, 3, 1, 4, 1, 3), -- U
    (9, 6, 1, 4, 1, 3)  -- D
;

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

-- For contrib modules : the permissions are added in their SQL install script.
-- See in directory "data/" of each module.
