"""
    Description des options de configuration
"""

import os

from marshmallow import (
    Schema,
    fields,
    validates_schema,
    ValidationError,
    post_load,
)
from marshmallow.validate import OneOf, Regexp, Email


from geonature.core.gn_synthese.synthese_config import (
    DEFAULT_EXPORT_COLUMNS,
    DEFAULT_LIST_COLUMN,
    DEFAULT_COLUMNS_API_SYNTHESE,
)
from geonature.utils.env import GEONATURE_VERSION
from geonature.utils.utilsmails import clean_recipients


class EmailStrOrListOfEmailStrField(fields.Field):
    def _deserialize(self, value, attr, data, **kwargs):
        if isinstance(value, str):
            self._check_email(value)
            return value
        elif isinstance(value, list) and all(isinstance(x, str) for x in value):
            self._check_email(value)
            return value
        else:
            raise ValidationError('Field should be str or list of str')
    
    def _check_email(self, value):
        recipients = clean_recipients(value)
        for recipient in recipients:
            email = recipient[1] if isinstance(recipient, tuple) else recipient
            # Validate email with Marshmallow
            validator = Email()
            validator(email)


class CasUserSchemaConf(Schema):
    URL = fields.Url(missing="https://inpn.mnhn.fr/authentication/information")
    ID = fields.String(missing="mon_id")
    PASSWORD = fields.String(missing="mon_pass")


class CasFrontend(Schema):
    CAS_AUTHENTIFICATION = fields.Boolean(missing="false")
    CAS_URL_LOGIN = fields.Url(missing="https://preprod-inpn.mnhn.fr/auth/login")
    CAS_URL_LOGOUT = fields.Url(missing="https://preprod-inpn.mnhn.fr/auth/logout")


class CasSchemaConf(Schema):
    CAS_URL_VALIDATION = fields.String(missing="https://preprod-inpn.mnhn.fr/auth/serviceValidate")
    CAS_USER_WS = fields.Nested(CasUserSchemaConf, missing=dict())
    USERS_CAN_SEE_ORGANISM_DATA = fields.Boolean(missing=False)
    # Quel modules seront associés au JDD récupérés depuis MTD

class MTDSchemaConf(Schema):
    JDD_MODULE_CODE_ASSOCIATION = fields.List(fields.String, missing=["OCCTAX", "OCCHAB"])
    ID_INSTANCE_FILTER = fields.Integer(missing=None)


class BddConfig(Schema):
    id_area_type_municipality = fields.Integer(missing=25)
    ID_USER_SOCLE_1 = fields.Integer(missing=8)
    ID_USER_SOCLE_2 = fields.Integer(missing=6)


class RightsSchemaConf(Schema):
    NOTHING = fields.Integer(missing=0)
    MY_DATA = fields.Integer(missing=1)
    MY_ORGANISM_DATA = fields.Integer(missing=2)
    ALL_DATA = fields.Integer(missing=3)


class MailConfig(Schema):
    MAIL_SERVER = fields.String(required=True)
    MAIL_PORT = fields.Integer(missing=465)
    MAIL_USE_TLS = fields.Boolean(missing=False)
    MAIL_USE_SSL = fields.Boolean(missing=True)
    MAIL_USERNAME = fields.String(required=True)
    MAIL_PASSWORD = fields.String(required=True)
    MAIL_DEFAULT_SENDER = fields.String(missing=None)
    MAIL_MAX_EMAILS = fields.Integer(missing=None)
    MAIL_ASCII_ATTACHMENTS = fields.Boolean(missing=False)
    ERROR_MAIL_TO = EmailStrOrListOfEmailStrField(missing=None)


class AccountManagement(Schema):
    # Configuration parameters for sign-up
    ENABLE_SIGN_UP = fields.Boolean(missing=False)
    ENABLE_USER_MANAGEMENT = fields.Boolean(missing=False)
    AUTO_ACCOUNT_CREATION = fields.Boolean(missing=True)
    AUTO_DATASET_CREATION = fields.Boolean(missing=True)
    VALIDATOR_EMAIL = EmailStrOrListOfEmailStrField(missing=None)
    ACCOUNT_FORM = fields.List(fields.Dict(), missing=[])
    ADDON_USER_EMAIL = fields.String(missing="")


class PermissionManagement(Schema):
    # Configuration parameters for permissions managment and access request
    ENABLE_ACCESS_REQUEST = fields.Boolean(missing=False)
    AREA_TYPES = fields.List(fields.Integer(), missing=[25, 26])
    DATA_ACCESS_RULES_LINK = fields.String(missing=None)
    DEFAULT_ACCESS_DURATION = fields.Integer(missing=None)
    MAX_ACCESS_DURATION = fields.Integer(missing=365)
    VALIDATOR_EMAIL = EmailStrOrListOfEmailStrField(missing=None)
    REQUEST_FORM_TITLE = fields.String(missing=None)
    REQUEST_FORM = fields.List(fields.Dict(), missing=[])
    ENABLE_CONVENTION = fields.Boolean(missing=False)
    CONVENTION_TITLE = fields.String(missing=None)
    CONVENTION_VALIDATE = fields.String(missing=None)


class UsersHubConfig(Schema):
    ADMIN_APPLICATION_LOGIN = fields.String()
    ADMIN_APPLICATION_PASSWORD = fields.String()
    URL_USERSHUB = fields.Url()


class ServerConfig(Schema):
    LOG_LEVEL = fields.Integer(missing=20)


class MediasConfig(Schema):
    MEDIAS_SIZE_MAX = fields.Integer(missing=50000)
    THUMBNAIL_SIZES = fields.List(fields.Integer, missing=[200, 50])


class MetadataConfig(Schema):
    NB_AF_DISPLAYED = fields.Integer(missing=50, validate=OneOf([10, 25, 50, 100]))
    ENABLE_CLOSE_AF = fields.Boolean(missing=False)
    AF_SHEET_CLOSED_LINK_NAME = fields.String(missing="Lien du certificat de dépôt")
    CLOSED_AF_TITLE = fields.String(missing="")
    AF_PDF_TITLE = fields.String(missing="Cadre d'acquisition: ")
    DS_PDF_TITLE = fields.String(missing="")
    MAIL_SUBJECT_AF_CLOSED_BASE = fields.String(missing="")
    MAIL_CONTENT_AF_CLOSED_ADDITION = fields.String(missing="")
    MAIL_CONTENT_AF_CLOSED_PDF = fields.String(missing="")
    MAIL_CONTENT_AF_CLOSED_URL = fields.String(missing="")
    MAIL_CONTENT_AF_CLOSED_GREETINGS = fields.String(missing="")
    CLOSED_MODAL_LABEL = fields.String(missing="Fermer un cadre d'acquisition")
    CLOSED_MODAL_CONTENT = fields.String(missing="""L'action de fermeture est irréversible. Il ne sera
    plus possible d'ajouter des jeux de données au cadre d'acquisition par la suite.""")


# Class to use for parameters you NOT want to pass to frontend
class GnPySchemaConf(Schema):
    SQLALCHEMY_DATABASE_URI = fields.String(
        required=True,
        validate=Regexp(
            "^postgresql:\/\/.*:.*@[^:]+:\w+\/\w+$",
            0,
            "Database uri is invalid ex: postgresql://monuser:monpass@server:port/db_name",
        ),
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = fields.Boolean(missing=True)
    SESSION_TYPE = fields.String(missing="filesystem")
    SECRET_KEY = fields.String(required=True)
    # le cookie expire toute les 7 jours par défaut
    COOKIE_EXPIRATION = fields.Integer(missing=3600 * 24 * 7)
    COOKIE_AUTORENEW = fields.Boolean(missing=True)
    TRAP_ALL_EXCEPTIONS = fields.Boolean(missing=False)

    UPLOAD_FOLDER = fields.String(missing="static/medias")
    BASE_DIR = fields.String(
        missing=os.path.dirname(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
    )
    CAS = fields.Nested(CasSchemaConf, missing=dict())
    MAIL_ON_ERROR = fields.Boolean(missing=False)
    MAIL_CONFIG = fields.Nested(MailConfig, missing=None)
    METADATA = fields.Nested(MetadataConfig, missing=dict())
    ADMIN_APPLICATION_LOGIN = fields.String()
    ACCOUNT_MANAGEMENT = fields.Nested(AccountManagement, missing={})
    PERMISSION_MANAGEMENT = fields.Nested(PermissionManagement, missing={})
    USERSHUB = fields.Nested(UsersHubConfig, missing={})
    SERVER = fields.Nested(ServerConfig, missing={})
    MEDIAS = fields.Nested(MediasConfig, missing={})

    @post_load()
    def unwrap_usershub(self, data):
        """
        On met la section [USERSHUB] à la racine de la conf
        pour compatibilité et simplicité ave le sous-module d'authentif
        """
        for key, value in data["USERSHUB"].items():
            data[key] = value
        data.pop("USERSHUB")
        return data

    @validates_schema
    def validate_enable_usershub_and_mail(self, data):
        # si account management = true, URL_USERSHUB et MAIL_CONFIG sont necessaire
        if data["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP", False) or data[
            "ACCOUNT_MANAGEMENT"
        ].get("ENABLE_USER_MANAGEMENT", False):
            if (
                data["USERSHUB"].get("URL_USERSHUB", None) is None
                or data["USERSHUB"].get("ADMIN_APPLICATION_LOGIN", None) is None
                or data["USERSHUB"].get("ADMIN_APPLICATION_PASSWORD", None) is None
            ):
                raise ValidationError(
                    "URL_USERSHUB, ADMIN_APPLICATION_LOGIN et ADMIN_APPLICATION_PASSWORD sont necessaires si ENABLE_SIGN_UP=True",
                    "URL_USERSHUB",
                )
            if (
                data["MAIL_CONFIG"].get("MAIL_SERVER", None) is None
                or data["MAIL_CONFIG"].get("MAIL_USERNAME", None) is None
                or data["MAIL_CONFIG"].get("MAIL_PASSWORD", None) is None
            ):
                raise ValidationError(
                    "Veuillez remplir la rubrique MAIL_CONFIG si ENABLE_SIGN_UP=True",
                    "ENABLE_SIGN_UP",
                )


class GnFrontEndConf(Schema):
    PROD_MOD = fields.Boolean(missing=True)
    DISPLAY_FOOTER = fields.Boolean(missing=True)
    DISPLAY_STAT_BLOC = fields.Boolean(missing=True)
    DISPLAY_MAP_LAST_OBS = fields.Boolean(missing=True)
    MULTILINGUAL = fields.Boolean(missing=False)
    # show email on synthese and validation info obs modal
    DISPLAY_EMAIL_INFO_OBS = fields.Boolean(missing=True)


id_municipality = BddConfig().load({}).data.get("id_area_type_municipality")


class Synthese(Schema):
    AREA_FILTERS = fields.List(
        fields.Dict, missing=[{"label": "Communes", "id_type": id_municipality}]
    )
    # Listes des champs renvoyés par l'API synthese '/synthese'
    # Si on veut afficher des champs personnalisés dans le frontend (paramètre LIST_COLUMNS_FRONTEND) il faut
    # d'abbord s'assurer que ces champs sont bien renvoyé par l'API !
    # Champs disponibles: tous ceux de la vue 'v_synthese_for_web_app
    COLUMNS_API_SYNTHESE_WEB_APP = fields.List(fields.String, missing=DEFAULT_COLUMNS_API_SYNTHESE)
    # Colonnes affichées sur la liste des résultats de la sytnthese
    LIST_COLUMNS_FRONTEND = fields.List(fields.Dict, missing=DEFAULT_LIST_COLUMN)
    EXPORT_COLUMNS = fields.List(fields.String(), missing=DEFAULT_EXPORT_COLUMNS)
    # Certaines colonnes sont obligatoires pour effectuer les filtres CRUVED
    EXPORT_ID_SYNTHESE_COL = fields.String(missing="id_synthese")
    EXPORT_ID_DATASET_COL = fields.String(missing="jdd_id")
    EXPORT_ID_DIGITISER_COL = fields.String(missing="id_digitiser")
    EXPORT_OBSERVERS_COL = fields.String(missing="observateurs")
    EXPORT_GEOJSON_4326_COL = fields.String(missing="geojson_4326")
    EXPORT_GEOJSON_LOCAL_COL = fields.String(missing="geojson_local")
    EXPORT_METADATA_ID_DATASET_COL = fields.String(missing="jdd_id")
    EXPORT_METADATA_ACTOR_COL = fields.String(missing="acteurs")
    # Formats d'export disponibles ["csv", "geojson", "shapefile", "gpkg"]
    EXPORT_FORMAT = fields.List(fields.String(), missing=["csv", "geojson", "shapefile"])
    # Nombre de résultat à afficher pour la rechercher autocompleté de taxon
    TAXON_RESULT_NUMBER = fields.Integer(missing=20)
    # Liste des id attributs Taxhub à afficher sur la fiche détaile de la synthese
    # et sur les filtres taxonomiques avancés
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer(), missing=[102, 103])
    # nom des colonnes de la table gn_synthese.synthese que l'on veux retirer des filres dynamiques
    # et de la modale d'information détaillée d'une observation
    # example = "[non_digital_proof]"
    EXCLUDED_COLUMNS = fields.List(fields.String(), missing=[])
    # Afficher ou non l'arbre taxonomique
    DISPLAY_TAXON_TREE = fields.Boolean(missing=True)
    # rajoute le filtre sur l'observers_txt en ILIKE sur les portée 1 et 2 du CRUVED
    CRUVED_SEARCH_WITH_OBSERVER_AS_TXT = fields.Boolean(missing=False)
    # Switch the observer form input in free text input (true) or in select input (false)
    SEARCH_OBSERVER_WITH_LIST = fields.Boolean(missing=False)
    # id of the observer list -- utilisateurs.t_menus
    ID_SEARCH_OBSERVER_LIST = fields.Integer(missing=1)
    # Nombre max d'observation à afficher sur la carte
    NB_MAX_OBS_MAP = fields.Integer(missing=50000)
    # clusteriser les layers sur la carte
    ENABLE_LEAFLET_CLUSTER = fields.Boolean(missing=True)
    # Nombre max d'observation dans les exports
    NB_MAX_OBS_EXPORT = fields.Integer(missing=50000)
    # Nombre des "dernières observations" affiché à l'arrive sur la synthese
    NB_LAST_OBS = fields.Integer(missing=100)

    # Display email on synthese and validation info obs modal
    DISPLAY_EMAIL = fields.Boolean(missing=True)


# On met la valeur par défaut de DISCONECT_AFTER_INACTIVITY inferieure à COOKIE_EXPIRATION
cookie_expiration = GnPySchemaConf().load({}).data.get("COOKIE_EXPIRATION")


# Map configuration
BASEMAP = [
    {
        "name": "OpenStreetMap",
        "url": "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
        "options": {
            "attribution": "&copy OpenStreetMap",
        },
    },
    {
        "name": "OpenTopoMap",
        "url": "//a.tile.opentopomap.org/{z}/{x}/{y}.png",
        "options": {
            "attribution": "© OpenTopoMap",
        },
    },
    {
        "name": "GoogleSatellite",
        "layer": "//{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
        "options": {
            "subdomains": ["mt0", "mt1", "mt2", "mt3"],
            "attribution": "© GoogleMap",
        },
    },
]


class MapConfig(Schema):
    BASEMAP = fields.List(fields.Dict(), missing=BASEMAP)
    CENTER = fields.List(fields.Float, missing=[46.52863469527167, 2.43896484375])
    ZOOM_LEVEL = fields.Integer(missing=6)
    ZOOM_LEVEL_RELEVE = fields.Integer(missing=15)
    # zoom appliqué sur la carte lorsque l'on clique sur une liste
    # ne s'applique qu'aux points
    ZOOM_ON_CLICK = fields.Integer(missing=18)


# Class to use for parameters you WANT to pass to frontend
class GnGeneralSchemaConf(Schema):
    appName = fields.String(missing="GeoNature2")
    LOGO_STRUCTURE_FILE = fields.String(missing="logo_structure.png")
    GEONATURE_VERSION = fields.String(missing=GEONATURE_VERSION.strip())
    DEFAULT_LANGUAGE = fields.String(missing="fr")
    PASS_METHOD = fields.String(missing="hash", validate=OneOf(["hash", "md5"]))
    DEBUG = fields.Boolean(missing=False)
    URL_APPLICATION = fields.Url(required=True)
    API_ENDPOINT = fields.Url(required=True)
    API_TAXHUB = fields.Url(required=True)
    LOCAL_SRID = fields.Integer(required=True, missing=2154)
    ID_APPLICATION_GEONATURE = fields.Integer(missing=3)
    XML_NAMESPACE = fields.String(missing="{http://inpn.mnhn.fr/mtd}")
    MTD_API_ENDPOINT = fields.Url(missing="https://preprod-inpn.mnhn.fr/mtd")
    CAS_PUBLIC = fields.Nested(CasFrontend, missing=dict())
    RIGHTS = fields.Nested(RightsSchemaConf, missing=dict())
    FRONTEND = fields.Nested(GnFrontEndConf, missing=dict())
    SYNTHESE = fields.Nested(Synthese, missing=dict())
    MAPCONFIG = fields.Nested(MapConfig, missing=dict())
    # Ajoute la surchouche 'taxonomique' sur l'API nomenclature
    ENABLE_NOMENCLATURE_TAXONOMIC_FILTERS = fields.Boolean(missing=True)
    BDD = fields.Nested(BddConfig, missing=dict())
    URL_USERSHUB = fields.Url(required=False)
    ACCOUNT_MANAGEMENT = fields.Nested(AccountManagement, missing={})
    PERMISSION_MANAGEMENT = fields.Nested(PermissionManagement, missing={})
    MEDIAS = fields.Nested(MediasConfig, missing={})
    UPLOAD_FOLDER = fields.String(missing="static/medias")
    METADATA = fields.Nested(MetadataConfig, missing={})
    MTD = fields.Nested(MTDSchemaConf, missing={})
    NB_MAX_DATA_SENSITIVITY_REPORT = fields.Integer(missing=1000000)

    @validates_schema
    def validate_enable_sign_up(self, data):
        # si CAS_PUBLIC = true and ENABLE_SIGN_UP = true
        if data.get("CAS_PUBLIC").get("CAS_AUTHENTIFICATION") and (
            data["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP", False)
            or data["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT", False)
        ):
            raise ValidationError(
                "CAS_PUBLIC et ENABLE_SIGN_UP ou ENABLE_USER_MANAGEMENT ne peuvent être activés ensemble",
                "ENABLE_SIGN_UP, ENABLE_USER_MANAGEMENT",
            )

    @validates_schema
    def validate_account_autovalidation(self, data):
        account_config = data.get("ACCOUNT_MANAGEMENT")
        if (
            not account_config.get("AUTO_ACCOUNT_CREATION", False)
            and account_config.get("VALIDATOR_EMAIL", None) is None
        ):
            raise ValidationError(
                "Si AUTO_ACCOUNT_CREATION = False, veuillez remplir le paramètre VALIDATOR_EMAIL",
                "AUTO_ACCOUNT_CREATION, VALIDATOR_EMAIL",
            )


class ManifestSchemaConf(Schema):
    package_format_version = fields.String(required=True)
    module_code = fields.String(required=True)
    module_version = fields.String(required=True)
    min_geonature_version = fields.String(required=True)
    max_geonature_version = fields.String(required=True)
    exclude_geonature_versions = fields.List(fields.String)


class ManifestSchemaProdConf(Schema):
    module_code = fields.String(required=True)
