=========
CHANGELOG
=========

2.4.1 (Unreleased)
------------------

**🚀 Nouveautés**

* Intégration de profils de taxons paramétrables (#917)

**⚠️ Notes de version**

* De nouvelles fonctions de TaxHub sont requises pour les profils de taxons (taxonomie.check_is_cd_ref & taxonomie.find_all_taxons_parents), assurez-vous d'être à jour sur l'intégration de ces fonctions
* SQL de création des profils de taxons à lancer (``data/core/profiles.sql``) et mettre en place des tâches cron pour rafraichir les vues matérialisées des profils.
* SQL d'update de la BDD (``data/migrations/2.4.0to2.4.1.sql``)

TODO : lancer ``data/core/profiles.sql`` lors de l'installation de geonature + Prévoir des cron pour rafraichir ces vues



2.4.0 (Unreleased)
----------------

**TO CHECK**

* Renommer https://github.com/ouidou/GeoNature/blob/develop/backend/static/css/jeu_de_donnees_template_pdf.css
* Et renommer aussi https://github.com/PnX-SI/GeoNature/blob/develop/backend/templates/cadre_acquisition_template_pdf.html
* https://github.com/PnX-SI/GeoNature/commit/202551eed6c19bb2f8b06ca9ada16ed3675d6613 >> On perd des colonnes...
* http://87.98.168.87/geonature/#/validation / Filtre données modifiées depuis dernière validation : Tourne en boucle. Et l'info ne semble plus remonter
* Installation standalone et dépendances WeasyPrint ?

**🚀 Nouveautés**

* Métadonnées : Ajout d'une fiche pour chaque jeu de données et cadres d'acquisition, incluant une carte de l'étendue des observations et un graphique de répartition des taxons par Groupe INPN (#846 par @FloVollmer)
* Métadonnées : Possibilité d'exporter les fiches des JDD et des CA en PDF, générés par le serveur avec WeasyPrint. Logo et entêtes modifiables dans le dossier ``backend/static/images/`` (#882 par @FloVollmer)
* Métadonnées : Implémentation du CRUVED sur la liste des CA et JDD (#911)
* Métadonnées : Affichage de tous les CA des JDD pour lequels l'utilisateur connecté a des droits (#908)
* Compatible avec TaxHub 1.7.0 qui inclut notamment la migration (optionnelle) vers Taxref version 13
* Installation globale migrée de Taxref vesion 11 à 13
* Synthèse et zonages : Ne pas inclure l'association aux zonages limitrophes d'une observation quand sa géométrie est égale à un zonage (maille, commune...) (#716 par @jbdesbas)
* Synthèse : Ajout de la possibilité d'activer la recherche par observateur à travers une liste, avec ajout des paramètres ``SEARCH_OBSERVER_WITH_LIST`` (``False`` par défaut) et ``ID_SEARCH_OBSERVER_LIST`` (#834 par @jbrieuclp)
* Synthèse : Amélioration de la recherche des observateurs. Non prise en compte de l'ordre des noms saisis (#834 par @jbrieuclp)
* Synthèse : Ajout de filtres avancés (``Saisie par`` basé sur ``id_digitiser``, ``Commentaire`` du relevé et de l'occurrence, ``Déterminateur``) (#834 par @jbrieuclp)
* Occtax : Création d'un trigger générique de calcul de l'altitude qui n'est exécuté que si l'altitude n'est pas postée (#848)
* Ajout d'une table ``gn_commons.t_mobile_apps`` permettant de lister les applications mobiles, l'URL de leur APK et d'une API pour interroger le contenu de cette table. Les fichiers des applications et leurs fichiers de configurations peuvent être chargés dans le dossier ``backend/static/mobile`` (#852)
* Ajout d'un offset et d'une limite sur la route de la couleur des taxons (utilisée uniquement par Occtax-mobile actuellement)
* Support des fonds de carte au format WMS (https://leafletjs.com/reference-1.6.0.html#tilelayer-wms-l-tilelayer-wms), (#890 par @jbdesbas)
* Ajout d'un champs texte ``reference_biblio`` dans la table ``gn_synthese``
* Amélioration des perfomances du module de validation, en revoyant la vue ``gn_commons.v_synthese_validation_forwebapp``, en revoyant les requêtes et en générant le GeoJSON au niveau de la BDD (#923)
* Ajout d'une fonction SQL d'insertion de données dans la synthese (et une fonction python associée)
* Compléments de la documentation (Permissions des utilisateurs, Occhab)
* Ajout de scripts de migration des données de GINCO1 vers GeoNature (``data/scripts/import_ginco``)
* Trigger Occtax vers Synthèse : Amélioration du formatage des heures avec ``date_trunc()`` dans la fonction ``pr_occtax.insert_in_synthese()`` (#896 par @jbdesbas)
* Barre de navigation : Clarification de l'icône d'ouverture du menu, ajout d'un paramètre ``LOGO_STRUCTURE_FILE`` permettant de changer le nom du fichier du logo de l'application (#897 par @jbrieuclp)
* Médias : Amélioration des fonctions backend
* Mise à jour de jQuery en version 3.5.0
* Suppression de la table ``gn_synthese.taxons_synthese_autocomplete`` et du trigger sur la Synthèse qui la remplissait pour utiliser la vue matérialisée ``taxonomie.vm_taxref_list_forautocomplete`` listant les noms de recherche de tous les taxons de Taxref, entièrement revue dans TaxHub 1.7.0
* Monitoring : Correction du backend pour utiliser la nouvelle syntaxe de jointure des tables
* Ajout de fonctions SQL d'insertion de données dans la Synthèse (``gn_synthese.import_json_row()`` et ``gn_synthese.import_row_from_table()``) et de la fonction Python associée (``import_from_table(schema_name, table_name, field_name, value)``) pour l'API permettant de poster dans la Synthèse (#736). Utilisée par le module Monitoring.
* Ajout du plugin Leaflet.Deflate (#934  par @jpm-cbna)
* Connexion au CAS INPN : Renseigner automatiquement ``gn_commons.cor_module_dataset``
* Mise à jour des librairies Python Utils-Flask-SQLAlchemy (en version 0.1.1) et Utils-Flask-SQLAlchemy-Geo (en version 0.1.0) permettant de mettre en place les exports au format GeoPackage et corrigeant les exports de SHP contenant des géométries multiples

**🐛 Corrections**

* Mise à jour des URL de la documentation utilisateur des modules, renvoyant vers http://docs.geonature.fr
* Validation : Correction de l'ouverture de la fiche d'information d'une observation (#858)
* Modification de l'attribution de la hauteur du composant ``map-container`` pour permettre d'adapter la hauteur de la carte si la hauteur d'un conteneur parent est modifié. Et que ``<pnx-map height="100%">`` fonctionne (#844 par @jbrieuclp)
* Mise à jour de la librairie python Markupsafe en version 1.1, corrigeant un problème de setuptools (#881)
* Page Maintenance : Correction de l'affichage de l'image (par @jpm-cbna)
* Correction du multiselect du composant ``pnx-nomenclatures`` (#885 par @jpm-cbna)
* Correction de l'``input('coordinates')`` du composant ``marker`` (#901 par @jbrieuclp)
* Utilisation de NVM quand on installe les dépendances javascript (#926 par @jpm-cbna)
* Formulaire JDD : Correction de l'affichage de la liste des modules (#861)

**⚠️ Notes de version**

* Vous devez d'abord mettre à jour TaxHub en version 1.7.0
* Si vous mettez à jour TaxHub, vous pouvez mettre à jour Taxref en version 13. Il est aussi possible de le faire en différé, plus tard
* Vous pouvez mettre à jour UsersHub en version 2.1.2
* Exécuter le script SQL de mise à jour des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update1.3.2to1.3.3.sql). 
* Si vous avez mis à jour Taxref en version, répercutez les évolutions au niveau des nomenclatures avec le script SQL https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update_taxref_v13.sql. Sinon vous devrez l'exécuter plus tard, après avoir mis à jour Taxref en version 13.
* Exécuter le script SQL de mise à jour de la BDD de GeoNature (``data/migrations/2.3.2to2.4.0.sql``)
* Installer les dépendances de la librairie Python WeasyPrint :

::

    sudo apt-get install -y libcairo2
    sudo apt-get install -y libpango-1.0-0
    sudo apt-get install -y libpangocairo-1.0-0
    sudo apt-get install -y libgdk-pixbuf2.0-0
    sudo apt-get install -y libffi-dev
    sudo apt-get install -y shared-mime-info
    
* Vous pouvez supprimer les associations des observations de la synthèse aux zonages limitrophes, si vous n'avez pas d'observations sans géométrie (#719) :

::

    DELETE FROM gn_synthese.cor_area_synthese cas
    USING gn_synthese.synthese s , ref_geo.l_areas a
    WHERE cas.id_synthese = s.id_synthese AND a.id_area = cas.id_area
    AND public.ST_TOUCHES(s.the_geom_local,a.geom);

* Suivez ensuite la procédure classique de mise à jour de GeoNature (http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application)

2.3.2 (2020-02-24)
------------------

**🚀 Nouveautés**

* Possibilité de charger les commandes d'un module dans les commandes de GeoNature
* Ajout de commentaires dans le fichier d'exemple de configuration ``config/default_config.toml.example``

**🐛 Corrections**

* Correction d'une incohérence dans le décompte des JDD sur la page d'accueil en leur appliquant le CRUVED (#752)
* Montée de version de la librairie ``utils-flask-sqlalchemy-geo`` pour compatibilité avec la version 1.0.0 du module d'export

2.3.1 (2020-02-18)
------------------

**🚀 Nouveautés**

* Installation globale : Compatibilité Debian 10 (PostgreSQL 11, PostGIS 2.5)
* Installation globale : Passage à Taxhub 1.6.4 et UsersHub 2.1.1
* Utilisation généralisée des nouvelles librairies externalisées de sérialisation (https://github.com/PnX-SI/Utils-Flask-SQLAlchemy et https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo)
* Possibilité de régler le timeout de Gunicorn pour éviter le plantage lors de requêtes longues
* Ne pas zoomer sur les observations au premier chargement de la carte (#838)
* Leaflet-draw : Ajout de la possibilité de zoomer sur le point (par @joelclems)
* Ajout du nom vernaculaire dans les fiches d'information des relevés d'Occtax (par @FloVollmer / #826)

**🐛 Corrections**

* Correction de l'installation de Node.js et npm par l'utilisation généralisée de nvm (#832 et #837)
* Fixation de la version de Node.js en 10.15.3 (dans le fichier ``fronted/.nvmrc``)
* Ajout d'une référence de l'objet Leaflet ``L`` afin qu'il soit utilisé dans les modules et changement du typage de l'évenement Leaflet ``MouseEvent`` en ``L.LeafletMouseEvent``
* Fixation de la version de vitualenv en 20.0.1 (par @sogalgeeko)
* Corrections de typos dans la documentation d'administration (#840 - par @sogalgeeko)

**⚠️ Notes de version**

* Vous pouvez passer directement à cette version depuis la 2.2.x, mais en suivant les notes des versions intermédiaires (NB : il n'est pas nécessaire d’exécuter le script ``migrate.sh`` des versions précédentes)
* Installez ``pip3`` et ``virtualenv``
::

    sudo apt-get update
    sudo apt-get install python3-pip
    sudo pip3 install virtualenv==20.0.1
* Rajoutez la ligne ``gun_timeout=30`` au fichier ``config/settings.ini``. Il s'agit du temps maximal (en seconde) autorisé pour chaque requête. A augmenter, si vous avez déjà rencontré des problèmes de timeout.
* Depuis le répertoire ``frontend``, lancez la commande ``nvm install``

2.3.0 - Occhab de Noël (2019-12-27)
-----------------------------------

**🚀 Nouveautés**

* Développement du module Occhab (Occurrences d'habitats) basé sur une version minimale du standard SINP du même nom et s'appuyant sur le référentiel Habref du SINP (#735)

  - Consultation (carte-liste) des stations et affichage de leurs habitats
  - Recherche (et export) des stations par jeu de données, habitats ou dates
  - Saisie d'une station et de ses habitats
  - Possibilité de saisir plusieurs habitats par station
  - Saisie des habitats basée sur une liste pré-définie à partir d'Habref. Possibilité d'intégrer toutes les typologies d'habitat ou de faire des listes réduites d'habitats
  - Possibilité de charger un fichier GeoJson, KML ou GPX sur la carte et d'utiliser un de ses objets comme géométrie de station
  - Mise en place d'une API Occhab (Get, Post, Delete, Export stations et habitats et récupérer les valeurs par défaut des nomenclatures)
  - Calcul automatique des altitudes (min/max) et de la surface d'une station
  - Gestion des droits (en fonction du CRUVED de l'utilisateur connecté)
  - Définition des valeurs par défaut dans la BDD (paramétrable par organisme)
  - Possibilité de masquer des champs du formulaire

* Création d'un sous-module autonome ou intégré pour gérer l'API d'Habref (https://github.com/PnX-SI/Habref-api-module) pour :

  - Rechercher un habitat dans Habref (avec usage du trigramme pour la pertinence du résultat)
  - Obtenir les infos d'un habitat et de ses correspondances à partir de son cd_hab
  - Obtenir les habitats d'une liste (avec ou sans leur code en plus de leur nom et filtrable par typologie)
  - Obtenir la liste des typologies (filtrable par liste d'habitats)

* Mise à jour du module des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module) en version 1.3.2 incluant notamment :

  - Ajout de nomenclatures SINP concernant les habitats
  - Ajout d'une contrainte d'unicité sur la combinaison des champs ``id_type`` et ``cd_nomenclature`` de la table ``t_nomenclatures``

* Association des JDD à des modules pour filtrer les JDD utilisés dans Occtax ou dans Occhab notamment (#399)
* Mise à jour de Angular 4 à Angular 7 (performances, ....) par @jbrieuclp
* Ajout d'une documentation utilisateur pour le module Synthèse : http://docs.geonature.fr/user-manual.html#synthese (par @amandine-sahl)
* OCCTAX : Amélioration importante des performances de la liste des relevés (par @jbrieuclp) (#690, #740)
* Améliorations des performances des exports de Occtax et de Synthèse et ajout d'index dans Occtax (par @gildeluermoz) (#560)
* Partage de scripts de sauvegarde de l'application et de la BDD dans ``data/scripts/backup/`` (par @gildeluermoz)
* Externalisation des librairies d'outils Flask et SQLAlchemy (https://github.com/PnX-SI/Utils-Flask-SQLAlchemy et https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo) pour pouvoir les factoriser et les utiliser dans d'autres applications. Cela améliore aussi les performances des jointures.
* SYNTHESE : Ajout d'un export de la liste des espèces (#805)
* SYNTHESE : Baser la portée de tous les exports (y compris Statuts) sur l'action E (#804)
* METADONNEES : Affichage des ID des JDD et CA
* OCCTAX : Conserver le fichier GPX ou GeoJSON chargé sur la carte quand on enchaine des relevés et ajouter de la transparence sur les géométries utilisés dans les relevés précédents (#813)
* OCCTAX : Clarification de l'ergonomie pour ajouter un dénombrement sur un taxon (#780)
* Ajout des dates de creation et de modification dans les tables ``gn_monitoring.t_base_sites`` et ``gn_monitoring.t_base_visits`` et triggers pour les calculer automatiquement
* Ajout des champs ``geom_local``, ``altitude_min`` et ``altitude_max`` dans la table ``gn_monitoring.t_base_sites`` et triggers pour les calculer automatiquement (#812)
* Ajout des champs ``id_dataset``, ``id_module``, ``id_nomenclature_obs_technique`` et ``id_nomenclature_grp_typ`` dans la table ``gn_monitoring.t_base_visits`` (#812)
* Le composant générique FileLayer expose un ``output`` pour récuperer la géométrie sélectionnée (un observable de MapService était utilisé auparavant)
* Support des markers sur le composant ``leaflet-draw``
* Possibilité de ne pas activer le composant ``marker`` au lancement lorsque celui-ci est utilisé (input ``defaultEnable``)
* Ajout d'inputs ``time`` et ``number`` au composant DynamicForm permettant de générer des formulaires dynamiques.
* Améliorations diverses du composant DynamicForm (par @joelclems)
* Ajout d'un paramètre dans le cas où le serveur se trouve derrière un proxy (``proxy_http`` ou dans ``proxy_https`` dans ``config/settings.ini``)
* Ajout d'une route permettant de récupérer la liste des rôles d'une liste à partir de son code (par @joelclems)

**🐛 Corrections**

* MENU Side nav : Correction pour ne pas afficher les modules pour lesquels le paramètre ``active_frontend`` est False (#822)
* OCCTAX : Gestion de l'édition des occurrences où le JDD a été désactivé, en ne permettant pas de modifier le JDD (#694)
* OCCTAX : Correction d'une faiblesse lors de la récupération des informations taxonomiques d'un relevé (utilisation d'une jointure plutôt que l'API TaxHub) (#751)
* OCCTAX : Correction des longues listes de taxons dans les tooltip des relevés en y ajoutant un scroll (par @jbrieuclp) (#666)
* OCCTAX : Masquer le bouton ``Télécharger`` si l'utilisateur n'a pas de droits d'export dans le module (E = 0)
* OCCTAX : Correction de l'affichage des relevés dans la liste (#777)
* OCCTAX : Correction des exports quand on filtre sur un obervateur en texte
* SYNTHESE : Filtre sur ``date_max`` en prenant ``date_max <= 23:59:59`` pour prendre en compte les observations avec un horaire (#778)
* SYNTHESE : Correction des boutons radios pour les filtres taxonomiques avancés basés sur les attributs TaxHub (#763)
* SYNTHESE : Correction de la recherche par ``cd_nom`` dans le composant ``SearchTaxon`` (#824)
* VALIDATION : Corrections mineures (par @jbrieuclp) (#715)
* INSCRIPTION : Correction si aucun champ additionnel n'a été ajouté au formulaire (par @jbrieuclp) (#746)
* INSCRIPTION : Correction de l'usage des paramètres ``ENABLE_SIGN_UP`` et ``ENABLE_USER_MANAGEMENT`` (#791)
* Simplification de l'écriture des logs dans le script ``install_db.sh``
* Correction de l'installation des requirements.txt lors de l'installation d'un module (#764 par @joelclems)
* COMMONS : Modification des champs de ``t_modules`` de type CHARACTER(n) en CHARACTER VARYING(n) (``module_path``, ``module_target``, ``module_external_url``) (#799)
* COMMONS : Ajout de contraintes d'unicité pour les champs ``module_path`` et ``module_code`` de ``t_modules``
* pnx-geojson : Amélioration du zoom, gestion des styles
* Migration des données GeoNature V1 vers V2 (``data/migrations/v1tov2/``) : ajustements mineurs

**⚠️ Notes de version**

NB: La version 2.3.0 n'est pas compatible avec le module Dashboard. Si vous avez le module dashboard installé, ne passez pas à cette nouvelle version. Compatibilité dans la 2.3.1.

* Lancer le script de migration qui va installer et remplir le nouveau schéma ``ref_habitats`` avec Habref et mettre à jour le schéma ``ref_nomenclatures`` :

::

    cd /home/`whoami`/geonature/install/migration
    chmod +x 2.2.1to2.3.0.sh
    ./2.2.1to2.3.0.sh

Vérifier que la migration s'est bien déroulée dans le fichier ``var/log/2.2.1to2.3.0.log``.

* Lancer le script SQL de mise à jour de la BDD de GeoNature https://raw.githubusercontent.com/PnX-SI/GeoNature/2.3.0/data/migrations/2.2.1to2.3.0.sql

* Vous pouvez installer le nouveau module Occhab (Occurrences d'habitats) si vous le souhaitez :

::

    cd /home/`whoami`/geonature/backend
    source venv/bin/activate
    geonature install_gn_module /home/`whoami`/geonature/contrib/gn_module_occhab /occhab

* Lors de la migration (``/data/migrations/2.2.1to2.3.0.sql``), tous les JDD actifs sont associés par défaut au module Occtax (https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.2.1to2.3.0.sql#L17-L22). A chacun d'adapter si besoin, en en retirant certains. Pour utiliser le module Occhab, vous devez y associer au moins un JDD.

2.2.1 (2019-10-09)
------------------

**🐛 Corrections**

* La route de changement de mot de passe était désactivée par le mauvais paramètre (``ENABLE_SIGN_UP`` au lieu de ``ENABLE_USER_MANAGEMENT``)
* Désactivation du mode "enchainement des relevés" en mode édition (#669). Correction effacement du même relevé (#744)
* Correction d'affichage du module métadonnées lorsque les AF n'ont pas de JDD pour des raisons de droit (#743)
* Diverses corrections de doublons d'import et de logs de débugs (#742)
* Montée de version du sous-module d'authentification: 1.4.2

2.2.0 - Module utilisateurs (2019-09-18)
----------------------------------------

**🚀 Nouveautés**

* Ajout d'interfaces et de paramètres de création de compte, de récupération de son mot de passe et d'administration de son profil, basé sur l'API UsersHub 2.1.0 (par @jbrieuclp et @TheoLechemia) #615
* Ajout d'une fonctionnalité de création automatique d'un CA et d'un JDD personnel lors de la validation d'un compte créé automatiquement (paramétrable)
* Amélioration du composant de création dynamique de formulaire (support de text-area, checkbox simple et multiple et exemple d'utilisation à partir de la conf GeoNature)
* Le composant 'observateur' permet de rechercher sur le nom ou le prénom (utilisation des RegEx) #567
* Mise à jour de Flask en version 1.1.1
* Nouvelle version du sous-module d'authentification (1.4.1), compatible avec UsersHub 2.1.0
* Mise à jour du sous-module de nomenclatures (version 1.3.0)
* Mise à jour et clarification du MCD (http://docs.geonature.fr/admin-manual.html#base-de-donnees) par @jpm-cbna
* Ajout d'une tutoriel vidéo d'installation dans la documentation (https://www.youtube.com/watch?v=JYgH7cV9AjE, par @olivier8064)

**🐛 Corrections**

* Correction d'un bug sur les export CSV en utilisant la librairie Python standard ``csv`` (#733)
* SYNTHESE API : Passage de la route principale de récupération des données en POST plutôt qu'en GET (#704)
* SYNTHESE BDD : Suppression automatique des aires intersectées (``synthese.cor_area_synthese``) lorsqu'une observation est supprimée (DELETE CASCADE)
* SYNTHESE : Prise en compte du paramètre ``EXPORT_ID_SYNTHESE_COL`` (#707)
* OCCTAX : Correction d'une autocomplétion automatique erronée de la date max en mode édition (#706)
* VALIDATION : Améliorations des performances, par @jbrieuclp (#710)
* Prise en compte des sous-taxons pour le calcul des règles de sensibilité
* Correction des contraintes CHECK sur les tables liées à la sensibilité
* Complément et correction des scripts de migration ``data/migrations/v1tov2``
* Correction et clarification de la documentation d'administration des listes de taxons et de sauvegarde et restauration de la BDD (par @lpofredc)
* Correction de la rotation des logs

**⚠️ Notes de version**

* Passer le script de migration suivant: https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.1.2to2.2.0.sql
* Suivez ensuite la procédure classique de mise à jour de GeoNature (http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application)
* Si vous souhaitez activer les fonctionnalités de création de compte, veuillez lire **attentivement** cette documentation : http://docs.geonature.fr/admin-manual.html#configuration-de-la-creation-de-compte
* Si vous activez la création de compte, UsersHub 2.1.0 doit être installé. Voir sa `note de version <https://github.com/PnX-SI/UsersHub/releases>`_.

2.1.2 (2019-07-25)
------------------

**🐛 Corrections**

* SYNTHESE : Correction d'une URL en dur pour la recherche de rangs taxonomiques
* OCCTAX : Affichage uniquement des JDD actifs
* VALIDATION : Abaissement de la limite d'affichage de données sur la carte par défaut + message indicatif
* Migration : Suppression d'un lien symbolique qui créait des liens en cascade
* Amélioration de la documentation (@dthonon)
* Amélioration de la rapidité d'installation du MNT grâce à la suppression d'un paramètre inutile
* BACKOFFICE : Correction d'une URL incorrecte et customisation

**⚠️ Notes de version**

Ceci est une version corrective mineure. Si vous migrez depuis la 2.1.0, passez directement à cette version en suivant les notes de version de la 2.1.1.

2.1.1 (2019-07-18)
------------------

**🚀 Nouveautés**

* SYNTHESE: Factorisation du formulaire de recherche (utilisé dans le module synthese et validation)
* SYNTHESE: Simplification et correction du module de recherche avancée d'un taxon en le limitant à l'ordre (performances)
* SYNTHESE: Ajout d'un composant de recherche taxonomique avancé basé sur les rangs taxonomiques (modules synthese et validation), basé sur la nouvelle fonction ``taxonomie.find_all_taxons_children`` ajoutée à TaxHub
* Création d'un backoffice d'admnistration dans le coeur de GeoNature. Basé sur Flask-admin, les modules peuvent alimenter dynamiquement le backoffice avec leur configuration
* Mise en place d'une documentation développeur automatique de l'API à partir des docstring et des composants frontend, générée par Travis et désormais accessible à l'adresse http://docs.geonature.fr (#673)
* Amélioration de la documentation (triggers, installation, module validation)
* Suppression du module d'exemple, remplacé par un template de module (https://github.com/PnX-SI/gn_module_template)
* Ajout d'un champ ``validable`` sur la table ``gn_meta.t_datasets`` controlant les données présentes dans le module VALIDATION (https://github.com/PnX-SI/gn_module_validation/issues/31)
* VALIDATION: Lister toutes les données de la synthèse ayant un ``uuid_sinp`` dans le module validation, et plus seulement celles qui ont un enregistrement dans ``gn_commons.t_validations``
* VALIDATION: On ne liste plus les ``id_nomenclatures`` des types de validation à utiliser, dans la configuration du module. Mais on utilise toutes les nomenclatures activées du type de nomenclature ``STATUT_VALID``. (https://github.com/PnX-SI/gn_module_validation/issues/30)
* Ajout de tests sur les ajouts de JDD et CA
* Ajout d'une fonctionnalité d'envoie d'email via Flask-Mail dans le coeur de GeoNature
* Amélioration des performances: ajout d'index sur Occtax et Metadonnées
* Script d'import des métadonnées à partir du webservice MTD de l'INPN (@DonovanMaillard)
* Complément, correction et compatibilité 2.1.0 des scripts de migration ``data/migrations/v1tov2``

**🐛 Corrections**

* Nombreuses corrections du module de validation (non utilisation des id_nomenclature, simplification des vues et de la table ``gn_commons.t_validations``)
* Ordonnancement de listes déroulantes (#685)
* OCCTAX : correction de l'édition d'un relevé à la géométrie de type Polyline (#684)
* OCCTAX : correction l'édition et du contrôle conditionnel des champs de "preuves" (preuve d'existence numérique / non numérique) (#679)
* OCCTAX : correction du parametre ``DATE_FORM_WITH_TODAY`` non pris en compte (#670)
* OCCTAX: correction de la date_max non remplie lorsque ``DATE_FORM_WITH_TODAY = false``
* OCCTAX: correction d'un bug lors de l'enchainement de relevé lorsque l'heure est remplie
* SYNTHESE: correction des doublons lorsqu'il y a plusieurs observateurs
* Correction du composant ``dynamicForm`` sur les champs de recherche de type texte (recherche sur Preuve numérique) (#530)
* Désactivation du mode "enchainer les relevés" en mode édition (#699)
* Correction de ``gn_monitoring`` : utiliser ``gn_commons.t_modules`` à la place de ``utilisateurs.t_applications`` pour associer des sites de suivi à des modules
* Fix de SQLalchemy 1.3.3 et jointure sur objet Table
* Le trigger remplissant ``cor_area_synthese`` en intersectant ``gn_synthese.synthese`` avec ``ref_geo.l_areas`` ne prend plus que les zonages ayant le champs ``enabled=true``
* Correction ``dict()`` et version de Python (par @jpm-cbna)
* MAJ de sécurité de Bootstrap (en version 4.3.1)
* L'ancien module export du coeur est enlevé en vue de la sortie du nouveau module export

**⚠️ Notes de version**

* Passer TaxHub en version 1.6.3 (https://github.com/PnX-SI/TaxHub/releases/tag/1.6.3)
* Passer le script de migration ``data/2.1.0to2.1.1.sql``
* Si vous aviez modifier les ``id_nomenclature`` dans la surcouche de la configuration du module validation, supprimer les car on se base maintenant sur les ``cd_nomenclature``
* Suivez ensuite la procédure classique de mise à jour de GeoNature (http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application)
* Nouvelle localisation de la doc : http://docs.geonature.fr

2.1.0 - Module validation (2019-06-01)
--------------------------------------

**🚀 Nouveautés**

* Intégration du module Validation dans GeoNature (développé par @JulienCorny, financé par @sig-pnrnm)
* Ajout de tables, règles et fonctions permettant de calculer la sensibilité des occurrences de taxon de la synthèse (#284)
* Occtax - Possibilité d'enchainer les saisies de relevés et de garder les informations du relevé (#633)
* Occtax - Amélioration de l'ergonomie de l'interface MapList pour clarifier la recherche et l'ajout d'un relevé + ajout compteur (#467)
* Révision de l'interface du module Métadonnées, listant les cadres d'acquisition et leurs jeux de données (par @jbrieuclp)
* Ajout d'un mécanisme du calcul des taxons observés par zonage géographique (#617)
* Les mailles INPN (1, 5, 10km) sont intégrées à l'installation (avec un paramètre)
* Statistiques de la page d'accueil - Ajout d'un paramètre permettant de les désactiver (#599)
* Occtax - Date par défaut paramétrable (#351)
* Support des géometries multiples (MultiPoint, MultiPolygone, MultiLigne) dans la synthèse et Occtax (#609)
* Synthese - Affichage des zonages intersectés dans un onglet séparé (#579)

**🐛 Corrections**

* Révision complète des scripts de migration de GeoNature v1 à v2 (``data/migrations/v1tov2``)
* Masquer l'export du module Synthèse si son CRUVED est défini à 0 (#608)
* Correction de la vérification du CRUVED du module METADONNEES (#601)
* Correction de la vérification du CRUVED lorsque get_role = False
* Correction de la traduction sur la page de connexion (par @jbrieuclp)
* Occtax - Retour du composant GPS permettant de charger un marker à partir de coordonnées X et Y (#624)
* Correction lors d'import de fichier GPX ayant une altitude (#631)
* Occtax - Correction du filtre Observateur texte libre (#598)
* Métadonnées - Inversion des domaines terrestre/marin (par @xavyeah39)
* Métadonnées - Correction de l'édition des cadres d'acquisition (#654, par @DonovanMaillard)
* Mise à jour de sécurité de Jinja2 et SQLAlchemy

**⚠️ Notes de version**

* Vous pouvez passer directement à cette version, mais en suivant les notes des versions intermédiaires
* Suivez ensuite la procédure classique de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)
* Lancer le script de migration de la base de données :

  Cette nouvelle version de GeoNature intègre les mailles INPN (1, 5, 10km) dans le réferentiel géographique. Si vous ne souhaitez pas les installer, lancer le script ci dessous en passant le paramètre ``no-grid``

  ::

    cd /home/`whoami`/geonature/data/migrations
    # avec les mailles
    ./2.0.1to2.1.0.sh
    # sans les mailles:
    # ./2.0.1to2.1.0.sh no-grid

* Installer le module VALIDATION si vous le souhaitez :

  Se placer dans le virtualenv de GeoNature

  ::

    cd /home/`whoami`/geonature/backend
    source venv/bin/activate

  Lancer la commande d'installation du module puis sortir du virtualenv

  ::

    geonature install_gn_module /home/`whoami`/geonature/contrib/gn_module_validation/ /validation
    deactivate

2.0.1 (2019-03-18)
------------------

**🚀 Nouveautés**

* Développement : ajout d'une fonction de génération dynamique de requête SQL (avec vérification et cast des types)
* Synthese : Ajout d'un message indiquant que le module affiche les dernières observations par défaut

**🐛 Corrections**

* Synthese : correction du filtre CRUVED pour les portées 1 et 2 sur la route ``synthese/for_web`` (#584)
* Synthese : correction du bug lorsque la géométrie est null (#580)
* Synthese : Correction de la redirection vers le module de saisie (#586)
* Synthese : Correction de la valeur par défaut de la nomenclature ``STATUT_OBS`` (``Présent`` au lieu de ``NSP``)
* Configuration carto : correction du bug d'arrondissement des coordonnées géographiques (#582)
* Correction du trigger de calcul de la geom locale
* Recréation de la vue ``pr_occtax.export_occtax_sinp`` qui avait été supprimée lors de la migration RC3 vers RC4
* Correction de la vue ``pr_occtax.v_releve_list``
* Correction ajout rang et cd_nom sur l'autocomplete de la synthese, absent dans le script de migration
* DEPOBIO : Correction de la déconnexion au CAS INPN
* Occtax et Metadata: correction lors de la mise à jour d'un élement (Merge mal géré par SQLAlchemy lorsqu'on n'a pas une valeur NULL) (#588)
* Composant "jeu de données" : retour à l'affichage du nom long (#583)
* Amélioration du style du composant multiselect
* Metadata : formulaire cadre d'acquisition - listage uniquement des cadres d'acquisition parent pour ne pas avoir de cadres d'acquisition imbriqués
* Ajouts de tests automatisés complémentaires

**⚠️ Notes de version**

* Vous pouvez passer directement à cette version, mais en suivant les notes des versions intermédiaires
* Exécuter le script de migration SQL du sous-module Nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module/blob/1.2.4/data/update1.2.3to1.2.4.sql)
* Exécuter le script de migration SQL de GeoNature (https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.0.0to2.0.1.sql)
* Suivez ensuite la procédure classique de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)

2.0.0 - La refonte (2019-02-28)
-------------------------------

La version 2 de GeoNature est une refonte complète de l'application.

* Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à Python3/Flask/Angular4/Leaflet
* Refonte de l'architecture du code pour rendre GeoNature plus générique et modulaire
* Refonte de la base de données pour la rendre plus standardisée, plus générique et modulaire
* Refonte ergonomique pour moderniser l'application

.. image :: http://geonature.fr/img/gn-login.jpg

Pour plus de détails sur les évolutions apportées dans la version 2, consultez les détails des versions RC (Release Candidate) ci-dessous.

**Nouveautés**

* Possibilité de charger un fichier (GPX, GeoJson ou KML) sur la carte pour la saisie dans le module Occtax (#256)
* Ajout d'un moteur de recherche de lieu (basé sur l'API OpenStreetMap Nominatim) sur les modules cartographiques (#476)
* Intégration du plugin leaflet markerCluster permettant d'afficher d'avantage d'observations sur les cartes et de gérer leurs superposition (#559)
* Synthèse : possibilité de grouper plusieurs types de zonages dans le composant ``pnx-areas``
* Design de la page de login
* Intégration d'un bloc stat sur la page d'accueil
* Ajout d'un export des métadonnées dans la synthèse
* Centralisation de la configuration cartographique dans la configuration globale de GeoNature (``geonature_config.toml``)
* Cartographie : zoom sur l'emprise des résultats après une recherche
* Migration de la gestion des métadonnées dans un module à part : 'METADATA' (#550)
* Export vue synthèse customisable (voir doc)
* Lien vers doc par module (customisables dans ``gn_commons.t_modules``) (#556)
* Ajout du code du département dans les filtres par commune (#555)
* Ajout du rang taxonomique et du cd_nom après les noms de taxons dans la recherche taxonomique (#549)
* Mise à jour des communes fournies lors de l'installation (IGN admin express 2019) (#537)
* Synthèse : Ajout du filtre par organisme (#531), affichage des acteurs dans les fiches détail et les exports
* Synthese: possibilité de filtrer dans les listes déroulantes des jeux de données et cadres d'acquisition
* Filtre de la recherche taxonomique par règne et groupe INPN retiré des formulaires de recherche (#531)
* Suppression du champ validation dans le schéma de BDD Occtax car cette information est stockée dans la table verticale ``gn_commons.t_validations`` + affichage du statut de validation dans les fiches Occtax et Synthèse
* Ajout d'une vue ``gn_commons.v_lastest_validation`` pour faciliter la récupération du dernier statut de validation d'une observation
* Suppression de toutes les références à ``taxonomie.bib_noms`` en vue de le supprimer de TaxHub
* Séparation des commentaires sur l'observation et sur le contexte (relevé) dans la Synthèse et simplification des triggers de Occtax vers Synthèse (#478)
* Nouveau logo GeoNature (#346)

**Corrections**

* Améliorations importantes des performances de la synthèse (#560)
* Synthèse : correction liée aux filtres multiples et aux filtres géographiques de type cercle
* Ajout d'une contrainte ``DELETE CASCADE`` entre ``ref_geo.li_municialities`` et ``ref_geo.l_areas`` (#554)
* Occtax : possibilité de saisir un dénombrement égal à 0 (cas des occurrences d'absence)
* Occtax : retour à l'emprise cartographique précédente lorsqu'on enchaine les relevés (#570)
* Occtax : correction de l'automplissage du champ ``hour_max`` lors de l'édition d'un relevé
* Divers compléments de la documentation (merci @jbdesbas, @xavyeah39 et @DonovanMaillard)
* Ajout de contraintes d'unicité sur les UUID_SINP pour empêcher les doublons (#536)
* Corrections et compléments des tests automatiques
* Amélioration de l'installation des modules GeoNature

**Notes de version**

**1.** Pour les utilisateurs utilisant la version 1 de GeoNature :

Il ne s'agit pas de mettre à jour GeoNature mais d'en installer une nouvelle version. En effet, il s'agit d'une refonte complète.

* Sauvegarder toutes ses données car l'opération est complexe et non-automatisée
* Passer à la dernière version 1 de GeoNature (1.9.1)
* Passer aux dernières versions de UsersHub et TaxHub
* Installer GeoNature standalone ou refaire une installation complète
* Adaptez les scripts présents dans ``/data/migrations/v1tov2`` et exécutez-les pas à pas. Attention ces scripts ont été faits pour la version 2.0.0-rc.1 et sont donc à ajuster, tester, compléter et adapter à votre contexte

**2.** Pour les utilisateurs utilisant une version RC de GeoNature 2 :

Veuillez bien lire ces quelques consignes avant de vous lancer dans la migration.

* Vous pouvez passer directement à cette version, mais en suivant les notes des versions intermédiaires.
* Les personnes ayant configuré leur fichier ``map.config.ts`` devront le répercuter dans ``geonature_config.toml``, suite à la centralisation de la configuration cartographique (voir https://github.com/PnX-SI/GeoNature/blob/2.0.0/config/default_config.toml.example section ``[MAPCONFIG]``).
* La configuration des exports du module synthèse a été modifiée (voir https://geonature.readthedocs.io/fr/latest/admin-manual.html#module-synthese). Supprimer la variable``[SYNTHESE.EXPORT_COLUMNS]`` dans le fichier ``geonature_config.toml``. Voir l'exemple dans le fichier (voir https://github.com/PnX-SI/GeoNature/blob/2.0.0/config/default_config.toml.example section) pour configurer les exports.
* Supprimer la variable ``COLUMNS_API_SYNTHESE_WEB_APP`` si elle a été ajoutée dans le fichier ``geonature_config.toml``.
* Pour simplifier son édition, le template personalisable de la page d'accueil (``frontend/src/custom/components/introduction/introduction.component.html``) a été modifié (la carte des 100 dernière observations n'y figure plus). Veuillez supprimer tout ce qui se situe à partir de la ligne 21 (``<div class="row row-0">``) dans ce fichier.
* Exécuter le script de migration SQL: https://github.com/PnX-SI/GeoNature/blob/2.0.0/data/migrations/2.0.0rc4.2to2.0.0.sql.
* Le backoffice de gestion des métadonnées est dorénavant un module GeoNature à part. Le script migration précédemment lancé prévoit de mettre un CRUVED au groupe_admin et groupe_en_poste pour le nouveau module METADATA. Les groupes nouvellement créés par les administrateurs et n'ayant de CRUVED pour l'objet METADATA (du module Admin), se retrouvent avec le CRUVED hérité de GeoNature. L'administrateur devra changer lui-même le CRUVED de ces groupes pour le nouveau module METADATA via le backoffice des permissions.
* Suivez ensuite la procédure classique de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application).


2.0.0-rc.4.2 (2019-01-23)
-------------------------

**Nouveautés**

* Mise en place de logs rotatifs pour éviter de surcharger le serveur
* Centralisation des logs applicatifs dans le dossier ``var/log/gn_errors.log`` de GeoNature

**Corrections**

* Synthèse - Correction et amélioration de la gestion des dates (#540)
* Amélioration des tests automatisés
* Correction et complément ds scripts d'installation des modules GeoNature
* Remplacement de ``gn_monitoring.cor_site_application`` par ``gn_monitoring.cor_site_module``
* Complément des documentations de customisation, d'administration et de développement
* Ajout d'une documentation de migration de données Serena vers GeoNature (https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/serena) par @xavyeah39

**Note de version**

* Vous pouvez passer directement à cette version, mais en suivant les notes des versions intermédiaires
* Exécutez la mise à jour de la BDD GeoNature (``data/migrations/2.0.0rc4.1to2.0.0rc4.2.sql``)
* Depuis la version 2.0.0-rc.4, on ne stocke plus les modules de GeoNature dans ``utilisateurs.t_applications``. On ne peut donc plus associer les sites de suivi de ``gn_monitoring`` à des applications, utilisé par les modules de suivi (Flore, habitat, chiro). Le mécanisme est remplacé par une association des sites de suivi aux modules. La création de la nouvelle table est automatisée (``data/migrations/2.0.0rc4.1to2.0.0rc4.2.sql``), mais pas la migration des éventuelles données existantes de ``gn_monitoring.cor_site_application`` vers ``gn_monitoring.cor_site_module``, à faire manuellement.
* Afin que les logs de l'application soient tous écrits au même endroit, modifier le fichier ``geonature-service.conf`` (``sudo nano /etc/supervisor/conf.d/geonature-service.conf``). A la ligne ``stdout_logfile``, remplacer la ligne existante par ``stdout_logfile = /home/<MON_USER>/geonature/var/log/gn_errors.log`` (en remplaçant <MON_USER> par votre utilisateur linux).
* Vous pouvez également mettre en place un système de logs rotatifs (système permettant d'archiver les fichiers de logs afin qu'ils ne surchargent pas le serveur - conseillé si votre serveur a une capacité disque limitée). Créer le fichier suivant ``sudo nano /etc/logrotate.d/geonature`` puis copiez les lignes suivantes dans le fichier nouvellement créé (en remplaçant <MON_USER> par votre utilisateur linux)

  ::

    /home/<MON_USER>/geonature/var/log/*.log {
    daily
    rotate 8
    size 100M
    create
    compress
    }

  Exécutez ensuite la commande ``sudo logrotate -f /etc/logrotate.conf``
* Suivez ensuite la procédure classique de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)


2.0.0-rc.4.1 (2019-01-21)
-------------------------

**Corrections**

* Mise à jour des paquets du frontend (#538)
* Correction d'un conflit entre Marker et Leaflet-draw
* Utilisation du paramètre ``ID_APP`` au niveau de l'application
* Corrections mineures diverses

**Note de version**

* Sortie de versions correctives de UsersHub (2.0.2 - https://github.com/PnEcrins/UsersHub/releases) et TaxHub (1.6.1 - https://github.com/PnX-SI/TaxHub/releases) à appliquer aussi
* Vous pouvez vous référer à la documentation globale de mise à jour de GeoNature RC3 vers RC4 par @DonovanMaillard (https://github.com/PnX-SI/GeoNature/blob/master/docs/update-all-RC3-to-RC4.rst)


2.0.0-rc.4 (2019-01-15)
-----------------------

**Nouveautés**

* Intégration de la gestion des permissions (CRUVED) dans la BDD de GeoNature, géré via une interface d'administration dédié (#517)
* Mise en place d'un système de permissions plus fin par module et par objet (#517)
* Mise en place d'un mécanimse générique pour la gestion des permissions via des filtres : filtre de type portée (SCOPE), taxonomique, géographique etc... (#517)
* Compatibilité avec UsersHub version 2
* L'administration des permissions ne propose que les rôles qui sont actif et qui ont un profil dans GeoNature
* Ajout du composant Leaflet.FileLayer dans le module Synthèse pour pouvoir charger un GeoJSON, un GPS ou KML sur la carte comme géométrie de recherche (#256)
* Ajout et utilisation de l'extension PostgreSQL ``pg_tgrm`` permettant d'améliorer l'API d'autocomplétion de taxon dans la synthèse, en utilisant l'algorithme des trigrammes (http://si.ecrins-parcnational.com/blog/2019-01-fuzzy-search-taxons.html), fonctionnel aussi dans les autres modules si vous mettez à jour TaxHub en version 1.6.0.
* Nouvel exemple d'import de données historiques vers GeoNature V2 : https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/2018-12-csv-vers-synthese-FLAVIA.sql (par @DonovanMaillard)
* Complément de la documentation HTTPS et ajout d'une documentation Apache (par @DonovanMaillard, @RomainBaghi et @lpofredc)

**Corrections**

* Correction de l'id_digitiser lors de la mise à jour (#481)
* Corrections multiples de la prise en compte du CRUVED (#496)
* Deconnexion apres inactivité de l'utilisateur (#490)
* Suppression des heures au niveau des dates de l'export occtax (#485)
* Correction du message d'erreur quand on n'a pas de JDD (#479)
* Correction du champs commentaire dans les exports d'Occtax séparé entre relevé et occurrence (#478)
* Correction des paramètres de la fonction ``GenericQuery.build_query_filter()`` (par @patkap)
* Correction de l'administration des métadonnées (#466 #420)
* Métadonnées (JDD et CA) : ne pas afficher les utilisateurs qui sont des groupes dans les acteurs
* Ajout d'un champs dans la Synthèse permettant de stocker de quel module provient une occurrence et fonctions SQL associées (#412)
* Amélioration du style des champs obligatoires
* Améliorations mineures de l'ergonomie d'Occtax
* Correction du spinner qui tournait en boucle lors de l'export CSV de la Synthèse (#451)
* Correction des tests automatisés
* Amélioration des performances des intersections avec les zonages de ``ref_geo.l_areas``
* Complément de la documentation de développement
* Simplification de la configuration des gn_modules
* Occtax : ordonnancement des observation par date (#467)
* Occtax : Remplissage automatique de l'heure_max à partir de l'heure_min (#522)
* Suppression des warnings lors du build du frontend
* Correction de l'installation des modules GeoNature
* Ajout d'un message quand on n'a pas accès à une donnée d'un module
* Affichage du nom du module dans le Header (#398)
* Correction des outils cartographiques dans Occtax
* Correction complémentaire des styles des lignes sans remplissage (#458)
* MaplistService : correction du zoom sur les polygones et polylignes
* Composant Areas et Municipalities : remise à zéro de la liste déroulante quand on efface la recherche ou remet à jour les filtres
* Composant Taxonomy : la recherche autocompletée est lancée même si on tape plus de 20 caractères. Le nombre de résultat renvoyé est désormais paramétrable (#518)
* Limitation du nombre de connexions à la BDD en partageant l'instance ``DB`` avec les sous-modules
* Installation : utilisation d'un répertoire ``tmp`` local et non plus au niveau système pour limiter les problèmes de droits (#503)
* Evolution du template d'exemple de module GeoNature (https://github.com/PnX-SI/GeoNature/tree/master/contrib/module_example) pour utiliser l'instance DB et utiliser les nouveaux décorateurs de permissions (CRUVED)

**Note de version**

* Si vous effectuez une migration de GeoNature RC3 vers cette nouvelle version, il est nécessaire d'avoir installé UsersHub version 2.x au préalable. Suivez donc sa documentation (https://github.com/PnEcrins/UsersHub/releases) avant de procéder à la montée de version de GeoNature.
* Exécuter la commande suivante pour ajouter l'extension ``pg_trgm``, en remplaçant la variable ``$db_name`` par le nom de votre BDD : ``sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"``
* Mettez à jour TaxHub en version 1.6.0 pour bénéficier de l'amélioration de la recherche taxonomique dans tous les modules
* Exécutez la mise à jour de la BDD GeoNature (``data/migrations/2.0.0rc3.1-to-2.0.0rc4.sql``)
* Suivez ensuite la procédure classique de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)

**Note développeurs**

* Vous pouvez faire évoluer les modules GeoNature en utilisant l'instance ``DB`` de GeoNature pour lancer les scripts d'installation (#498)
* Il n'est plus nécéssaire de définir un ``id_application`` dans la configuration des modules GeoNature.
* La gestion des permissions a été revue et est désormais internalisée dans GeoNature (voir https://geonature.readthedocs.io/fr/develop/development.html#developpement-backend), il est donc necessaire d'utiliser les nouveaux décorateurs décrit dans la doc pour récupérer le CRUVED.


2.0.0-rc.3.1 (2018-10-21)
-------------------------

**Corrections**

* Correction du script ``ìnstall_all.sh`` au niveau de la génération de la configuration Apache de TaxHub et UsersHub (#493)
* Suppression du Servername dans la configuration Apache de TaxHub du script ``install_all.sh``
* Complément de la documentation de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)

**Notes de version**

* Si vous migrez depuis une version 2.0.0-rc.2, installez directement cette version corrective plutôt que la 2.0.0-rc.3, mais en suivant les notes de versions de la 2.0.0-rc.3
* Pour mettre en place la redirection de TaxHub sans ``/``, consultez sa documentation https://taxhub.readthedocs.io/fr/latest/installation.html#configuration-apache
* Le script ``install_all.sh`` actuel ne semble pas fonctionner sur Debian 8, problème de version de PostGIS qui ne s'installe pas correctement


2.0.0-rc.3 (2018-10-18)
-----------------------

* Possibilité d'utiliser le MNT en raster ou en vecteur dans la BDD (+ doc MNT) #439 (merci @mathieubossaert)
* INSTALL_ALL - gestion du format date du serveur PostgreSQL (#435)
* INSTALL_ALL - Amélioration de la conf Apache de TaxHub pour gérer son URL sans ``/`` à la fin
* Dessin cartographique d'une autre couleur (rouge) que les observations (bleu)
* Occtax : retour au zoom précédent lors de l'enchainement de relevé (#436)
* Occtax : observateur rempli par défaut avec l'utilisateur connecté (#438)
* Prise en compte des géométries nulles dans la fonction ``serializegeofn``
* Gestion plus complète des données exemple intégrées ou non lors de l'installation (#446)
* Complément des différentes documentations
* Complément FAQ (#441)
* Documentation de la customisation (merci @DonovanMaillard)
* Amélioration de l'architecture du gn_module d'exemple
* Clarification de la configuration des gn_modules
* Lire le fichier ``VERSION`` pour l'afficher dans l'interface (#421)
* Utilisation de la vue ``export_occtax_sinp`` et non plus ``export_occtax_dlb`` par défaut pour les exports Occtax (#462)
* Complément et correction des vues ``export_occtax_sinp`` et ``export_occtax_dlb`` (#462)
* Mise à jour de Marshmallow (2.5.0 => 2.5.1)
* Améliorations des routes de ``gn_monitoring`` et de la configuration des modules de suivi pour pouvoir utiliser le nom d'une application plutôt que son identifiant
* Export Synthèse - Remplacement de la barre de téléchargement par un spinner (#451)

**Corrections**

* Doc Import niveau 2 : Corrections et compléments
* Correction du trigger Occtax > Synthèse qui met à jour le champs ``gn_synthese.observers_txt`` et les commentaires (#448 et #459)
* Correction et amélioration de la fonction ``install_gn_module``
* Correction coquille dans le modèle ``gn_monitoring`` et la fonction ``serializegeofn``
* Installation uniquement sur un environnement 64 bits (documentation + vérification) #442 (merci @jbrieuclp et @sig-pnrnm)
* Correction et découpage des scripts de mise à jour de la BDD depuis la version Beta5
* Correction de l'édition des date_debut et date_fin de Occtax (#457)
* Correction des exports depuis la Synthèse et intégration de la géométrie des observations (#461 et #456)
* Ne pas remplir ``pr_occtax.cor_role_releves_occtax`` si ``observers_txt = true`` (#463)
* Edition d'un relevé Occtax - Ne pas recalculer l'altitude existante (#424)
* Correction de l'activation du formulaire Occtax après localisation du relevé (#469 et #471)
* Carte - Enlever le remplissage des lignes (#458)
* Amélioration du script de mise à jour de GeoNature (``install/migration/migration.sh``) (#465)
* Suppression d'un doublon dans le modèle de ``gn_commons.t_modules`` (merci @lpofredc)

**Autres**

* Mise à jour de TaxHub (Doc utilisateur, configuration Apache, script d'import des médias depuis API INPN Taxref et remise à zéro des séquences)
* Script de migration des données SICEN (ObsOcc) vers GeoNature : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/sicen
* Script d'import continu depuis une BDD externe vivante (avec exemple SICEN) : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/generic
* Module Suivi Flore Territoire fonctionnel et installable (https://github.com/PnX-SI/gn_module_suivi_flore_territoire)
* Module Suivi Chiro fonctionnel et installable (https://github.com/PnCevennes/gn_module_suivi_chiro) ainsi que son Frontend générique pour les protocoles de suivi (https://github.com/PnCevennes/projet_suivis_frontend/)
* Ebauche d'un module pour les protocoles CMR (Capture-Marquage-Recapture) : https://github.com/PnX-SI/gn_module_cmr
* MCD du module Suivi Habitat Territoire (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire)
* MCD du module Flore Prioritaire (https://github.com/PnX-SI/gn_module_flore_prioritaire)
* Consolidation du backend et premiers développements du frontend de GeoNature-citizen (https://github.com/PnX-SI/GeoNature-citizen)
* Création d'un script expérimental d'installation de GeoNature-atlas compatible avec GeoNature V2 dt pouvant utiliser son schéma ``ref_geo`` pour les communes, le territoire et les mailles (https://github.com/PnEcrins/GeoNature-atlas/blob/develop/install_db_gn2.sh)

**Notes de version**

* Suivez la procédure standard de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)
* Exécutez l'update de la BDD GeoNature (``data/migrations/2.0.0rc2-to-2.0.0rc3.sql``)
* Il est aussi conseillé de mettre à jour TaxHub en 1.5.1 (https://github.com/PnX-SI/TaxHub/releases) ainsi que sa configuration pour qu'il fonctionne sans ``/`` à la fin de son URL
* Attention, si vous installez cette version avec le script global ``install_all.sh``, il créé un problème dans la configuration Apache de UserHub (``/etc/apache2/sites-available/usershub.conf``) et supprime tous les ``/``. Les ajouter sur la page de la documentation de UsersHub (https://github.com/PnEcrins/UsersHub/blob/master/docs/installation.rst#configuration-apache) puis relancer Apache (``https://github.com/PnEcrins/GeoNature-atlas/blob/develop/docs/installation.rst``). Il est conseillé d'installer plutôt la version corrective.


2.0.0-rc.2 (2018-09-24)
-----------------------

**Nouveautés**

* Script ``install_all.sh`` compatible Ubuntu (16 et 18)
* Amélioration du composant Download
* Amélioration du ShapeService
* Compléments de la documentation
* Intégration de la documentation Développement backend dans la documentation
* Nettoyage du code
* Mise à jour de la doc de l'API : https://documenter.getpostman.com/view/2640883/RWaPskTw
* Configuration de la carte (``frontend/src/conf/map.config.ts``) : OSM par défaut car OpenTopoMap ne s'affiche pas à petite échelle

**Corrections**

* Correction du script ``install/migration/migration.sh``
* Ne pas afficher le debug dans le recherche de la synthèse
* Correction du bug de déconnexion entre TaxHub et GeoNature (#423)
* Correction de la fiche info d'Occtax
* Champs Multiselect : Ne pas afficher les valeurs selectionnées dans la liste quand on modifie un objet
* Trigger Occtax vers Synthèse : Correction des problèmes d'heure de relevés mal copiés dans la Synthèse
* Correction des altitudes (non abouti) (#424)
* Données exemple : Suppression de l'``observers_txt`` dans la synthèse
* Suppression d'un ``id_municipality`` en dur dans une route
* Suppression de la librairie Certifi non utilisée

**Notes de version**

* Suivez la procédure standard de mise à jour de GeoNature
* Exécuter l'update de la BDD GeoNature (``data/migrations/2.0.0rc1-to-2.0.0rc2.sql``)


2.0.0-rc.1 (2018-09-21)
-----------------------

La version 2 de GeoNature est une refonte complète de l'application.

* Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à Python3/Flask/Angular4/Leaflet
* Refonte de l'architecture du code pour rendre GeoNature plus générique et modulaire
* Refonte de la base de données pour la rendre plus standarde, plus générique et modulaire
* Refonte ergonomique pour moderniser l'application

Présentation et suivi des développements : https://github.com/PnX-SI/GeoNature/issues/168

**Accueil**

* Message d'introduction customisable
* Carte des 100 dernières observations
* CSS général de l'application surcouchable

**Occtax**

Module permettant de saisir, consulter, rechercher et exporter des données Faune, Flore et Fonge de type Contact selon le standard Occurrences de taxon du SINP (https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon).

* Développement des formulaires de saisie, page de recherche, fiche détail, API, CRUVED et export
* Possibilité de masquer ou afficher les différents champs dans le formulaire Occtax (#344)
* Développement du formulaire de manière générique pour pouvoir réutiliser ses différents éléments dans d'autres modules sous forme de composants Angular
* Configuration possible du module (Niveau de zoom, champs affichées, export...)
* Ajout des nomenclatures dans les filtres d'Occtax à partir du composant ``dynamicForm`` qui permet de créer dynamiquement un formulaire en déclarant ses champs et leur type (#318)
* Amélioration du composant de recherche d'un taxon en ne recherchant que sur les débuts de mot et en affichant en premier les noms de référence (``ordrer_by cd_nom=cd_ref DESC``) #334
* Multilingue fourni avec français et anglais (extensible à d'autres langues)
* Mise en place d'un export CSV, SHP, GeoJSON paramétrable dans Occtax. #363 et #366
* Ajout d'un message d'erreur si l'utilisateur n'a pas de jeu de données ou si il y a eu un problème lors de la récupération des JDD depuis MTD
* Prise en compte du CRUVED au niveau des routes et du front pour adapter les contenus et fonctionnalités aux droits de l'utilisateur
* Mise en place des triggers alimentant la synthèse à partir des données saisies et modifiées dans Occtax

**Synthèse**

Module permettant de rechercher parmi les données des différentes sources présentes ou intégrées dans la base de données de GeoNature

* Mise en place du backend, de l'API et du frontend #345
* Interface de consultation, de recherche et d'export dans la Synthèse
* Synthèse : Calcul automatique (trigger) des zonages de chaque observation (communes, zonages réglementaires et naturels)
* Recherche sur les zonages générique et paramétrable
* Recherche par taxon, liste de taxons, par rang, groupe, liste rouge, milieu, attribut taxonomique, nomenclature, date, période, commune, zonage, cadre d'acquisition, jeu de données, observateur, polygone, rectange ou cercle dessiné
* Retour à la fiche source possible si l'observation a été saisie dans un module de GeoNature
* Affichage de la fiche détail de chaque observation
* Attributs TaxHub dynamiques et paramétrables
* Configuration possible du module (colonnes, limites de recherche et d'export, zoom, export...)
* Export basé sur une vue (observations et statuts)
* Prise en compte du CRUVED pour définir les données à afficher et à exporter #412
* Recherche de taxons : Liste basée sur une table alimentée automatiquement par les taxons présents au moins une fois dans la Synthèse

**Export**

Module permettant de proposer des exports basés sur des vues

* Mise en place temporaire d'un export unique, basé sur une vue s'appuyant sur les données de Occtax, par jeu de données
* A remplacer par le module générique https://github.com/PnX-SI/gn_module_export (en cours de développement) permettant de générer des exports à volonté en créant des vues et en les affectant à des utilisateurs ou des groupes. Chaque export sera accompagné de son API standardisée et documentée

**Admin**

Module d'administration des tables centrales de GeoNature

* Mise en place d'un module (incomplet) permettant de gérer les métadonnées et les nomenclatures

**Gestion des droits**

* Mise en place d'un système baptisé CRUVED permettant de définir globalement ou par module 6 actions sont possibles (Create / Read / Update / Validate / Export / Delete) sur 3 portées possibles (Mes données / Les données de mon organisme / Toutes les données)
* Ces évolutions ont été intégrées au niveau du schéma ``utilisateurs`` de la base de données de UsersHub, de son module (https://github.com/PnX-SI/UsersHub-authentification-module), des routes de l'API GeoNature et des interfaces

**Bases de données**

* Développement d'un module et d'une API générique et autonome pour la gestion des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module). Il permet d'avoir un mécanisme générique de centralisation des listes de valeurs (nomenclatures) pour ne pas créer des tables pour chaque liste : https://github.com/PnX-SI/Nomenclature-api-module. Les valeurs de chaque nomenclature s'adaptent en fonction des regnes et groupe 2 INPN des taxons.
* Mise en place de tables de stockage verticales (historique, médias et validation) #339
* Mise en place d'un référentiel géographique avec un schéma dédié (``ref_geo``), partageable avec d'autres applications comprenant une table des communes, une table générique des zonages, une table pour le MNT et des fonctions pour intersecter point/ligne/polygones avec les zonages et le MNT (#228)
* Evolution du schéma ``utilisateurs`` de UsersHub pour passer d'une gestion des droits avec 6 niveaux à un mécanisme plus générique, souple et complet. Il permet d'attribuer des actions possibles à un rôle (utilisateur ou groupe), sur une portée; dans une application ou un module. 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
* Droits CRUVED : La définition du CRUVED d'un rôle (utilisateur ou groupe) sur un module de GeoNature surcouche ses droits GeoNature même si ils sont inférieurs. Si une action du CRUVED n'est pas définie au niveau du module, on prend celle de l'application parente. #292
* Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne lui est pas listé dans le Menu et il ne lui est pas accessible si il en connait l'URL. #360
* Développement des métadonnées dans la BDD (schéma ``gn_meta``) sur la base du standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/). Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles. Chaque relevé est associé à un jeu de données.
* Développement d'un mécanisme de calcul automatique de la sensibilité d'une espèce directement dans la BDD (sur la base des règles nationales et régionales du SINP + locales éventuellement)
* Intégration du calcul automatique de l'identifiant permanent SINP (#209)
* Création du schéma ``gn_monitoring`` pour gérer la partie générique des modules de suivi (sites et visites centralisés) et les routes associées
* Mise en place d'un schéma ``gn_commons`` dans la BDD qui permet de stocker de manière générique des informations qui peuvent être communes aux autres modules : l'historique des actions sur chaque objet de la BDD, la validation d'une donnée et les médias associés à une donnée. Accompagné de fonctions génériques d'historisation et de validation des données mises en place sur le module Occtax. #339
* Ajout d'une vue matérialisée (``gn_synthese.vm_min_max_for_taxons``) et d'une fonction (``gn_synthese.fct_calculate_min_max_for_taxon``) permettant de renvoyer des informations sur les observations existantes d'un taxon (étendue des observations, date min et max, altitude min et max, nombre d'observations) pour orienter la validation et la saisie (https://github.com/PnX-SI/gn_module_validation/issues/5). Désactivée pour le moment.
* Ajout d'un trigger générique pour calculer la géométrie dans la projection locale à partir de la géométrie 4326 (#370)
* Ajout d'un trigger pour calculer automatiquement les zonages des sites de suivi (``gn_monitoring.fct_trg_cor_site_area()``)
* Gestion des conflits de nomenclatures en n'utilisant plus leur ``id_type`` ni leur ``id_nomenclature`` lors de la création de leur contenu (code_nomenclature) (#384)
* Mise en place d'un schéma ``gn_imports`` intégrant des fonctions SQL permettant d'importer un CSV dans la BDD et de mapper des champs de tables importées avec ceux d'une table de GeoNature pour générer le script ``INSERT INTO``
* Début de script de migration GeoNature V1 vers GeoNature V2
* Nombreuses fonctions intégrées dans les schémas de la BDD

**Installation**

* Scripts d'installation autonome ou globale de GeoNature sur Debian (8 et 9) et Ubuntu (16 et 18)
* Scripts de déploiement spécifiques de DEPOBIO (MTES-MNHN)

**Documentation**

* Rédaction d'une documentation concernant l'installation (autonome ou globale), l'utilisation, l'administration et le développement : https://geonature.readthedocs.io

**Développement**

* Découpage de l'application en backend / API / Frontend
* Multilingue au niveau de l'interface et des listes de valeurs avec français et anglais intégrés mais extensible à d'autres langues (#173)
* Développement de composants Angular génériques pour pouvoir les utiliser dans plusieurs modules sans avoir à les redévelopper ni les dupliquer (composant CARTE, composant RECHERCHE TAXON, composant OBSERVATEURS, composant NOMENCLATURES, SelectSearch, Municipalities, Observers, DynamicForm, MapList...)
* Implémentation de la gestion des droits au niveau de l'API (pour limiter les données affichées à un utilisateur en fonction de ses droits) et au niveau du Frontend (pour afficher ou non certains boutons aux utilisateurs en fonction de leurs droits).
* Par défaut, l'authentification et les utilisateurs sont gérés localement dans UsersHub, mais il est aussi possible de connecter GeoNature directement au CAS de l'INPN, sans UsersHub (cas de l'instance nationale INPN de GeoNature).
* Connexion possible au webservice METADONNEES de l'INPN pour y récupérer les jeux de données en fonction de l'utilisateur connecté, avec mise à jour des JDD à chaque appel de la route
* Mise en place d'un mécanisme standardisé de développement de modules dans GeoNature (#306)
* Ajout de tests unitaires au niveau du backend et du frontend
* Ajout d'un mécanisme de log par email (paramètres MAILERROR)
* Début de création du module de gestion des médias (backend uniquement)
* Mise en place d'une configuration globale et d'une configuration par module
* Fonction d'installation d'un module et de génération des fichiers de configuration
* Gestion de l'installation d'un module qui n'a pas de Frontend dans GeoNature
* Mise en place d'une route générique permettant de requêter dans une vue non mappée
* Mise en place d'un script pour la customisation de la plateforme nationale (https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh)

**Autres modules**

* Module Export en cours de développement (https://github.com/PnX-SI/gn_module_export). Chaque export s'appuie sur une vue. Il sera possible aux administrateurs d'une GeoNature d'ajouter autant de vues que nécessaires dans son GeoNature.
* Module de validation des données en cours de développement (https://github.com/PnX-SI/gn_module_validation/issues/4)
* Module Suivi Flore territoire en cours de développement (https://github.com/PnX-SI/gn_module_suivi_flore_territoire)
* Module Suivi Habitat en cours de développement (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/issues/1)
* gn_module_suivi_chiro refondu pour devenir un module de GeoNature V2 (https://github.com/PnCevennes/gn_module_suivi_chiro)
* Projet suivi utilisé comme Frontend générique et autonome pour le Suivi chiro (https://github.com/PnCevennes/projet_suivis_frontend)
* GeoNature-citizen en cours de développement (https://github.com/PnX-SI/GeoNature-citizen/issues/2)
* GeoNature-mobile en cours de refonte pour compatibilité avec GeoNature V2 (https://github.com/PnEcrins/GeoNature-mobile/issues/19)
* GeoNature-atlas en cours d'ajustements pour compatibilité avec GeoNature V2 (https://github.com/PnEcrins/GeoNature-atlas/issues/162)

**Notes de version**

**1.** Pour les utilisateurs utilisant la version 1 de GeoNature :

Il ne s'agit pas de mettre à jour GeoNature mais d'en installer une nouvelle version. En effet, il s'agit d'une refonte complète.

* Passer à la dernière version 1 de GeoNature (1.9.1)
* Idem pour UsersHub et TaxHub
* Installer GeoNature standalone ou refaire une installation complète
* Adaptez les scripts présents dans ``/data/migrations/v1tov2`` et éxécutez-les

*TODO : MAJ depuis V1 à  tester et compléter*

**2.** Pour les utilisateurs utilisant la version 2.0.0.beta5 :

* Supprimer le schéma ``gn_synthese`` puis le recréer dans sa version RC1 (#430)
* Exécuter l'update de la BDD GeoNature (``data/migrations/2.0.0beta5-to-2.0.0rc1.sql``) ainsi que celui du sous-module Nomenclature (https://github.com/PnX-SI/Nomenclature-api-module/blob/1.2.1/data/update1.1.0to1.2.1.sql)
* Suivre la procédure habituelle de mise à jour
* Exécuter les commandes suivantes :

  ::

    cd geonature/backend
    source venv/bin/activate
    geonature generate_frontend_modules_route
    geonature frontend_build


2.0.0.beta5 (2018-07-16)
------------------------

**Nouveautés**

* Ajout d'un message d'erreur si l'utilisateur n'a pas de JDD ou si il y a eu un problème lors de la récupération des JDD de MTD
* Ajout d'une vue matérialisée (``gn_synthese.vm_min_max_for_taxons``) et d'une fonction (``gn_synthese.fct_calculate_min_max_for_taxon``) permettant de renvoyer des informations sur les observations existantes d'un taxon (étendue des observations, date min et max, altitude min et max, nombre d'observations) pour orienter la validation et la saisie (https://github.com/PnX-SI/gn_module_validation/issues/5)
* L'export OccTax est désormais basé sur une vue qu'il est possible d'adapter
* Ajouts de nouveaux tests automatisés du code et mise en place de Travis pour les lancer automatiquement à chaque commit (https://travis-ci.org/PnX-SI/GeoNature)
* Ajout de données test
* Mise à jour des scripts de déploiement spécifiques de DEPOBIO (MTES)
* Déplacement de la table centrale de gestion des paramètres ``t_parameters`` dans le schéma ``gn_commons`` (#376)
* Ajout d'un trigger générique pour calculer la géométrie dans la projection locale à partir de la géométrie 4326 (#370)
* Regroupement des fichiers liés à l'installation et la mise à jour dans un répertoire dédié (``install``) (#383)
* Mise en place de scripts de migration global de la BDD (``data/migrations/2.0.0beta4to2.00beta5.sql``) et du schéma ``pr_occtax`` (``contrib/occtax/data/migration_2.0.0.beta4to2.0.0.beta5.sql``), d'un script générique de migration de l'application (``install/migration/migration.sh``) et d'une doc de mise à jour (https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst#mise-%C3%A0-jour-de-lapplication)
* Réintégration des fichiers de configuration, de logs et des modules externes dans les répertoires de l'application (#375)
* Ajout de routes à ``gn_monitoring``
* Ajout d'un trigger pour calculer automatiquement les zonages des sites de suivi (``gn_monitoring.fct_trg_cor_site_area()``)
* Améliorations et documentation des commandes d'installation d'un module
* Ajout des unités géographiques dans le schéma ``ref_geo``
* Ajout d'un bouton ``Annuler`` dans le formulaire Occtax
* Gestion des conflits de nomenclatures en n'utilisant plus leur ``id_type`` ni leur ``id_nomenclature`` (#384)
* Migration du SQL de ``ref_nomenclautres`` dans le dépôt du sous-module (https://github.com/PnX-SI/Nomenclature-api-module)
* Début de mise en place d'un backoffice (métadonnées et nomenclatures)

**Corrections**

* OccTax : Correction du double post
* OccTax : Correction des droits dans les JDD
* OccTax : Correction de l'affichage des observers_txt dans la fiche d'un relevé
* Correction de la gestion générique des médias
* Suppression du lien entre ``ref_geo`` et ``ref_nomenclatures`` (#374)
* Compléments et relecture de la documentation
* Correction

**Notes de version**

Si vous mettez à jour votre GeoNature depuis une Beta4 :

* Téléchargez la beta5 et renommer les répertoires :

::

    cd /home/myuser
    wget https://github.com/PnX-SI/GeoNature/archive/geonature2beta.zip
    unzip geonature2beta.zip
    mv /home/<mon_user>/geonature/ /home/<mon_user>/geonature_old/
    mv GeoNature-geonature2beta /home/<mon_user>/geonature/

* Exécutez le script de migration ``install/migration/beta4tobeta5.sh`` depuis la racine de votre GeoNature :

::

    cd geonature
   ./install/migration/beta4tobeta5.sh

Celui-ci va récupérer vos fichiers de configuration, déplacer les modules et appliquer les changements de la BDD.

* Si vous avez développé des modules externes, voir https://github.com/PnX-SI/GeoNature/issues/375, en ajoutant un lien symbolique depuis le répertoire ``external_modules`` et en réintégrant la configuration du module dans son répertoire ``config``

2.0.0.beta4 (2018-05-25)
------------------------

**Nouveautés**

* Synthèse : début de mise en place du backend, de l'API et du frontend #345
* Complément de la nomenclature des Méthodes de détermination et suppression du champs Complement_Determination. Merci @DonovanMaillard. #341
* Nouveaux composants Angular (SelectSearch, Municipalities, Observers)
* Amélioration de composants Angular (Date du jour par défaut, Option de tri des nomenclatures, DynamicForm
* Connexion à MTD INPN : Mise à jour des JDD à chaque appel de la route
* Finalisation du renommage de Contact en OccTax (BDD, API, backend)
* Droits CRUVED : La définition du CRUVED d'un rôle (utilisateur ou groupe) sur un module de GeoNature surcouche ses droits GeoNature même si ils sont inférieurs. Si une action du CRUVED n'est pas définie au niveau du module, on prend celle de l'application parente. #292
* Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne lui est pas listé dans le Menu et il ne lui ai pas accessible si il en connait l'URL. #360
* Mise en place d'un schéma ``gn_commons`` dans la BDD qui permet de stocker de manière générique des informations qui peuvent être communes aux autres modules : l'historique des actions sur chaque objet de la BDD, la validation d'une donnée et les médias associés à une donnée. Accompagné de fonctions génériques d'historisation et de validation des données mises en place sur le module Occtax. #339
* Amélioration de l'ergonomie du MapList de OccTax. #361
* Mise en place d'un export CSV, SHP, GeoJSON paramétrable dans OccTax. #363 et #366
* Amélioration du module générique ``gn_monitoring`` et de ses sous-modules https://github.com/PnCevennes/gn_module_suivi_chiro et https://github.com/PnCevennes/projet_suivis_frontend
* Amélioration et compléments des scripts d'installation
* Mise en place d'un script pour la customisation de la plateforme nationale (https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh)

**Documentation**

* Complément des différentes documentations
* Ajout d'une documentation d'administration d'OccTax (https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst#module-occtax)

2.0.0.beta3 (2018-03-28)
------------------------

**Nouveautés**

* Travail sur le module générique de Suivi intégré à GeoNature (``gn_monitoring``). Gestion des fichiers de configuration
* Gestion de l'installation d'un module qui n'a pas de Frontend dans GeoNature
* Mise en place de tests automatiques au niveau du Frontend
* Ménage et réorganisation du code du Frontend
* Factorisation et harmonisation des composants génériques Angular
* Suppression des blocs non fonctionnels sur la Home
* Mise à jour de la doc et du MCD
* Possibilité de masquer ou afficher les différents champs dans le formulaire Occtax (#344)
* Ajout des nomenclatures dans les filtres d'OccTax à partir du nouveau composant ``dynamicForm`` qui permet de créer dynamiquement un formulaire en déclarant les champs (#318)
* Amélioration du composant de recherche d'un taxon en ne recherchant que sur les débuts de mot et en affichant en premier les noms de référence (ordrer_by cd_nom=cd_ref DESC) - #334
* Mise en place d'une route générique permettant de requêter dans une vue non mappée
* Suppression des options vides dans les listes déroulantes des nomenclatures
* Ajout de quelques paramètres (niveau de zoom mini dans chaque module, ID de la liste des taxons saisissables dans Occtax...)

**Corrections**

* Correction de la pagination du composant MapList
* Correction des droits attribués automatiquement quand on se connecte avec le CAS
* Correction de l'installation optionnelle de UsersHub dans le script ``install_all.sh``

**Modules annexes**

* Début de refonte du module Suivi chiro (https://github.com/PnCevennes/gn_module_suivi_chiro) connecté au module générique de suivi de GeoNature, dont le front sera externe à GeoNature (https://github.com/PnCevennes/projet_suivi)
* Maquettage et avancée sur le module Validation (https://github.com/PnX-SI/gn_module_validation)
* Définition du module Suivi Habitat Territoire (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire)
* Piste de définition du module Interopérabilité (https://github.com/PnX-SI/gn_module_interoperabilite)

2.0.0.beta2 (2018-03-16)
------------------------

**Nouveautés**

* Compléments de la documentation (schéma architecture, administration, installation, développement, FAQ...)
* Amélioration de l'ergonomie du module OccTax (composant MapList, filtres, colonnes et formulaires) et du module Exports
* Amélioration du composant de recherche d'un taxon (#324)
* Amélioration et optimisation de la sérialisation des données
* Ajout de tests unitaires au niveau du backend
* Ajout d'un mécanisme de log par email (paramètres MAILERROR)
* Migration du module occtax dans le répertoire ``/contrib`` pour homogénéiser les modules
* Création du schéma ``gn_monitoring`` pour gérer la partie générique des modules de suivi (sites et visites centralisés)
* Début de création du module générique des protocoles de suivi
* Début de création du module de gestion des médias

**Corrections**

* Corrections de l'installation globale et autonome
* Renommage Contact en OccTax (en cours)
* Nettoyage du schéma des métadonnées (``gn_meta``)

2.0.0.beta1 (2018-02-16)
------------------------

La version 2 de GeoNature est une refonte complète de l'application.

* Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à Python3/Flask/Angular4/Leaflet
* Refonte de l'architecture du code pour rendre GeoNature plus générique et modulaire
* Refonte de la base de données pour la rendre plus standarde, plus générique et modulaire
* Refonte ergonomique pour moderniser l'application

Présentation et suivi du projet : https://github.com/PnX-SI/GeoNature/issues/168

**Nouveautés**

* Refonte de la base de données du module Contact, renommé en OccTax, s'appuyant sur le standard Occurrence de taxons du SINP (#183)
* Développement du module OccTax regroupant les contacts Faune, Flore, Fonge et Mortalité (avec formulaire de consultation et de saisie des données)
* Développement d'un module et d'une API générique et autonome pour la gestion des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module). Il permet d'avoir un mécanisme générique de centralisation des listes de valeurs (nomenclatures) pour ne pas créer des tables pour chaque liste : https://github.com/PnX-SI/Nomenclature-api-module. Les valeurs de chaque nomenclature s'adaptent en fonction des regnes et groupe 2 INPN des taxons.
* Découpage de l'application en backend / API / Frontend
* Multilingue au niveau de l'interface et des listes de valeurs avec français et anglais intégrés mais extensible à d'autres langues (#173)
* Développement de composants génériques pour pouvoir les utiliser dans plusieurs modules sans avoir à les redévelopper ni les dupliquer (composant CARTE, composant RECHERCHE TAXON, composant OBSERVATEURS, composant NOMENCLATURES...)
* Mise en place d'un référentiel géographique avec un schéma dédié (``ref_geo``), partageable avec d'autres applications comprenant une table des communes, une table générique des zonages, une table pour le MNT et des fonctions pour intersecter point/ligne/polygones avec les zonages et le MNT (#228)
* Evolution du schéma ``utilisateurs`` de UsersHub pour passer d'une gestion des droits avec 6 niveaux à un mécanisme plus générique, souple et complet. Il permet d'attribuer des actions possibles à un rôle (utilisateur ou groupe), sur une portée; dans une application ou un module. 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
* Implémentation de la gestion des droits au niveau de l'API (pour limiter les données affichées à un utilisateur en fonction de ses droits) et au niveau du Frontend (pour afficher ou non certains boutons aux utilisateurs en fonction de leurs droits).
* Par défaut, l'authentification et les utilisateurs sont gérés localement dans UsersHub, mais il est aussi possible de connecter GeoNature au CAS de l'INPN, sans utiliser GeoNature (utilisé pour l'instance nationale INPN de GeoNature). GeoNature peut aussi se connecter au webservice METADONNEES de l'INPN pour y récupérer les jeux de données en fonction de l'utilisateur connecté.
* Mise en place d'un module d'export. Chaque export s'appuie sur une vue. Il sera possible à chaque administrateur d'ajouter autant de vues que nécessaires dans son GeoNature. Pour le moment, un export au format SINP Occurrence de taxons a été intégré par défaut.
* Développement des métadonnées dans la BDD (schema ``gn_meta``) sur la base du standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/). Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles. Chaque relevé est associé à un jeu de données.
* Développement d'un mécanisme de calcul automatique de la sensibilité d'une espèce directement dans la BDD (sur la base des règles nationales et régionales du SINP + locales éventuellement)
* Intégration du calcul automatique de l'identifiant permanent SINP (#209)
* Mise en place d'un mécanisme standardisé de développement de modules dans GeoNature (#306)
* Scripts d'installation autonome ou globale de GeoNature sur Debian 8 et 9

**Documentation**

* Installation globale de GeoNature (avec TaxHub et UsersHub) / https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-all.rst
* Installation autonome de GeoNature / https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst
* Manuel utilisateur / https://github.com/PnX-SI/GeoNature/blob/develop/docs/user-manual.rst
* Manuel administrateur / https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst
* Développement (API, modules et composants) / https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst

Documentation complète disponible sur http://geonature.fr/docs/2-0-0-beta1

**A venir**

* Finalisation MCD du module Synthèse
* Triggers d'alimentation automatique de la Synthèse depuis le module OccTax
* Développement de l'interface du module Synthèse
* Amélioration et généricité du module OccTax (médias, import GPX, champs masquables et pseudo-champs)
* Généricité du module d'export
* Développement du module de validation (#181)
* Développement d'un module de suivi des habitats avec une gestion générique des sites et visites de suivi
* Développement d'un module de collecte citoyenne (#242)


1.9.1 (2018-05-17)
------------------

**Corrections**

* Installation - Suppression des couches SIG (communes, znieff...) pour les télécharger sur http://geonature.fr/data/inpn/layers/ et ainsi alléger le dépôt de 158 Mo.
* Compléments mineurs de la documentation
* Migration du script ``install_all`` en Debian 9. La doc et le script Debian 8 restent disponibles dans le répertoire ``docs/install_all``
* Corrections mineures de triggers
* Compatibilité avec TaxHub 1.3.2, UsersHub 1.3.1, GeoNature-atlas 1.3.2

**Notes de version**

* Vous pouvez passer directement d'une 1.7.X à la 1.9.1, en prenant en compte les notes des différentes versions intermédiaires, notamment les scripts de mise à jour de la BDD ainsi que les éventuels nouveaux paramètres à ajouter.
* Exécuter le script de mise à jour de la BDD ``data/update_1.9.0to1.9.1.sql``


1.9.0 (2017-07-06)
------------------

**ATTENTION : Les évolutions de cette version concernent aussi la webapi. Si vous utilisez les applications GeoNature-mobile, vous devez attendre la sortie d'une version de GeoNature-mobile-webapi (https://github.com/PnEcrins/GeoNature-mobile-webapi) compatible avec cette version 1.9.0 de GeoNature.** Coming soon !

A noter aussi que cette version de GeoNature est compatible avec GeoNature-atlas 1.2.4 et +.

**Nouveautés**

* Ajout de la création des index spatiaux à la création initiale de la base.
* Création ou mise à jour des géométries compatible PostGIS 2.
* Ajout du champ diffusable (oui/non) dans le formulaire web de saisie, uniquement pour ContactFaune et Mortalité (TODO : faire la même chose pour les autres protocoles).
* Multi-projection : Les versions antérieures de GeoNature n'étaient compatibles qu'avec la projection Lambert 93 (srid: 2154). Cette version permet de choisir sa projection locale. Elle ajoute un paramètre ``srid_local`` dans le ``config/settings.ini`` et renomme tous les champs ``the_geom_2154`` en ``the_geom_local`` des tables "métier".
  Ce paramètre est notamment utilisé lors de la création de la base pour affecter le srid de la projection locale à tous les champs ``the_geom_local`` présents dans les tables de la base. Ce paramètre est également utilisé pour mettre en cohérence le système de projection local utilisé dans toutes les couches SIG présentes dans la base et les géométries stockées dans les champs ``the_geom_local`` des tables "métier". Le paramétrage du service WMS dans ``wms/wms.map`` est également pris en charge par le script d'installation de l'application.
* Correction de l'installation de npm
* Script ``install_all.sh`` mis à jour avec les nouvelles versions de GeoNature-atlas, de TaxHub et de UsersHub.

IMPORTANT : toutes les couches SIG insérées dans le schéma ``layers`` doivent être dans la projection fournie pour le paramètre ``srid_local``. L'application est livrée avec un ensemble de couches en Lambert 93 concernant la métropole. Une installation avec une autre projection, hors métropole, doit donc se faire sans l'insertion des couches SIG. Vous devrez manuellement fournir le contenu des tables du schéma ``layers`` dans la projection choisie.

**Notes de versions**

* Vous pouvez ajouter les paramètres ``srid_local``, ``install_sig_layers`` et ``add_sample_data`` au fichier ``config/settings.ini`` en vous inspirant du fichier ``config/settings.ini.sample``. Toutefois ces paramètres ne sont utilisés que pour une nouvelle installation et notamment pour l'installation de la base.
* Vous pouvez passer directement d'une 1.7.X à la 1.9.0, en prenant en compte les notes des différentes versions intermédiaires, notamment les scripts de mise à jour de la BDD ainsi que les éventuels nouveaux paramètres à ajouter.
* Si vous migrez depuis la version 1.8.3, exécutez le fichier SQL ``data/update_1.8.3to1.9.0.sql``. Comme GeoNature ne fonctionne jusque là que pour des structures de métropole, il est basé sur le fait que le champ ``the_geom_local`` reste en Lambert 93 (2154). Assurez-vous que le paramètre ``$srid_local`` dans ``lib/sfGeonatureConfig.php`` est égal à ``2154``.
  ATTENTION : ce script SQL renomme tous les champs ``the_geom_2154`` en ``the_geom_local`` de la BDD de GeoNature. Ceci affecte de nombreuses tables, de nombreux triggers et de nombreuses vues de la base. Le script n'intègre que les vues fournies par défaut. Si vous avez créé des vues spécifiques, notamment pour le module d'export, ou si vous avez modifié des vues fournies, vous devez adapter/compléter le script. Vous pouvez vous inspirer de son contenu.
* RAPPEL : Ceci affecte également la webapi des applications mobiles. Vous devez donc mettre à jour votre webapi si vous utilisez la saisie sur les applications mobiles. Une release de la webapi devrait sortir bientôt.


1.8.4 (2017-04-10)
------------------

**Corrections**

* Correction du script d'installation globale (``install_all``) si l'utilisateur de BDD par défaut a été renommé (``data/grant.sql``)
* Correction de la création des vues qui remontent la liste des taxons dans les 3 contacts


1.8.3 (2017-02-23)
------------------

**Nouveautés**

* Multi-organisme : l'organisme associé à la donnée est désormais celui de l'utilisateur connecté dans l'application (lors de la création d'une observation uniquement).
* Taxonomie : création d'une liste ``Saisie possible``, remplaçant l'attribut ``Saisie``. Cela permet de choisir les synonymes que l'on peut saisir ou non dans GeoNature en se basant sur les ``cd_nom`` (``bib_listes`` et ``cor_nom_liste``) et non plus sur les ``cd_ref`` (``bib_attributs`` et ``cor_taxon_attribut``). Voir le script de migration SQL ``data/update_1.8.2to1.8.3.sql`` pour bien basculer les informations de l'attribut dans la nouvelle liste.
* Correction de la vue ``synthese.v_tree_taxons_synthese`` potentiellement bloquante à l'ouverture de la synthèse.
* Suppression de la table ``utilisateurs.bib_observateurs`` inutile.
* Création des index spatiaux manquants (performances)
* Clarification et corrections mineures du script ``install_all``
* Ajout du MCD de la 1.8 (par @xavier-pnm)
* Améliorations du nom des fichiers exportés depuis la Synthèse (par @sylvain-m)

**Notes de versions**

Vous pouvez supprimer les lignes concernant le paramètre ``public static $id_organisme = ...`` dans ``lib/sfGeonatureConfig.php``, l'organisme n'étant plus un paramètre fixe mais désormais celui de l'utilisateur connecté.

Vous pouvez passer directement d'une 1.7.X à la 1.8.3, en prenant en compte les notes des différentes versions intermédiaires.

Si vous migrez depuis la version 1.8.2, éxécutez le fichier SQL ``data/update_1.8.2to1.8.3.sql``.


1.8.2 (2017-01-11)
------------------

**Nouveautés**

* Modularité des scripts SQL de création de la base en les dissociant par protocole et en regroupant les triggers dans les schémas de chaque protocole (préparation GeoNature V2)
* Correction d'une requête dans flore station (indépendance vis à vis de flore patrimoniale)
* Correction du trigger ``synthese_update_fiche_cflore`` (@ClaireLagaye)

**Notes de versions**

Vous pouvez passer directement d'une 1.7.X à la 1.8.2, en prenant en compte les notes des différentes versions intermédiaires.

Si vous migrez depuis la version 1.8.1, éxécutez le fichier ``data/update_1.8.1to1.8.2.sql``. Consultez les dernières lignes de ce fichier : vous devez évaluer si la requête d'insertion dans la table ``taxonomie.cor_taxon_attribut`` doit être faite ou non (vous pourriez avoir déjà constaté et corrigé cette erreur lors d'une précédente migration). Cela corrige l'absence de taxons protégés dans votre synthese en récupérant les informations de protection présentes dans le champ ``filtre3`` de la table ``save.bib_taxons``


1.8.1 (2017-01-05)
------------------

**Nouveautés**

* Ajout des sauvegardes et de l'installation globale avec un exemple détaillé dans la documentation : http://geonature.readthedocs.io
* Optimisation et correction de la vue qui retourne l'arbre des rangs taxonomiques (synthese.v_tree_taxons_synthese)
* Mise en cohérence des données exemple de GeoNature-atlas avec les critères des vues matérialisées de GeoNature-atlas
* Mise à jour de 2 triggers du Contact Flore (@ClaireLagaye)

**Notes de versions**

Vous pouvez passer directement d'une 1.7.X à la 1.8.1, en prenant en compte les notes des différentes versions intermédiaires.

Si vous migrez depuis la version 1.8.0, éxécutez le fichier ``data/update_1.8to1.8.1.sql``


1.8.0 (2016-12-14)
------------------

**Nouveautés**

* Passage à TAXREF version 9
* Accès à la synthèse en consultation uniquement pour des utilisateurs enregistrés avec des droits 1
* Ajout d'un champ ``diffusion`` (oui/non) dans la table ``synthese.syntheseff``, utilisable dans GeoNature-atlas. Pas d'interface de gestion de ce champ pour le moment. CF #132
* Création d'un script d'installation simplifié pour un pack UsersHub, TaxHub, GeoNature et GeoNature-atlas : https://github.com/PnEcrins/GeoNature/tree/master/docs/install_all
* Factorisation des SQL de création des schémas ``taxonomie`` et ``utilisateurs`` en les récupérant dans les dépots TaxHub et UsersHub
* Compatibilité avec l'application `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui permet de gérer la taxonomie à partir de TAXREF. Cela induit d'importants changements dans le schéma ``taxonomie``, notamment le renommage de ``taxonomie.bib_taxons`` en ``taxonomie.bib_noms``, la suppression de ``taxonomie.bib_filtres`` et l'utilisation de ``taxonomie.bib_attributs`` (voir https://github.com/PnX-SI/TaxHub/issues/71 pour plus d'informations). Voir aussi le fichier de migration ``data/update_1.7to1.8.sql`` qui permet d'automatiser ces évolutions de la BDD
* Compatibilité avec l'application `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_ qui permet de diffuser les données de la synthèse faune et flore dans un atlas en ligne (exemple : http://biodiversite.ecrins-parcnational.fr)
* Création d'un site internet de présentation de GeoNature : http://geonature.fr

**Corrections**

* Amélioration des triggers concernant la suppression de fiches orphelines
* Affichage par défaut du nom latin dans Contact flore et Contact invertébrés
* Correction des exports lors de la présence de points-virgules dans les commentaires. Fix #143
* Suppression du besoin d'un super utilisateur lors de l'installation de la BDD. Fix #141
* Correction de l'ID des protocoles mortalité et invertebres dans la configuration par défaut
* Suppression d'un doublon dans le fichier de configuration symfony de l'application
* Correction des coordonnées lors de l'export de données Flore Station
* Autres corrections mineures

**Note de version**

* Exécuter le script SQL de migration réalisant les modifications de la BDD de la version 1.7.X à 1.8.0 ``data/update_1.7to1.8.sql``
* Mettre à jour taxref en V9 en vous inspirant du script ``data/taxonomie/inpn/update_taxref_v8tov9``

**TaxHub**

L'application TaxHub (https://github.com/PnX-SI/TaxHub) est désormais fonctionnelle, documenté et installable.

Elle vous aidera à gérer vos taxons et l'ensemble du schéma ``taxonomie``, présent dans la BDD de GeoNature.

TaxHub évoluera pour intégrer progressivement de nouvelles fonctionnalités.

Il est conseillé de ne pas installer la base de données de TaxHub indépendamment et de connecter l'application directement sur le la base de données de GeoNature.

**GeoNature-atlas**

GeoNature-atlas est également basé sur le schéma ``taxonomie`` de TaxHub. Ainsi TaxHub permet la saisie des informations relatives aux taxons (descriptions, milieux, photos, liens, PDF...). GeoNature-atlas dispose de sa propre base de données mais pour fonctionner en connexion avec le contenu de la base GeoNature il faut à minima disposer d'une version 1.8 de GeoNature.

:notes:

    Une régression dans le contenu de Taxref V9 conduit à la suppression de l'information concernant le niveau de protection des espèces (régional, national, international,...).
    Cette information était utilisée par GeoNature, notamment pour définir les textes à retenir pour la colonne ``concerne_mon_territoire`` de la table ``taxonomie.taxref_protection_articles``.
    Vous devez désormais remplir cette colonne manuellement.


1.7.4 (2016-07-06)
------------------

**Corrections de bugs**

* Correction du script d'installation des tables liées au Contact flore (5a1fb07)
* Mise en cohérence avec GeoNature-mobile utilisant les classes 'gasteropodes' et 'bivalves' et non la classe générique 'mollusques'.

**Nouveautés**

* Corrections de mise en forme de la documentation
* Ajout de la liste rouge France de TaxRef lors d'une nouvelle installation (f4be2b6). A ne pas prendre en compte dans le cas d'une mise à jour.
* Ajout du MCD de la BDD - https://github.com/PnEcrins/GeoNature/blob/master/docs/2016-04-29-mcd_geonaturedb.png

**Note de version**

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.4 mais en vous référant aux notes de version de la 1.7.0.
* Remplacer ``id_classe_mollusques`` par ``id_classe_gasteropodes`` dans ``web/js/config.js`` et renseigner la valeur en cohérence avec l'``id_liste`` retenu dans la table ``taxonomie.bib_listes`` pour les gastéropodes. Attention, vous devez avoir établi une correspondance entre les taxons gastéropodes et bivalves et leur liste dans la table ``taxonomie.cor_taxon_liste``.


1.7.3 (2016-05-19)
------------------

**Corrections de bugs**

* Correction de coordonnées vides dans l'export de Flore station. cf https://github.com/PnEcrins/GeoNature/commit/0793a3d3d2b3719ed515058d1a0ba9baf7cb2096
* Correction des triggers en base concernant un bug de saisie pour les taxons dont le taxon de référence n'est pas présent dans ``taxonomie.bib_taxons``.

**Note de version**

Rappel : commencez par suivre la procédure classique de mise à jour. http://geonature.readthedocs.org/fr/latest/update.html

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.3 mais en vous référant aux notes de version de la 1.7.0.

* Pour passer de la 1.7.2 à la 1.7.3 vous devez exécuter le script ``https://github.com/PnEcrins/GeoNature/blob/master/data/update_1.7.2to1.7.3.sql``.


1.7.2 (2016-04-27)
----------------------

**Corrections de bug**

* Correction d'un bug dans l'export XLS depuis Flore Station.

**Note de version**

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.2 mais en vous référant aux notes de version de la 1.7.0.


1.7.1 (2016-04-27)
----------------------

**Corrections de bug**

* Ajout des listes flore manquantes dans le script de mise à jour ``data/update_1.6to1.7.sql``.


1.7.0 (2016-04-24)
----------------------

**Nouveautés**

* Ajout du contact flore
* Correction et compléments dans les statistiques et mise en paramètre de leur affichage ou non, ainsi que de la date de début à prendre en compte pour leur affichage.
* Ajout d'un module d'export des données permettant d'offrir, en interne ou à des partenaires, un lien de téléchargement des données basé sur une ou des vues de la base de données (un fichier par vue). Voir http://geonature.readthedocs.org/fr/latest/export.html
* Modification des identifiants des listes pour compatibilité avec les applications GeoNature-Mobile.
* Complément dans la base de données pour compatibilité avec les applications GeoNature-Mobile.
* Correction d'une erreur sur l'importation de shape pour la recherche géographique
* WMS : correction de la liste des sites N2000, correction de l'affichage de l'aire optimale d'adhésion des parcs nationaux et retrait des sites inscrits et classés
* Correction d'un bug permettant la saisie d'une date d'observation postérieure à aujourd'hui dans Flore station
* Mention de la version de taxref sur la page d'accueil

**Note de version**

Rappel : commencez par suivre la procédure classique de mise à jour. http://geonature.readthedocs.org/fr/latest/update.html

**1.** Modification des identifiants des listes de taxons pour compatibilité avec les applications GeoNature-Mobile.

Dans GeoNature-Mobile, les taxons sont filtrables par classe sur la base d'un ``id_classe``. Ces id sont inscrits en dur dans le code des applications mobiles.

Dans la base GeoNature les classes taxonomiques sont configurables grace au vues ``v_nomade_classes`` qui utilisent les listes (``taxonomie.bib_listes``).

Les ``id_liste`` ont donc été mis à jour pour être compatibles avec les ``id_classe`` des applications mobiles.

Voir le script SQL d'update ``data/update_1.6to1.7.sql`` et LIRE ATTENTIVEMENT LES COMMENTAIRES.

* En lien avec les modifications ci-dessus, mettre à jour les variables des classes taxonomiques correspondant aux modification des ``id_liste`` dans ``web/js/config.js``

* Ajouter dans le fichier ``lib/sfGeonatureConfig.php`` les variables ``$struc_abregee``, ``$struc_long``, ``$taxref_version``, ``$show_statistiques`` et ``$init_date_statistiques`` (voir le fichier ``lib/sfGeonatureConfig.php.sample``)

**2.** Pour ajouter le Contact flore

* Exécuter le script sql ``data/2154/contactflore.sql``
* Ajouter les variables ``$id_lot_cflore  = 7``, ``$id_protocole_cflore  = 7``, ``$id_source_cflore = 7`` et ``$appname_cflore = 'Contact flore - GeoNature';`` dans ``lib/sfGeonatureConfig.php`` (voir le fichier d'exemple ``lib/sfGeonatureConfig.php.sample``)
* Ajouter les variables  ``id_lot_contact_flore = 7``, ``id_protocole_contact_flore = 7``, ``id_source_contactflore = 7`` dans ``web/js/config.js`` (voir le fichier d'exemple ``web/js/config.js.sample``)
* l'enregistrement correspondant au contact flore dans la table ``synthese.bib_sources`` doit être actif (dernière colonne) pour que le contact flore soit accessible depuis la page d'accueil.

**3.** Afin de mettre à jour la configuration WMS, vous devez exécuter le fichier ``wms/update1.6to1.7.sh``.

Au préalable, assurez vous que les informations renseignées dans le fichier ``config/settings.ini`` sont à jour. L'ancien fichier sera sauvegardé sous ``wms/wms_1.6.map``. Vous pourrez faire le choix de conserver ou de supprimer ce fichier de sauvegarde qui ne sera pas utilisé par l'application.

   ::

      ./wms/update1.6to1.7.sh

**4.** Mise en place du module d'export

* Créer les vues retournant les données attendues.
* Configurer le module dans le fichier ``lib/sfGeonatureConfig.php`` à partir de l'exemple du fichier ``lib/sfGeonatureConfig.php.sample``); section ``configuration du module d'export``

   * Vous pouvez paramétrer plusieurs modules avec un nom pour chacun grace au paramètre ``exportname``
   * Pour chacun des modules seuls les utilisateurs de geonature dont le ``id_role`` figure dans le tableau ``authorized_roles_ids`` peuvent exporter les données mises à disposition par le module d'export.
   * Chaque module peut comporter autant que vues que nécessaire (un bouton par vue générera un fichier zip par vue). Renseigner le tableau ``views`` pour chacun des modules.
   * Voir la documentation ici : http://geonature.readthedocs.org/fr/latest/export.html

* Attribution des droits nécessaires pour le répertoire permettant l'enregistrement temporaire des fichiers générés par le module d'export.

   ::

      chmod -R 775 web/uploads/exports

* Rétablir les droits d'écriture et vider le cache

   ::

      chmod -R 777 cache/
      chmod -R 777 log/
      php symfony cc


1.6.0 (2016-01-14)
------------------

**Note de version**

* Pour les changements dans la base de données vous pouvez exécuter le fichier ``data/update_1.5to1.6.sql``
* Mise à jour de la configuration Apache. Modifier le fichier ``apache/wms.conf`` en vous basant sur l'exemple https://github.com/PnEcrins/GeoNature/blob/master/apache/wms.conf.sample#L16-L17
* Ajouter le paramètre ``$id_application`` dans ``lib/sfGeonatureConfig.php.php`` (voir la valeur utilisée pour GeoNature dans les tables ``utilisateurs.t_applications`` et ``utilisateurs.cor_role_droit_application``)
* Ajouter le paramètre ``import_shp_projection`` dans ``web/js/configmap.map`` - voir l'exemple dans le fichier ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/configmap.js.sample#L35``
* Supprimer toute référence à gps_user_projection dans ``web/js/configmap.map``
* Ajouter un tableau JSON des projections disponibles pour l'outil de pointage GPS : ``gps_user_projections`` dans ``web/js/configmap.map``. Respecter la structure définie dans ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/configmap.js.sample#L7-L14``. Attention de bien respecter la structure du tableau JSON et notamment sa syntaxe (accolades, virgules, nom des objects, etc...)
* Ajouter les ``id_liste`` pour les classes faune filtrables dans les formulaires de saisie dans le fichier ``web/js/config.map``. Ceci concerne les variables ``id_classe_oiseaux``, ``id_classe_mammiferes``, ``id_classe_amphibiens``, ``id_classe_reptiles``, ``id_classe_poissons`` et ``id_classe_ecrevisses``, ``id_classe_insectes``, ``id_classe_arachnides``, ``id_classe_myriapodes`` et  ``id_classe_mollusques``. Voir l'exemple dans le fichier ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/config.js.sample#L32-44``
* Taxref a été mis à jour de la version 7 à 8. GeoNature 1.6.0 peut fonctionner avec la version 7. Cependant il est conseillé de passer en taxref V8 en mettant à jour la table ``synthese.taxref`` avec la version 8. Cette mise à jour pouvant avoir un impact fort sur vos données, son automatisation n'a pas été prévue. Le script SQL de migration de vos données de taxref V7 vers taxref V8 n'est donc pas fourni. Pour une installation nouvelle de la base de données, GeoNature 1.6.0 est fourni avec taxref V8.
* Le routing a été mis à jour, vous devez vider le cache de Symfony pour qu'il soit pris en compte. Pour cela, placez vous dans le répertoire racine de l'application et effectuez la commande suivante :

    ::

        php symfony cc

**Changements**

* Les recherches dans la synthèse sont désormais faites sur le ``cd_ref`` et non plus sur le ``cd_nom`` pour retourner tous les synonymes du taxon recherché - Fix #92
* Passage de taxref V7 à Taxref V8 - Fix #34
* Intégration de la première version de l'API permettant d'intégrer des données dans la synthèse depuis une source externe - https://github.com/PnEcrins/GeoNature/blob/master/docs/geonature_webapi_doc.rst
* Mise en paramètre du ``id_application`` dans ``lib/sfGeonatureConfig.php.php`` - Fix #105
* Recharger la synthese après suppression d'un enregistrement - Fix #94
* L'utilisateur peut lui-même définir le système de coordonnées dans l'outil de pointage GPS - Fix #107
* Mise en paramètre de la projection de la shape importée comme zone de recherche dans la synthèse
* Les exports XLS et SHP comportent le ``cd_nom`` ET le ``cd_ref`` de tous les synonymes du nom recherché ainsi que le nom_latin (bib_taxons) ET le nom_valide (taxref) - Fix #92
* SAISIE invertébrés - Ajout d'un filtre Mollusques - Fix #117
* Amélioration du vocabulaire utilisé sur la page d'accueil - #118
* Affichage d'un message pendant le chargement des exports
* Mise en place de statistiques automatiques sur la page d'accueil, basées sur les listes de taxons. A compléter.

**Corrections de bug**

* Intégration de la librairie ``OpenLayers.js`` en local dans le code car les liens distants ne fonctionnaient plus - Fix #97
* Correction d'une erreur lors de l'enregistrement de la saisie invertébrés - Fix #104
* Correction d'une erreur de redirection si on choisit "Quitter" après la saisie de l'enregistrement (contact faune, mortalité et invertébrés) - Fix #102
* Correction du trigger ``contactfaune.synthese_update_cor_role_fiche_cf()`` - Fix #95
* Correction d'un bug dans les listes déroulantes des taxons filtrée par classe qui n'affichaient rien - Fix #109
* Correction d'un bug sur le contenu des exports shape avec le critère de protection activé - Fix #114
* Correction et adaptation faune-flore des exports shape
* SYNTHESE - Correction de la liste des taxons sans nom français - Fix #116
* Corrections CSS sur la page d'accueil - Fix #115
* Correction sur la largeur de la liste des résultats de la synthèse - Fix #110
* Correction des doublons dans la recherche multi-taxons - Fix #101
* Autres corrections mineures


1.5.0 (2015-11-26)
------------------

**Note de version**

* Pour les changements dans la base de données vous pouvez exécuter le fichier ``data/update_1.4to1.5.sql``
* Le bandeau de la page d'accueil ``web/images/bandeau_faune.jpg`` a été renommé en ``bandeau_geonature.jpg``. Renommez le votre si vous aviez personnalisé ce bandeau.
* Si vous souhaitez désactiver certains programmes dans le "Comment ?" de la synthèse vous devez utiliser le champs ``actif`` de la table ``meta.bib_programmes``.
* Compléter si nécessaire les champs ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources``.
* Nouvelle répartition des paramètres de configuration javascript en 2 fichiers (``config.js`` et ``configmap.js``). Vous devez reprendre vos paramètres de configuration du fichier ``web/js/config.js`` et les ventiler dans ces deux fichiers.
* Ajouter le paramètre ``id_source_mortalite = 2;`` au fichier ``web/js/config.js``;
* Retirer le paramètre ``fuseauUTM;`` du fichier ``web/js/config.js``;
* Bien définir le système de coordonnées à utiliser pour les pointages par coordonnées fournies en renseignant le paramètre ``gps_user_projection`` dans le fichier ``web/js/configmap.js``;
* Ajouter le paramètre ``public static $id_source_mortalite = 2;`` au fichier ``lib/sfGeonatureConfig.php``;
* Ajouter le paramètre ``public static $srid_ol_map = 3857;`` au fichier ``lib/sfGeonatureConfig.php``;
* L'altitude est calculée automatiquement à partir du service "Alticodage" de l'API GeoPortail de l'IGN et non pluas à partir de la couche ``layers.l_isolines20``. Ajoutez ce service dans votre contrat API Geoportail. Il n'est donc plus nécessaire de remplir la couche ``layers.l_isolines20``. Cette couche peut toutefois encore être utile si l'utilisateur supprime l'altitude calculée par l'API Geoportail dans les formulaires de saisie.
* Le loup et le lynx sont retirés par défaut de la saisie (saisie recommandée dans le protocole national du réseau grands prédateurs)
* Le cerf, chamois et le bouquetin doivent être saisis selon 6 critères de sexe et age et non 5 comme les autres taxons. Comportement peut-être changé en modifiant la vue ``contactfaune.v_nomade_taxons_faune``.
* Mortailité est désormais une source à part entière alors qu'elles étaient mélangées avec la source ContactFaune précédemment. Si vous avez déjà des données de mortalité enregistrées, vous devez adapter la requête SQL ci-dessous avec votre ``id_source`` pour Mortalité et l'exécuter :

    ::

        UPDATE synthese.syntheseff SET id_source = 2 WHERE id_source = 1 AND id_critere_synthese = 2;

**Changements**

* Optimisation des vues aux chargement des listes de taxons. Fixes #64
* Généricité des champs dans ``meta.bib_programmes`` (champs ``sitpn`` renommé en ``public``). Fixes #68
* Ajout d'un champ ``actif`` à la table ``meta.bib_programmes`` permettant de masquer certains programmes dans le "Comment ?" de la synthèse. Fixes #66
* Ajout d'un champ ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources`` pour générer la page d'accueil dynamiquement et de manière générique. Fixes #69
* Construire dynamiquement la liste des liens vers la saisie des différents protocoles à partir de la table ``synthese.bib_sources``. Fixes #69
* Tous les styles des éléments de la page d'accueil ont été passés en CSS. Fixes #57
* Amélioration de l'interface pendant le chargement des différentes applications (synthèse, flore station, formualires de saisie...). Fixes #65
* Recentrage sur la position de l'utilisation en utilisant le protocole de géolocalisation intégré au navigateur de l'utilisateur. Fixes #65
* Un message automatique conseille les utilisateurs d'Internet Explorer de plutôt utiliser Firefox ou Chrome. Fixes #65
* Tri par défaut par date décroissante des 50 dernières observations affichées à l'ouverture de la Synthèse. Fixes #51
* Vocabulaire. "Dessiner un point" remplacé par "Localiser l'observation". Fixes #66
* Mise à jour des copyrights dans les pieds de page de toutes les applications.
* Refonte du CSS du formulaire de login avec bootstrap et une image de fond différente.
* Refonte Bootstrap de la page d'accueil.
* Homogénéisation du pied de page.
* FloreStation et Bryophytes - Homogénéiser interaction carte liste - ajout d'un popup au survol. Fixes #74
* Suppression d'images non utilisées dans le répertoire ``web/images``.
* Mise en cohérence des vues taxonomiques faune. Fixes #81
* Calcul de l'altitude à partir du service "Alticodage" de l'API GeoPortail de l'IGN.
* Factorisation et généralisation du module permettant un positionnement des pointages par saisie de coordonnées selon projection et bbox fournies en paramètres de config.
* Création d'une configuration javascript carto dédiée (``configmap.js``).

**Corrections de bug**

* Correction des problèmes de saisie de la version 1.4.0 liés à la migration de la taxonomie.
* Correction de bugs dans Flore Station et Bryophytes (Zoom, recherche


1.4.0 (2015-10-16)
------------------

**Note de version**

* La gestion de la taxonomie a été mis en conformité avec le schéma ``taxonomie`` de la base de données de TaxHub (https://github.com/PnX-SI/TaxHub). Ainsi le schéma ``taxonomie`` intégré à GeoNature 1.3.0 doit être globalement revu. L'ensemble des modifications peuvent être réalisées en éxecutant la partie correspondante dans le fichier ``data/update_1.3to1.4.sql`` (https://github.com/PnEcrins/GeoNature/blob/master/data/update_1.3to1.4.sql).
* De nouveaux paramètres ont potentiellement été ajoutés à l'application. Après avoir récupéré le fichier de configuration de votre version 1.3.0, vérifiez les changements éventuels des différents fichiers de configuration.
* Modification du nom de l'host host hébergeant la base de données. databases --> geonatdbhost. A changer ou ajouter dans le ``/etc/hosts`` si vous avez déjà installé GeoNature.
* Suivez la procédure de mise à jour : http://geonature.readthedocs.org/fr/latest/update.html

**Changements**

* A l'installation initiale, chargement en base des zones à statuts juridiques pour toute la France métropolitaine à partir des sources de l'INPN
* A l'installation initiale, chargement en base de toutes les communes de France
* Mise en place de la compatibilité de la base avec le schema de TaxHub


1.3.0 (2015-02-11)
------------------

Pré-Version de GeoNature - Faune ET Flore. Le fonctionnement de l'ensemble n'a pas été totalement testé, des bugs sont identifiés, d'autres subsistent certainement.

**Changements**

* Grosse évolution de la base de données
* Ajout de deux applications de saisie flore (flore station et bryophytes)
* Intégration de la flore en sythese
* Ajouter un id_lot, id_organisme, id_protocole dans toutes les tables pour que ces id soit ajoutés vers la synthese en trigger depuis les tables et pas avec des valeurs en dur dans les triggers. Ceci permet d'utiliser les paramètres de conf de GeoNature
* Ajout d'une fonction à la base pour correction du dysfonctionnement du wms avec mapserver
* Suppression du champ id_taxon en synthese et lien direct de la synthese avecle taxref. ceci permet d'ajouter des données en synthese directement dans la base sans ajouter tous les taxons manquants dans la table bib_taxons
* Suppression de la notion de coeur dans les critère de recherche en synthese
* Ajout d'un filtre faune flore fonge dans la synthese
* Ajout de l'embranchement et du regne dans les exports
* Permettre à des partenaires de saisir mais d'exporter uniquement leurs données perso
* Ajout du déterminateur dans les formulaires invertébrés et contactfaune + en synthese
* Ajout du référentiel géographique de toutes les communes de France métropolitaine
* Ajout des zones à statuts juridiques de la région sud-est (national à venir)
* Bugs fix

**BUG à identifier**

Installation :

* corriger l'insertion de données flore station qui ne fonctionne pas

Bryophythes :

* Corriger la recherche avancée par date sans années

Synthèse :

* la construction de l'arbre pour choisir plusieurs taxons ne tient pas compte des filtres
* le fonctionnement des unités geographiques n'a pas été testé (initialement conçu uniquement pour la faune)


1.2.0 (2015-02-11)
------------------

Version stabilisée de GeoNature - Faune uniquement (Synthèse Faune + Saisie ContactFauneVertebre, ContactFauneInvertebre et Mortalité).

**Changements**

* Modification du nom de l'application de FF-synthese en GeoNature
* Changement du nom des utilisateurs PostgreSQL
* Changement du nom de la base de données
* Mise à jour de la documentation (http://geonature.readthedocs.org/)
* Automatisation de l'installation de la BDD
* Renommer les tables pour plus de généricité
* Supprimer les tables inutiles ou trop spécifiques
* Gestion des utilisateurs externalisée et centralisée avec UsersHub (https://github.com/PnEcrins/UsersHub)
* Correction de bugs
* Préparation de l'intégration de la Flore pour passer de GeoNature Faune à GeoNature Faune-Flore


1.1.0 (2014-12-11)
------------------

**Changements**

* Modification du schéma de la base pour être compatible taxref v7
* Import automatisé de taxref v7
* Suppression des tables de hiérarchie taxonomique (famille, ordre, ...) afin de simplifier l'utilisation de la taxonomie.
* Création de la notion de groupe (para-taxonomique) à la place de l'utilisation des classes.
* Ajout de données pour pouvoir tester de façon complète l'application (invertébrés, vertébrés)
* Ajout de données exemples
* Bugs fix


1.0.0 (2014-12-10)
------------------

Version fonctionnelle des applications : visualisation de la synthèse faune, saisie d'une donnée de contact (vertébrés, invertébrés, mortalité)

**Changements**

* Documentation de l'installation d'un serveur Debian wheezy pas à pas
* Documentation de la mise en place de la base de données
* Documentation de la mise en place de l'application et de son paramétrage
* Script d'insertion d'un jeu de données test
* Passage à PostGIS v2
* Mise en paramètre de la notion de lot, protocole et source

**Prochaines évolutions**

* Script d'import de taxref v7
* Utilisation préférentielle de la taxonomie de taxref plutôt que les tables de hiérarchie taxonomique


0.1.0 (2014-12-01)
------------------

* Création du projet et de la documentation
