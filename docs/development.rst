DEVELOPPEMENT
=============

Général
-------

GeoNature a été développé par Gil Deluermoz depuis 2010 avec PHP/Symfony/ExtJS.

En 2017, les parcs nationaux français ont décidé de refondre GeoNature
complètement avec une nouvelle version (V2) réalisée en Python/Flask/Angular.

Mainteneurs :

- Gil DELUERMOZ (PnEcrins) : Base de données / SQL / Installation / Mise à jour
- Amandine SAHL (PnCevennes) : Backend / Python Flask / API
- Theo LECHEMIA (PnEcrins) : Frontend / Angular
- Camille MONCHICOURT (PnEcrins) : Documentation / Gestion du projet

.. image :: http://geonature.fr/docs/img/developpement/geonature-techno.png

API
---

GeoNature utilise :

- l'API de TaxHub (recherche taxon, règne et groupe d'un taxon...)
- l'API du sous-module Nomenclatures (typologies et listes déroulantes)
- l'API du sous-module d'authentification de UsersHub (login/logout, récupération du CRUVED d'un utilisateur)
- l'API de GeoNature (get, post, update des données des différents modules, métadonnées, intersections géographiques, exports...)

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/api_services.png

Liste des routes
*****************

.. qrefflask:: geonature.utils.command:get_app_for_cmd(with_flask_admin=False)
  :undoc-static:

Documentation des routes
************************

.. autoflask:: geonature.utils.command:get_app_for_cmd(with_flask_admin=False)
  :undoc-static:


Release
-------

Pour sortir une nouvelle version de GeoNature :

- Faites les éventuelles Releases des dépendances (UsersHub, TaxHub, UsersHub-authentification-module, Nomenclature-api-module, GeoNature-atlas)
- Mettez à jour la version de GeoNature et éventuellement des dépendances dans ``install/install_all/install_all.ini``, ``config/settings.ini.sample``, ``backend/requirements.txt``
- Complétez le fichier ``docs/CHANGELOG.rst`` (en comparant les branches https://github.com/PnX-SI/GeoNature/compare/develop) et dater la version à sortir
- Mettez à jour le fichier ``VERSION``
- Remplissez le tableau de compatibilité des dépendances (``docs/versions-compatibility.rst``)
- Mergez la branche ``develop`` dans la branche ``master``
- Faites la release (https://github.com/PnX-SI/GeoNature/releases) en la taguant ``X.Y.Z`` (sans ``v`` devant) et en copiant le contenu du Changelog
- Dans la branche ``develop``, modifiez le fichier ``VERSION`` en ``X.Y.Z.dev0`` et pareil dans le fichier ``docs/CHANGELOG.rst``

BDD
---

Mettre à jour le ``ref_geo`` à partir des données IGN scan express :

- Télécharger le dernier millesime : http://professionnels.ign.fr/adminexpress
- Intégrer le fichier Shape dans la BDD grâce à QGIS dans une table nommée ``ref_geo.temp_fr_municipalities``
- Générer le SQL de création de la table : ``pg_dump --table=ref_geo.temp_fr_municipalities --column-inserts -U <MON_USER> -h <MON_HOST> -d <MA_BASE> > fr_municipalities.sql``. Le fichier en sortie doit s'appeler ``fr_municipalities.sql``
- Zipper le fichier SQL et le mettre sur le serveur http://geonature.fr/data
- Adapter le script ``install_db.sh`` pour récupérer le nouveau fichier zippé

Pratiques et règles de developpement
------------------------------------

Afin de partager des règles communes de développement et faciliter l'intégration de 
nouveau code, veuillez lire les recommandations et bonnes pratiques recommandées pour contribuer
au projet GeoNature.

Git
***

- Ne jamais faire de commit dans la branche ``master`` mais dans la branche ``develop`` ou idéalement dans une branche dédiée à la fonctionnalité (feature branch)
- Faire des pull request vers la branche ``develop``
- Faire des ``git pull`` avant chaque développement et avant chaque commit
- Les messages de commits font référence à un ticket ou le ferment (``ref #12`` ou ``fixes #23``)
- Les messages des commits sont en anglais (dans la mesure du possible)

Backend
*******

- Une fonction ou classe doit contenir une docstring en français. Les doctrings doivent suivre le modèle NumPy/SciPy (voir https://numpydoc.readthedocs.io/en/latest/format.html et https://realpython.com/documenting-python-code/#numpyscipy-docstrings-example)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empêcher de mettre un commentaire en français sur une partie du code complexe !)
- Installer les requirements-dev (``pip install -r backend/requirements-dev.txt``) qui contiennent une série d'outils indispensables au développement dans GeoNature.
- Utiliser *blake* comme formateur de texte et activer l'auto-formatage dans son éditeur de texte (Tuto pour VsCode : https://medium.com/@marcobelo/setting-up-python-black-on-visual-studio-code-5318eba4cd00)
- Utiliser *pylint* comme formatteur de code 
- Respecter la norme PEP8 (assurée par les deux outils précédents)
- La longueur maximale pour une ligne de code est 100 caractères. Pour VsCode copier ces lignes le fichier ``settings.json`` :
- Respecter le snake case

::

    "python.formatting.blackArgs": [
      "--line-length",
      "100"
    ]

- Utiliser des doubles quotes pour les chaines de charactères.

BDD 
***

- Le noms des tables est préfixé par un "t" pour une table de contenu, de "bib" pour les tables de "dictionnaires" et de "cor" pour les tables de correspondance
- Les schémas du coeur de GeoNature sont préfixés de "gn" 
- Les schémas des protocoles ou modules GeoNature sont préfixés de "pr"
- Chaque schéma de BDD dispose de son propre fichier SQL
- Les scripts SQL sont ordonnés en section dans l'ordre suivant : (voir https://github.com/PnX-SI/GeoNature/blob/master/data/core/synthese.sql)

  - Fonctions
  - Tables 
  - Clés primaires 
  - Clés étrangères 
  - Contraintes 
  - Triggers 
  - Données nécessaires au fonctionnement du schéma
  
- Les scripts de données sont écrits dans des fichiers à part
- Ne rien écrire dans le schéma ``public``
- Ne pas répeter le nom des tables dans les noms des colonnes (exception faite des colonnes "id)

Typescript
**********

- Documenter les fonctions et classes grâce au JSDoc en français (https://jsdoc.app/)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empecher de mettre un commentaire en français sur une partie du code complexe !)
- Les messages renvoyés aux utilisateurs sont en français 
- Installer les outils de devéloppement: `npm install --only=dev`
- Utiliser *prettier* comme formateur de texte et activer l'autoformatage dans son éditeur de texte (VsCode dispose d'une extension Prettier : https://github.com/prettier/prettier-vscode)
- Utiliser tslint comme linter
- La longueur maximale pour une ligne de code est 100 caractères.

Angular
*******

- Suivre les recommandations définies par le styleguide Angular: https://angular.io/guide/styleguide. C'est une ressources très fournie en cas de question sur les pratiques de développement (principe de séparation des principes, organisation des services et des composants)
- On privilegira l'utilisation des reactive forms pour la construction des formulaires (https://angular.io/guide/reactive-forms). Ce sont des formulaires piloté par le code, ce qui facilite la lisibilité et le contrôle de ceux-ci.
- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.
 
HTML 
****

- La longueur maximale pour une ligne de code est 100 caractères.
- Lorsqu'il y a plus d'un attribut sur une balise, revenir à la ligne et aligner les attributs :

::

      <button 
        mat-raised-button
        color="primary"
        class="btn-action hard-shadow uppercase ml-3"
        data-toggle="collapse"
        data-target="#collapseAvance"
      >
        Filtrer
      </button>

- VsCode fournit un formatteur de HTML par défaut (Dans les options de VsCode, tapez "wrap attributes" et sélectionner "force-expand-multiline")

Style et ergonomie
******************

- Boutons :
  On utilise les boutons d'Angular materials (https://material.angular.io/components/button/overview).
  
  - mat-raised-button pour les boutons contenant du texte 
  - mat-fab ou mat-mini-fab pour les boutons d'actions avec seulement une icone 

- Couleur des boutons :

  - Action : primary 
  - Validation: vert (n'existant pas dans material: utiliser la classe `button-success`)
  - Suppression: warn 
  - Navigation: basic 

- Librairie d'icones :

  - Utiliser la librairie material icons fournie avec le projet : https://material.io/resources/icons/?style=baseline (``<mat-icon> add </mat-icon>``)

- Formulaire :

  - Nous utilisons pour l'instant le style des formulaires Bootstrap (https://getbootstrap.com/docs/4.0/components/forms/). Une reflexion de migration vers les formulaires materials est en cours.

- Système de grille et responsive :

  - Utiliser le système de grille de bootstrap pour assurer le responsive design sur l'application. On ne vise pas l'utilisation sur mobile, mais à minima sur ordinateur portable de petite taille.


Développer et installer un gn_module
------------------------------------

GeoNature a été conçu pour fonctionner en briques modulaires. 

Chaque protocole, répondant à une question scientifique, est amené à avoir
son propre module GeoNature comportant son modèle de base de données (dans un
schéma séparé), son API et son interface utilisateur.

Les modules développés s'appuieront sur le coeur de GeoNature qui est
constitué d'un ensemble de briques réutilisables.

En base de données, le coeur de GeoNature est constitué de l'ensemble des
référentiels (utilisateurs, taxonomique, nomenclatures géographique)
et du schéma ``synthese`` regroupant l'ensemble données saisies dans les
différents protocoles (voir doc administrateur pour plus de détail sur le
modèle de données).

L'API du coeur permet d'interroger les schémas de la base de données "coeur"
de GeoNature. Une documentation complète de l'API est disponible dans la
rubrique 'Documentation API Backend'_.

Du côté interface utilisateur, GeoNature met à disposition un ensemble de
composants Angular réutilisables
(http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html),
pour l'affichage des cartes, des formulaires etc...

Développer un gn_module
***********************

Avant de développer un gn_module, assurez-vous d'avoir GeoNature bien
installé sur votre machine
(`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst>`__).

Afin de pouvoir connecter ce module au "coeur", il est impératif de suivre
une arborescence prédéfinie par l'équipe GeoNature.
Un template GitHub a été prévu à cet effet
(https://github.com/PnX-SI/gn_module_template).
Il est possible de créer un nouveau dépôt GitHub à partir de ce template,
ou alors de copier/coller le contenu du dépôt dans un nouveau.

Cette arborescence implique de développer le module dans les technologies du
coeur de GeoNature à savoir :

- Le backend est développé en Python grâce au framework Flask.
- Le frontend est développé grâce au framework Angular (voir la version actuelle du coeur)

GeoNature prévoit cependant l'intégration de module "externe" dont le
frontend serait développé dans d'autres technologies. La gestion de
l'intégration du module est à la charge du développeur.

- Le module se placera dans un dossier à part du dossier "GeoNature" et portera le suffixe "gn_module". Exemple : *gn_module_validation*

- La racine du module comportera les fichiers suivants :

  - ``install_app.sh`` : script bash d'installation des librairies python ou npm necessaires au module
  - ``install_env.sh`` : script bash d'installation des paquets Linux
  - ``requirements.txt`` : liste des librairies python necessaires au module
  - ``manifest.toml`` : fichier de description du module (nom, version du module, version de GeoNature compatible)
  - ``conf_gn_module.toml`` : fichier de configuration de l'application (livré en version sample)
  - ``conf_schema_toml.py`` : schéma 'marshmallow' (https://marshmallow.readthedocs.io/en/latest/) du fichier de configuration (permet de s'assurer la conformité des paramètres renseignés par l'utilisateur). Ce fichier doit contenir une classe ``GnModuleSchemaConf`` dans laquelle toutes les configurations sont synchronisées.
  - ``install_gn_module.py`` : script python lançant les commandes relatives à 'installation du module (Base de données, ...). Ce fichier doit comprendre une fonction ``gnmodule_install_app(gn_db, gn_app)`` qui est utilisée pour installer le module (Voir l'`exemple du module CMR <https://github.com/PnX-SI/gn_module_cmr/blob/master/install_gn_module.py>`__)

- La racine du module comportera les dossiers suivants :

  - ``backend`` : dossier comportant l'API du module utilisant un blueprint Flask
  - Le fichier ``blueprint.py`` comprend les routes du module (ou instancie les nouveaux blueprints du module)
  - Le fichier ``models.py`` comprend les modèles SQLAlchemy des tables du module.
  - ``frontend`` : le dossier ``app`` comprend les fichiers typescript du module, et le dossier ``assets`` l'ensemble des médias (images, son).

    - Le dossier ``app`` doit comprendre le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.module.ts``
    - Le dossier ``app`` doit contenir un fichier ``module.config.ts``. Ce fichier est automatiquement synchronisé avec le fichier de configuration du module `<GEONATURE_DIRECTORY>/external_modules/<nom_module>/conf_gn_module.toml`` grâce à la commande ``geonature update_module_configuration <nom_module>``. C'est à partir de ce fichier que toutes les configuration doivent pointer.
    - A la racine du dossier ``frontend``, on retrouve également un fichier ``package.json`` qui décrit l'ensemble des librairies JS necessaires au module.

  - ``data`` : ce dossier comprenant les scripts SQL d'installation du module

Le module est ensuite installable à la manière d'un plugin grâce à la commande ``geonature install_gn_module`` de la manière suivante :

::

    # se placer dans le répertoire backend de GeoNature
    cd <GEONATURE_DIRECTORY>/backend
    # activer le virtualenv python
    source venv/bin/activate
    # lancer la commande d'installation
    geonature install_gn_module <CHEMIN_ABSOLU_DU_MODULE> <URL_API>
    # example geonature install_gn_module /home/moi/gn_module_validation /validation


Bonnes pratiques Frontend
"""""""""""""""""""""""""

- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.

  Importez ce module dans le module racine de la manière suivante 
  
  ::

    import { GN2CommonModule } from '@geonature_common/GN2Common.module';

- Les librairies JS seront installées dans le dossier ``node_modules`` de GeoNature. (Il n'est pas nécessaire de réinstaller toutes les librairies déjà présentes dans GeoNature (Angular, Leaflet, ChartJS ...). Le ``package.json`` de GeoNature liste l'ensemble des librairies déjà installées et réutilisable dans le module.

- Les fichiers d'assets sont à ranger dans le dossier ``assets`` du frontend. Angular-cli impose cependant que tous les assets soient dans le répertoire mère de l'application (celui de GeoNature). Un lien symbolique est créé à l'installation du module pour faire entre le dossier d'assets du module et celui de Geonature.

- Utiliser node_modules présent dans GeoNature

  Pour utiliser des librairies déjà installées dans GeoNature,
  utilisez la syntaxe suivante
  
  ::

    import { TreeModule } from "@librairies/angular-tree-component";

  L'alias ``@librairies`` pointe en effet vers le repertoire des node_modules
  de GeoNature

  Pour les utiliser à l'interieur du module, utiliser la syntaxe suivante 
  
  ::

    <img src="external_assets/<MY_MODULE_CODE>/afb.png">

  Exemple pour le module de validation 
  
  ::

    <img src="external_assets/<gn_module_validation>/afb.png">


Installer un gn_module
**********************

Renseignez l'éventuel fichier ``config/settings.ini`` du module.

Pour installer un module, rendez vous dans le dossier ``backend`` de GeoNature.

Activer ensuite le virtualenv pour rendre disponible les commandes GeoNature 

::

    source venv/bin/activate

Lancez ensuite la commande 

::

    geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_api>

Le premier paramètre est l'emplacement absolu du module sur votre machine et
le 2ème le chemin derrière lequel on retrouvera les routes de l'API du module.

Exemple pour atteindre les routes du module de validation à l'adresse
'http://mon-geonature.fr/api/geonature/validation'

Cette commande exécute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production

Complétez l'éventuelle configuration du module (``config/conf_gn_module.toml``) 
à partir des paramètres présents dans
``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les
valeurs par défaut. Puis relancez la mise à jour de la configuration
(depuis le répertoire ``geonature/backend`` et une fois dans le venv
(``source venv/bin/activate``) :
``geonature update_module_configuration nom_du_module``)


Développement Backend
----------------------

Démarrage du serveur de dev backend
***********************************

::

    (venv)...$ geonature dev_back


Base de données
***************

Session sqlalchemy
""""""""""""""""""

- ``geonature.utils.env.DB``


Fournit l'instance de connexion SQLAlchemy Python ::

    from geonature.utils.env import DB

    result = DB.session.query(MyModel).get(1)


Serialisation des modèles
*************************

La sérialisation des modèles SQLAlchemy s'appuie sur deux librairies maison externalisée. Voir la doc plus complète: https://github.com/PnX-SI/Utils-Flask-SQLAlchemy

- ``utils_flask_sqla.serializers.serializable``

  Décorateur pour les modèles SQLA : Ajoute une méthode ``as_dict`` qui
  retourne un dictionnaire des données de l'objet sérialisable json

  Fichier définition modèle :

  ::

    from geonature.utils.env import DB
    from utils_flask_sqla.serializers import serializable

    @serializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...

  Fichier utilisation modèle ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_dict()

- ``utils_flask_sqla_geo.serializers.geoserializable``


  Décorateur pour les modèles SQLA : Ajoute une méthode as_geofeature qui
  retourne un dictionnaire serialisable sous forme de Feature geojson.


  Fichier définition modèle ::

    from geonature.utils.env import DB
    from utils_flask_sqla_geo.serializers import geoserializable


    @geoserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


  Fichier utilisation modèle ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_geofeature()

- ``utils_flask_sqla_geo.serializers.shapeserializable``

  Décorateur pour les modèles SQLA :

  - Ajoute une méthode ``as_list`` qui retourne l'objet sous forme de tableau (utilisé pour créer des shapefiles)
  - Ajoute une méthode de classe ``to_shape`` qui crée des shapefiles à partir des données passées en paramètre

  Fichier définition modèle ::

    from geonature.utils.env import DB
    from utils_flask_sqla_geo.serializers import shapeserializable


    @shapeserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


  Fichier utilisation modèle::

    # utilisation de as_shape()
    data = DB.session.query(MyShapeserializableClass).all()
    MyShapeserializableClass.as_shape(
        geom_col='geom_4326',
        srid=4326,
        data=data,
        dir_path=str(ROOT_DIR / 'backend/static/shapefiles'),
        file_name=file_name
    )

- ``utils_flask_sqla_geo.utilsgeometry.FionaShapeService``

  Classe utilitaire pour créer des shapefiles.

  La classe contient 3 méthodes de classe :

- FionaShapeService.create_shapes_struct() : crée la structure de 3 shapefiles
  (point, ligne, polygone) à partir des colonens et de la geométrie passée
  en paramètre

- FionaShapeService.create_feature() : ajoute un enregistrement
  aux shapefiles

- FionaShapeService.save_and_zip_shapefiles() : sauvegarde et zip les
  shapefiles qui ont au moins un enregistrement::

        data = DB.session.query(MySQLAModel).all()

        for d in data:
                FionaShapeService.create_shapes_struct(
                        db_cols=db_cols,
                        srid=current_app.config['LOCAL_SRID'],
                        dir_path=dir_path,
                        file_name=file_name,
                        col_mapping=current_app.config['SYNTHESE']['EXPORT_COLUMNS']
                )
        FionaShapeService.create_feature(row_as_dict, geom)
                FionaShapeService.save_and_zip_shapefiles()



- ``utils_flask_sqla_geo.serializers.json_resp``

  Décorateur pour les routes : les données renvoyées par la route sont
  automatiquement serialisées en json (ou geojson selon la structure des
  données).

  S'insère entre le décorateur de route flask et la signature de fonction

  Fichier routes ::

    from flask import Blueprint
    from utils_flask_sqla.response import json_resp

    blueprint = Blueprint(__name__)

    @blueprint.route('/myview')
    @json_resp
    def my_view():
        return {'result': 'OK'}


    @blueprint.route('/myerrview')
    @json_resp
    def my_err_view():
        return {'result': 'Not OK'}, 400

Export des données
******************

TODO


Utilisation de la configuration
*******************************

La configuration globale de l'application est controlée par le fichier
``config/geonature_config.toml`` qui contient un nombre limité de paramètres.
De nombreux paramètres sont néammoins passés à l'application via un schéma
Marshmallow (voir fichier ``backend/geonature/utils/config_schema.py``).

Dans l'application flask, l'ensemble des paramètres de configuration sont
utilisables via le dictionnaire ``config`` de l'application Flask ::

    from flask import current_app
    MY_PARAMETER = current_app.config['MY_PARAMETER']

Chaque module GeoNature dispose de son propre fichier de configuration,
(``module/config/cong_gn_module.toml``) contrôlé de la même manière par un
schéma Marshmallow (``module/config/conf_schema_toml.py``).
Pour récupérer la configuration du module dans l'application Flask,
il existe deux méthodes:

Dans le fichier ``blueprint.py`` ::

        # Methode 1 :

        from flask import current_app
        MY_MODULE_PARAMETER = current_app.config['MY_MODULE_NAME']['MY_PARAMETER]
        # ou MY_MODULE_NAME est le nom du module tel qu'il est défini dans le fichier ``manifest.toml`` et la table ``gn_commons.t_modules``

        #Méthode 2 :
        MY_MODULE_PARAMETER = blueprint.config['MY_MODULE_PARAMETER']

Il peut-être utile de récupérer l'ID du module GeoNature (notamment pour des
questions droits). De la même manière que précédement, à l'interieur d'une
route, on peut récupérer l'ID du module de la manière suivante ::

        ID_MODULE = blueprint.config['ID_MODULE']
        # ou
        ID_MODULE = current_app.config['MODULE_NAME']['ID_MODULE']

Si on souhaite récupérer l'ID du module en dehors du contexte d'une route,
il faut utiliser la méthode suivante ::

        from geonature.utils.env import get_id_module
        ID_MODULE = get_id_module(current_app, 'occtax')


Authentification avec pypnusershub
**********************************


Vérification des droits des utilisateurs
""""""""""""""""""""""""""""""""""""""""

- ``pypnusershub.routes.check_auth``

  Décorateur pour les routes : vérifie les droits de l'utilisateur et le
  redirige en cas de niveau insuffisant ou d'informations de session erronés
  (deprecated) Privilegier `check_cruved_scope`

  params :

  * level <int> : niveau de droits requis pour accéder à la vue
  * get_role <bool:False> : si True, ajoute l'id utilisateur aux kwargs de la vue

  ::

        from flask import Blueprint
        from pypnusershub.routes import check_auth
        from utils_flask_sqla.response import json_resp

        blueprint = Blueprint(__name__)

        @blueprint.route('/myview')
        @check_auth(
                1,
                True,
                )
        @json_resp
        def my_view(id_role):
                return {'result': 'id_role = {}'.format(id_role)}

- ``geonature.core.gn_permissions.decorators.check_cruved_scope``

  Décorateur pour les routes : Vérifie les droits de l'utilisateur à effectuer
  une action sur la donnée et le redirige en cas de niveau insuffisant ou
  d'informations de session erronées

  params :

  * action <str:['C','R','U','V','E','D']> type d'action effectuée par la route
    (Create, Read, Update, Validate, Export, Delete)
  * get_role <bool:False>: si True, ajoute l'id utilisateur aux kwargs de la vue
  * module_code: <str:None>: Code du module (gn_commons.t_modules) sur lequel on
    veut récupérer le CRUVED. Si ce paramètre n'est pas passer on vérifie le
    cruved de GeoNature


  ::

        from flask import Blueprint
        from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
        from utils_flask_sqla.response import json_resp
        from geonature.core.gn_permissions import decorators as permissions

        blueprint = Blueprint(__name__)

        @blueprint.route('/mysensibleview', methods=['GET'])
        @permissions.check_cruved_scope(
                'R',
                True,
                module_code="OCCTAX"
        )
        @json_resp
        def my_sensible_view(info_role):
            # Récupérer l'id de l'utilisateur qui demande la route
            id_role = info_role.id_role
            # Récupérer la portée autorisée à l'utilisateur pour l'action 'R' (read)
            read_scope = info_role.value_filter
            #récupérer le CRUVED complet de l'utilisateur courant
            user_cruved = get_or_fetch_user_cruved(
                    session=session,
                    id_role=info_role.id_role,
                    module_code=MY_MODULE_CODE,
            )
            return {'result': 'id_role = {}'.format(info_role.id_role)}

- ``geonature.core.gn_permissions.tools.cruved_scope_for_user_in_module``

  * Fonction qui retourne le CRUVED d'un utilisateur pour un module et/ou
    un objet donné.
  * Si aucun CRUVED n'est défini pour le module, c'est celui de GeoNature qui
    est retourné, sinon 0.
  * Le CRUVED du module enfant surcharge toujours celui du module parent.
  * Le CRUVED sur les objets n'est pas hérité du module parent.

  params :

  * id_role <integer:None>
  * module_code <str:None>: code du module sur lequel on veut avoir le CRUVED
  * object_code <str:'ALL'> : code de l'objet sur lequel on veut avoir le CRUVED

  Valeur retournée : tuple

  A l'indice 0 du tuple: <dict{str:str}> ou <dict{str:int}>, boolean)
  {'C': '1', 'R':'2', 'U': '1', 'V':'2', 'E':'3', 'D': '3'}

  A l'indice 1 du tuple: un booléan spécifiant si le CRUVED est hérité depuis
  un module parent ou non.

  ::

    from pypnusershub.db.tools import cruved_for_user_in_app

    # recuperer le cruved de l'utilisateur 1 dans le module OCCTAX
    cruved, herited = cruved_scope_for_user_in_module(
            id_role=1
            module_code='OCCTAX
    )
    # recupérer le cruved de l'utilisateur 1 sur GeoNature
    cruved, herited = cruved_scope_for_user_in_module(id_role=1)



Développement Frontend
----------------------

Bonnes pratiques
****************

- Chaque gn_module de GeoNature doit être un module Angular indépendant https://angular.io/guide/ngmodule. 
- Ce gn_module peut s'appuyer sur une série de composants génériques intégrés dans le module GN2CommonModule et décrit ci-dessous 

Les composants génériques
*************************

Un ensemble de composants décrits ci-dessous sont intégrés dans le coeur de GeoNature et permettent aux développeurs de simplifier la mise en place de formulaires ou de bloc cartographiques. 

Voir la `DOCUMENTATION COMPLETE <http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html>`_ sur les composants génériques. 


NB: mes composants de type "formulaire" (balise `input` ou `select`) partagent une logique commune et ont des ``Inputs`` et des ``Outputs`` communs décrit ci dessous. (voir https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/app/GN2CommonModule/form/genericForm.component.ts).

Une documentation complète des composants générique est
`disponible ici <http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html>`_

NB: mes composants de type "formulaire" (balise `input` ou `select`) partagent
une logique commune et ont des ``Inputs`` et des ``Outputs`` communs décrit
ci dessous.
(voir https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/app/GN2CommonModule/form/genericForm.component.ts).

- Inputs

  - L'input ``parentFormControl`` de type ``FormControl`` (https://angular.io/api/forms/FormControl) permet de contrôler la logique et les valeurs du formulaire depuis l'extérieur du composant. Cet input est **obligatoire** pour le fonctionnement du composant.
  - L'input ``label`` (string) permet d'afficher un label au dessus de l'input.
  - L'input ``displayAll`` (boolean, défaut = false) permet d'ajouter un item 'tous' sur les inputs de type select (Exemple : pour sélectionner tous les jeux de données de la liste)
  - L'input ``multiSelect`` (boolean, défaut = false) permet de passer les composants de type select en "multiselect" (sélection multiple sur une liste déroulante). Le parentFormControl devient par conséquent un tableau
  - L'input ``searchBar`` (boolean, défaut = false) permet de rajouter une barre de recherche sur les composants multiselect
  - L'input ``disabled`` (boolean) permet de rendre le composant non-saisissable
  - L'input ``debounceTime`` définit une durée en ms après laquelle les évenements ``onChange`` et ``onDelete`` sont déclenchés suite à un changement d'un formulaire. (Par défault à 0)

- Outputs

  Plusieurs ``Output`` communs à ses composants permettent d'émettre des événements liés aux formulaires.

  - ``onChange`` : événement émit à chaque fois qu'un changement est effectué sur le composant. Renvoie la valeur fraiche de l'input.
  - ``onDelete`` : événement émit chaque fois que le champ du formulaire est supprimé. Renvoie un évenement vide.

Ces composants peuvent être considérés comme des "dump components" ou
"presentation components", puisque que la logique de contrôle est déporté
au composant parent qui l'accueil
(https://blog.angular-university.io/angular-2-smart-components-vs-presentation-components-whats-the-difference-when-to-use-each-and-why/)

Un ensemble de composant permattant de simplifier l'affichage des cartographies
leaflet sont disponible. Notamment un composant "map-list" permettant de
connecter une carte avec une liste d'objet décrit en détail ci dessous.

- **MapListComponent**

Le composant MapList fournit une carte pouvant être synchronisé
avec une liste. La liste, pouvant être spécifique à chaque module,
elle n'est pas intégré dans le composant et est laissé à la
responsabilité du développeur. Le service ``MapListService`` offre
cependant des fonctions permettant facilement de synchroniser
les deux éléments.

Fonctionnalité et comportement offert par le composant et le
service :

 - Charger les données
      
  Le service expose la fonction ``getData(apiEndPoint, params?)``
  permettant de charger les données pour la carte et la liste.
  Cette fonction doit être utilisée dans le composant qui utilise
  le composant ``MapListComponent``. Elle se charge de faire
  appel à l'API passé en paramètre et de rendre les données
  disponibles au service.

  Le deuxième paramètre ``params`` est un tableau de paramètre(s)
  (facultatif). Il permet de filtrer les données sur n'importe
  quelle propriété du GeoJson, et également de gérer
  la pagination.

  Exemple : afficher les 10 premiers relevés du cd_nom 212 :

  ::

        mapListService.getData('occtax/releve',
        [{'param': 'limit', 'value': 10'},
        {'param': 'cd_nom', 'value': 212'}])

  `Exemple dans le module OccTax  <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/modules/occtax/occtax-map-list/occtax-map-list.component.ts#L84/>`_

  L'API doit nécessairement renvoyer un objet comportant un
  GeoJson. La structure du l'objet doit être la suivante :

  ::

        'total': nombre d'élément total,
        'total_filtered': nombre d'élément filtré,
        'page': numéro de page de la liste,
        'limit': limite d'élément renvoyé,
        'items': le GeoJson

  Pour une liste simple sans pagination, seule la propriété 'items'
  est obligatoire.

  - Rafraîchir les données
        
  La fonction ``refreshData(apiEndPoint, method, params?)`` permet de raffrachir les données en fonction de filtres personnalisés.
  Les paramètres ``apiEndPoint`` et ``params`` sont les mêmes que pour la fonction ``getData``. Le paramètre ``method`` permet lui de chosir si on ajoute - ``append``- , ou si on initialise (ou remplace) -``set``- un filtre.

  Exemple 1 : Pour filtrer sur l'observateur 1, puis ajouter un filtre sur l'observateur 2.

                ``mapListService.refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 1'}])``

                puis

                ``refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 2'}])``

                Exemple 2: pour filtrer sur le cd_nom 212, supprimer ce filtre et filtrer sur  le cd_nom 214

                ``mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 1'}])``

                puis

                ``mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 2'}])``

        - Gestion des évenements :
        
                - Au clic sur un marker de la carte, le service ``MapListService`` expose la propriété ``selectedRow`` qui est un tableau contenant l'id du marker sélectionné. Il est ainsi possible de surligner l'élément séléctionné dans le liste.
                - Au clic sur une ligne du tableau, utiliser la fonction ``MapListService.onRowSelected(id)`` (id étant l'id utilisé dans le GeoJson) qui permet de zoomer sur le point séléctionner et de changer la couleur de celui-ci.

        La service contient également deux propriétés publiques ``geoJsonData`` (le geojson renvoyé par l'API) et ``tableData`` (le tableau de features du Geojson) qui sont respectivement passées à la carte et à la liste. Ces deux propriétés sont utilisables pour intéragir (ajouter, supprimer) avec les données de la carte et de la liste.

        **Selector**: ``pnx-map-list``

        **Inputs**:

        :``idName``:
                        Libellé de l'id du geojson (id_releve, id)

                        Type: ``string``
        :``height``:
                        Taille de l'affichage de la carte Leaflet

                        Type: ``string``


        Exemple d'utilisation avec une liste simple :
        
        ::

                <pnx-map-list
                        idName="id_releve_occtax"
                        height="80vh">
                </pnx-map-list>
                <table>
                        <tr ngFor="let row of mapListService.tableData" [ngClass]=" {'selected': mapListService.selectedRow[0]} == row.id ">
                                <td (click)="mapListService.onRowSelect(row.id)"> Zoom on map </td>
                                <td > {{row.observers}} </td>
                                <td > {{row.date}} </td>
                        </tr>
                </table>


Outils d'aide à la qualité du code
----------------------------------

Des outils d'amélioration du code pour les développeurs peuvent être utilisés :
flake8, pylint, pytest, coverage.

La documentation peut être générée avec Sphinx.

Les fichiers de configuration de ces outils se trouvent à la racine du projet :

* .pylint

Un fichier ``.editorconfig`` permettant de définir le comportement de
votre éditeur de code est également disponible à la racine du projet.


Sphinx
******

Sphinx est un générateur de documentation.

Pour générer la documentation HTML, se placer dans le répertoire ``docs``
et modifier les fichiers .rst::

        cd docs
        make html


Pylint
******

Pylint fait la même chose que Flake8 mais il est plus complet, plus
configurable mais aussi plus exigeant.

Pour inspecter le répertoire ``geonature``::

        cd backend
        pylint geonature

tslint
******

tslint fait la même chose que pylint mais pour la partie frontend en
typescript::

        cd frontend
        ng lint



Pytest
******

Pytest permet de mettre en place des tests fonctionnels et automatisés
du code Python.

Les fichiers de test sont dans le répertoire ``backend/tests``

::

        cd backend
        pytest


Coverage
********

Coverage permet de donner une indication concernant la couverture du code
par les tests.

::

        cd backend
        pytest --cov=geonature --cov-report=html

Ceci génénère un rapport html disponible dans  ``backend/htmlcov/index.html``.
