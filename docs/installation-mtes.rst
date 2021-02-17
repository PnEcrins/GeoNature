SPECIFICITES DEPOBIO
====================

Cette documentation mentionne les spécificités et la configuration de l'installation de l'instance nationale du Ministère de la Transition Ecologique et Solidaire (MTES), dans le cadre du projet de Depôt Légal des données de biodiversité (https://depot-legal-biodiversite.naturefrance.fr/).

Pour l'installation de GeoNature, voir la procédure d'installation de GeoNature et ses dépendances (https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-all.rst).


Configuration Apache
--------------------

Editez la configuration Apache de GeoNature et de TaxHub pour l'adapter au
contexte de production.

Fichier ``/etc/apache/site-enabled/geonature.conf`` :

::

    #Configuration GeoNature

    Alias /saisie /home/ecrins/geonature/frontend/dist
    <Directory /home/ecrins/geonature/frontend/dist>
        Require all granted
    </Directory>

    <Location /saisie/api>
        ProxyPass http://127.0.0.1:8000
        ProxyPassReverse  http://127.0.0.1:8000
    </Location>

Fichier ``/etc/apache/site-enabled/taxhub.conf`` :

::

        # Configuration TaxHub
        RewriteEngine  on
        RewriteRule    "taxhub$"  "taxhub/"  [R]
        <Location /saisie/taxhub>
            ProxyPass  http://127.0.0.1:5000 retry=0
            ProxyPassReverse  http://127.0.0.1:5000
        </Location>
        #FIN Configuration TaxHub


Le fichier ``/etc/apache/site-enabled/000-default.conf`` doit également être
édité pour faire fonctionner le load balancing (Voir la configuration de la
pre-prod pour l'adapter au serveur de production).


Configuration de l'application
------------------------------

Une fois l'installation terminée, il est nécessaire d'adapter les fichiers de
configuration de l'application pour les besoins spécifiques de
l'instance nationale.

Lancer le script pour effectuer automatiquement la configuration
de l'application :

``/home/<my_user>/geonature/install/install_all/configuration_mtes.sh``

Il est cependant possible de modifier ces configurations.
Le fichier ``/home/<my_user>/geonature/config/default_config.toml.example``
liste l'ensemble des variables de configuration disponibles ainsi que leurs
valeurs par défaut.

Editer le fichier de configuration de GeoNature pour surcoucher ces variables :

::

        sudo nano /home/<MON_USER>/geonature/config/geonature_config.toml`

Ci-dessous, les paramètres de configuration pour l'instance de production.



Configuration globale de l'application
**************************************

# code EPSG de la projection de la base
LOCAL_SRID = '2154'

DEFAULT_LANGUAGE='fr'

# url de l'application métadonnée
MTD_API_ENDPOINT = 'http://inpn.mnhn.fr/mtd'

# Nom de l'application sur la page d'acceuil
appName = 'Depôt légal de biodiviersité - saisie'

ID_APPLICATION_GEONATURE = 14

Configuration des URLS pour le CAS
***********************************

Les URLS doivent correspondre aux informations renseignées dans la
configuration Apache et au Load Balancer. Elle ne doivent pas contenir
de ``/`` final.

Pour la pré-prod, ajouter le préfixe "pp-" avant ``saisie`` et ``taxhub``
(naturefrance.fr/pp-saisie, naturefrance.fr/pp-taxhub/api) et adapter la
configuration Apache en conséquence.

::

    # URL d'accès à l'application
    URL_APPLICATION = 'https://depot-legal-biodiversite.naturefrance.fr/saisie'
    # URL de l'API de GeoNature
    API_ENDPOINT = 'https://depot-legal-biodiversite.naturefrance.fr/saisie/api'
    # URL de l'API de Taxhub
    API_TAXHUB = 'https://depot-legal-biodiversite.naturefrance.fr/taxhub/api'


Clé secrète
***********

Mettre un clé secrète personnalisée

::

    SECRET_KEY = '<MA_CLE_CRYPTEE>'


Configuration BDD liée à la connexion au CAS
********************************************

::

    [BDD]
    # id du groupe dans lequel tous les utilisateurs connectés sont ajoutés
    # (seul le socle 1 - droit minimum - est utilisé pour l'instance de production)
    ID_USER_SOCLE_1 = 20003
    ID_USER_SOCLE_2 = 20001

Connexion au CAS INPN - gestion centralisée des utilisateurs
************************************************************

Bien changer les variables ID et PASSWORD avec les bonnes valeurs.

NB : pour la pré-prod, utiliser ``https://preprod-inpn.mnhn.fr``

::

    [CAS_PUBLIC]
    CAS_AUTHENTIFICATION = true
    CAS_URL_LOGIN = 'https://inpn.mnhn.fr/auth/login'
    CAS_URL_LOGOUT = 'https://inpn.mnhn.fr/auth/logout'

    [CAS]
    CAS_URL_VALIDATION = 'https://inpn.mnhn.fr/auth/serviceValidate'
    # est ce que les utilisateurs connecté peuvent voir les donées de leur organisme
    USERS_CAN_SEE_ORGANISM_DATA = false

    [CAS.CAS_USER_WS]
    URL = 'https://inpn.mnhn.fr/authentication/information'
    ID = '<THE_INPN_LOGIN>'
    PASSWORD = '<THE_INPN_PASSWORD>'

Configuration du frontend
**************************

Pour l'instance de pré-prod, rajouter "instance de démo" à la variable
``appName``.

::

    [FRONTEND]
        # Compilation du fronend en mode production
        PROD_MOD = true
        # Affichage du footer sur la page d'acceuil
        DISPLAY_FOOTER = true
        # affiche la carte des dernières observations basées sur la synthese
        DISPLAY_MAP_LAST_OBS = false
        # afficheafficher un bloc de stat basé sur la synthese
        DISPLAY_STAT_BLOC = false


Configuration de la cartographie
********************************

::

    [MAPCONFIG]
    BASEMAP = [
        {"name" = "IGN-topo", "layer" = "https://wxs.ign.fr/i53afxeajwaokg3gxzzhn8un/geoportail/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=GEOGRAP$
        {"name"= "IGN-Scan Express", "layer" = "https://wxs.ign.fr/i53afxeajwaokg3gxzzhn8un/geoportail/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=$
        {"name" = "IGN-Ortho", "layer" = "https://wxs.ign.fr/i53afxeajwaokg3gxzzhn8un/geoportail/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=ORTHOI$
    ]
    # Attention: les coordonnées sont au format [Y, X] - cf leaflet configuration (https://leafletjs.com/reference-1.4.0.html#latlng-l-latlng)
    CENTER = [46.52863469527167, 2.43896484375]
    # Zoom par défaut
    ZOOM_LEVEL = 6
    # Zoom à partir duquel on peut pointer un releve
    ZOOM_LEVEL_RELEVE = 15



Après chaque modification du fichier de configuration, lancez les commandes
suivantes pour mettre à jour l'application (l'opération peut être longue car
il s'agit de la recompilation du frontend).

Depuis le répertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature update_configuration
    deactivate


Configuration du module Occurrence de taxon: OCCTAX
***************************************************

Le fichier de configuration du module Occtax se trouve dans le fichier
``<GEONATURE_DIRECTORY>/external_modules/occtax/config/conf_gn_module.toml``.

Le script de configuration spécifique de l'instance nationale remplit ce
fichier avec les bonnes configuration.

Voici la configuration fournie pour l'instance de production:

::

    api_url = '/occtax'

    # message sur la modale des export pour préciser les consignes pour GINCO
    export_message = "<p> <b> Attention: </b> </br> Vous vous apprêtez à télécharger les données de la <b>recherche courante.</b> </br> Pour n'exporter qu'un <b>$

    # format disponible pour l'export
    export_available_format = ['csv', 'geojson']

    # passage du champ observateur du formulaire de saisi en mode 'saisie libre'
    observers_txt = true

    # identifiant de la liste des taxon proposé dans le formulaire (voir table taxonomie.bib_listes et taxonomie.cor_nom_liste)
    id_taxon_list = 500

    # niveau de zoom à partir duquel on peut saisir un relevé sur la carte
    releve_map_zoom_level = 15

    # colonnes de la vue pr_occtax.export_occtax_sinp à exporter pour GINCO dépot légal
    export_columns =  [
        "permId",
        "statObs",
        "nomCite",
        "dateDebut",
        "dateFin",
        "heureDebut",
        "heureFin",
        "altMax",
        "altMin",
        "cdNom",
        "cdRef",
        "dateDet",
        "comment",
        "dSPublique",
        "statSource",
        "idOrigine",
        "refBiblio",
        "obsMeth",
        "ocEtatBio",
        "ocNat",
        "ocSex",
        "ocStade",
        "ocBiogeo",
        "ocStatBio",
        "preuveOui",
        "ocMethDet",
        "preuvNum",
        "preuvNoNum",
        "obsCtx",
        "permIdGrp",
        "methGrp",
        "typGrp",
        "denbrMax",
        "denbrMin",
        "objDenbr",
        "typDenbr",
        "obsId",
        "obsNomOrg",
        "detId",
        "detNomOrg",
        "orgGestDat",
        "WKT",
        "natObjGeo"
        ]


Le fichier
``<GEONATURE_DIRECTORY>/external_modules/occtax/config/conf_gn_module.toml.example``
liste l'ensemble des variables de configuration du module Occtax ainsi que
leurs valeurs par défault.

Après chaque modification du fichier de configuration, lancez les commandes
suivantes pour mettre à jour l'application (l'opération peut être longue car
il s'agit de la recompilation du frontend).

Depuis le répertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature update_module_configuration occtax
    deactivate


Pour plus d'information sur la configuration du module Occtax, voir la documentation concernant le module (https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst#module-occtax).

Référentiel géographique
------------------------

Sur l'instance nationale on charge dans le référentiel géographique
l'ensemble des communes du territoire français, ainsi qu'un MNT (modèle
numérique de terrain) national de résolution 250m (pour le calcul automatique
des altitudes pour chaque observation).

.. image :: http://geonature.fr/docs/img/admin-manual/design-geonature-mtes.png

Authentification CAS INPN
-------------------------

- Code source : https://github.com/PnX-SI/GeoNature/blob/develop/backend/geonature/core/auth/routes.py
- Config : https://github.com/PnX-SI/GeoNature/blob/develop/config/default_config.toml.example#L29-L44


Connexion et droits dans GeoNature
----------------------------------

- A chaque connexion via le CAS INPN on récupère l’ID_Utilisateur.
  On ajoute cet utilisateur dans la base de données de GeoNature
  (``utilisateurs.t_roles`` et ``utilisateurs.bib_organisme``) et on
  lui affecte des droits CRUVED par défaut.

- On assigne à l'utilisateur le « socle 1 » (C1-R1-V0-E1-D1). Il pourra voir
  seulement les données qu’il a saisi lui-même et les JDD qu’il a
  créé dans MTD.

NB sur la gestion des droits dans GeoNature :

- 6 actions sont possibles dans GeoNature :
  Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- 3 portées de ces actions sont possibles :
  Mes données / Les données de mon organisme / Toutes les données.

Récupération des JDD
--------------------

Grâce à l'API de MTD, il est désormais possible d’ajouter les jeux de données
(et des cadres d’acquisition) créés dans MTD dans la BDD GeoNature.

- On récupère la liste des JDD créés par l’utilisateur grâce à l’API MTD au
  chargement de la liste déroulante des JDD :
  https://xxxxx/cadre/jdd/export/xml/GetRecordsByUserId?id=<ID_USER>

- On récupère l’UUID du cadre CA associé au JDD dans le XML renvoyé et on fait
  appel au l’API MTD pour récupérer le fichier XML du CA :
  https://xxxxx/cadre/export/xml/GetRecordById?id=<UUID>

- On ajoute le CA dans la table ``gn_meta.t_acquisition_framwork`` et les JDD
  dans la table ``gn_meta.t_datasets``. Si le CA ou les JDD sont modifiés dans
  MTD, ils seront également modifiés dans le BDD GeoNature.

- Dans la table ``gn_meta.cor_dataset_actor`` on fait le lien entre les
  acteurs et le JDD. On ajoute l’utilisateur qui a créé le JDD comme
  "Point de contact principal" du JDD. Si on dispose de l’ID_Organisme de
  l’utilisateur, on ajoute également l’organisme comme
  "Point de contact principal" du JDD.

- Pour remplir cette table on ne prend pas les infos renvoyés par le
  XML JDD sous l’intitulé « Acteur » puisque l’ID_Organisme ou l’ID_Acteur
  n’est pas renseigné. (Dans la table ``gn_meta.cor_dataset_actor``, il faut
  obligatoirement un ID).

- La question de la suppresion de JDD et des CA n’est pas résolue. Si un JDD
  est supprimé dans MTD, qu’est-ce qu’on fait des données associées a celui-ci
  dans GeoNature ?


Module Synthese
---------------

Sur l'instance DEPOPBIO le module synthese a été désactivé en mettant un
CRUVED à 0 au groupe socle 1 et socle 2 pour le module.

::

    INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (
      id_role,
      id_action,
      id_module,
      id_object,
      id_filter_type,
      value_filter
    )
    VALUES
    -- synthese pour socle 1
    (20003, 1, 17, 1, 1, '0'),
    (20003, 2, 17, 1, 1, '0'),
    (20003, 3, 17, 1, 1, '0'),
    (20003, 4, 17, 1, 1, '0'),
    (20003, 5, 17, 1, 1, '0'),
    (20003, 6, 17, 1, 1, '0'),
   -- synthese socle 2
    (20001, 1, 17, 1, 1, '0'),
    (20001, 2, 17, 1, 1, '0'),
    (20001, 3, 17, 1, 1, '0'),
    (20001, 4, 17, 1, 1, '0'),
    (20001, 5, 17, 1, 1, '0'),
    (20001, 6, 17, 1, 1, '0'),
  -- admin socle 2
    (20003, 1, 19, 1, 1, '0'),
    (20003, 2, 19, 1, 1, '0'),
    (20003, 3, 19, 1, 1, '0'),
    (20003, 4, 19, 1, 1, '0'),
    (20003, 5, 19, 1, 1, '0'),
    (20003, 6, 19, 1, 1, '0'),
  -- admin socle 2
    (20001, 1, 19, 1, 1, '0'),
    (20001, 2, 19, 1, 1, '0'),
    (20001, 3, 19, 1, 1, '0'),
    (20001, 4, 19, 1, 1, '0'),
    (20001, 5, 19, 1, 1, '0'),
    (20001, 6, 19, 1, 1, '0'),
  -- meta socle 2
    (20003, 1, 20, 1, 1, '0'),
    (20003, 2, 20, 1, 1, '0'),
    (20003, 3, 20, 1, 1, '0'),
    (20003, 4, 20, 1, 1, '0'),
    (20003, 5, 20, 1, 1, '0'),
    (20003, 6, 20, 1, 1, '0'),
  -- meta socle 2
    (20001, 1, 20, 1, 1, '0'),
    (20001, 2, 20, 1, 1, '0'),
    (20001, 3, 20, 1, 1, '0'),
    (20001, 4, 20, 1, 1, '0'),
    (20001, 5, 20, 1, 1, '0'),
    (20001, 6, 20, 1, 1, '0')
  ;


Les triggers d'insertion du module Occtax vers le module Synthese ont
également été désactivés.


::


    ALTER TABLE pr_occtax.t_releves_occtax DISABLE TRIGGER tri_update_synthese_t_releve_occtax;
    ALTER TABLE pr_occtax.t_releves_occtax DISABLE TRIGGER tri_delete_synthese_t_releve_occtax;

    ALTER TABLE pr_occtax.t_occurrences_occtax DISABLE TRIGGER tri_update_synthese_t_occurrence_occtax;
    ALTER TABLE pr_occtax.t_occurrences_occtax DISABLE TRIGGER tri_delete_synthese_t_occurrence_occtax;

    ALTER TABLE pr_occtax.cor_counting_occtax DISABLE TRIGGER tri_insert_synthese_cor_counting_occtax;
    ALTER TABLE pr_occtax.cor_counting_occtax DISABLE TRIGGER tri_update_synthese_cor_counting_occtax;
    ALTER TABLE pr_occtax.cor_counting_occtax DISABLE TRIGGER tri_delete_synthese_cor_counting_occtax;
