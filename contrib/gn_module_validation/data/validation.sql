SET client_encoding = 'UTF8';

-- ----------------------------------------------------------------------
-- Add available Validation permissions

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
