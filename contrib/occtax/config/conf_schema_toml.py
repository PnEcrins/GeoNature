"""
   Spécification du schéma toml des paramètres de configurations
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
"""

from marshmallow import Schema, fields


class MapListConfig(Schema):
    pass


class FormConfig(Schema):
    date_min = fields.Boolean(missing=True)
    date_max = fields.Boolean(missing=True)
    hour_min = fields.Boolean(missing=True)
    hour_max = fields.Boolean(missing=True)
    altitude_min = fields.Boolean(missing=True)
    altitude_max = fields.Boolean(missing=True)
    depth_min = fields.Boolean(missing=False)
    depth_max = fields.Boolean(missing=False)
    altitude_max = fields.Boolean(missing=True)
    tech_collect = fields.Boolean(missing=False)
    group_type = fields.Boolean(missing=False)
    comment_releve = fields.Boolean(missing=True)
    obs_tech = fields.Boolean(missing=True)
    bio_condition = fields.Boolean(missing=True)
    bio_status = fields.Boolean(missing=True)
    naturalness = fields.Boolean(missing=True)
    exist_proof = fields.Boolean(missing=True)
    observation_status = fields.Boolean(missing=True)
    blurring = fields.Boolean(missing=False)
    determiner = fields.Boolean(missing=True)
    determination_method = fields.Boolean(missing=True)
    digital_proof = fields.Boolean(missing=True)
    non_digital_proof = fields.Boolean(missing=True)
    source_status = fields.Boolean(missing=False)
    comment_occ = fields.Boolean(missing=True)
    life_stage = fields.Boolean(missing=True)
    sex = fields.Boolean(missing=True)
    obj_count = fields.Boolean(missing=True)
    type_count = fields.Boolean(missing=True)
    count_min = fields.Boolean(missing=True)
    count_max = fields.Boolean(missing=True)
    display_nom_valide = fields.Boolean(missing=True)
    geo_object_nature = fields.Boolean(missing=False)
    habitat = fields.Boolean(missing=True)
    grp_method = fields.Boolean(missing=False)
    behaviour = fields.Boolean(missing=True)
    place_name = fields.Boolean(missing=False)
    precision = fields.Boolean(missing=False)


default_map_list_conf = [
    {"prop": "taxons", "name": "Taxon(s)"},
    {"prop": "observateurs", "name": "Observateurs"},
    {"prop": "date", "name": "Date"},
    {"prop": "dataset", "name": "Jeu de données"},
]

available_maplist_column = [
    {"prop": "altitude_min", "name": "Altitude min"},
    {"prop": "altitude_max", "name": "Altitude max"},
    {"prop": "comment", "name": "Commentaire"},
    {"prop": "date", "name": "Date"},
    {"prop": "date_min", "name": "Date début"},
    {"prop": "date_max", "name": "Date fin"},
    {"prop": "id_dataset", "name": "ID jeu de données"},
    {"prop": "dataset", "name": "Jeu de données"},
    {"prop": "id_digitiser", "name": "ID rédacteur"},
    {"prop": "id_releve_occtax", "name": "ID relevé"},
    {"prop": "observateurs", "name": "Observateurs"},
    {"prop": "nb_taxons", "name": "Nb. taxon"},
]

default_columns_export = [
    "permId",
    "statObs",
    "nomCite",
    "dateDebut",
    "dateFin",
    "heureDebut",
    "heureFin",
    "altMax",
    "altMin",
    "profMin",
    "profMax",
    "cdNom",
    "cdRef",
    "versionTAXREF",
    "datedet",
    "comment",
    "dSPublique",
    "jddMetadonneeDEEId",
    "statSource",
    "diffusionNiveauPrecision",
    "idOrigine",
    "jddCode",
    "jddId",
    "refBiblio",
    "obsTech",
    "techCollect",
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
    "obsDescr",
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
    "natObjGeo",
    "nomLieu",
    "precision",
]


# Formats d'export disponibles ["csv", "geojson", "shapefile", "gpkg"]
available_export_format = ["csv", "geojson", "shapefile"]

list_messages = {
    "emptyMessage": "Aucune donnée à afficher",
    "totalMessage": "Relevé(s) au total",
}

export_message = """
<p> <b> Attention: </b> </br>
Vous vous apprêtez à télécharger les données de la <b>recherche courante. </b> </p>
"""


class GnModuleSchemaConf(Schema):
    form_fields = fields.Nested(FormConfig, missing=dict())
    observers_txt = fields.Boolean(missing=False)
    export_view_name = fields.String(missing="v_export_occtax")
    export_geom_columns_name = fields.String(missing="geom_4326")
    export_id_column_name = fields.String(missing="permId")
    export_srid = fields.Integer(missing=4326)
    export_observer_txt_column = fields.String(missing="obsId")
    export_available_format = fields.List(
        fields.String(), missing=available_export_format
    )
    export_columns = fields.List(fields.String(), missing=default_columns_export)
    export_message = fields.String(missing=export_message)
    list_messages = fields.Dict(missing=list_messages)
    digital_proof_validator = fields.Boolean(missing=True)
    releve_map_zoom_level = fields.Integer()
    id_taxon_list = fields.Integer(missing=100)
    taxon_result_number = fields.Integer(missing=20)
    id_observers_list = fields.Integer(missing=1)
    default_maplist_columns = fields.List(fields.Dict(), missing=default_map_list_conf)
    available_maplist_column = fields.List(
        fields.Dict(), missing=available_maplist_column
    )
    MAX_EXPORT_NUMBER = fields.Integer(missing=50000)
    ENABLE_GPS_TOOL = fields.Boolean(missing=True)
    ENABLE_UPLOAD_TOOL = fields.Boolean(missing=True)
    DATE_FORM_WITH_TODAY = fields.Boolean(missing=True)
    ENABLE_SETTINGS_TOOLS = fields.Boolean(missing=False)
    ENABLE_MEDIAS = fields.Boolean(missing=True)
    ENABLE_MY_PLACES = fields.Boolean(missing=True)
    DEFAULT_DATASET_ID = fields.Integer(missing=None)
    DISPLAY_VERNACULAR_NAME = fields.Boolean(missing=True)
