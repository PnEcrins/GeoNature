"""
    Routes for gn_meta 
"""
import os
import base64
import datetime as dt
import io
import json
import logging

from pathlib import Path
from binascii import a2b_base64

from lxml import etree as ET

from flask import (
    Blueprint,
    current_app,
    request,
    render_template,
    send_from_directory,
    copy_current_request_context,
    Response,
)
from sqlalchemy.sql import text, exists, select, update
from sqlalchemy.sql.functions import func


from geonature.utils.env import DB, BACKEND_DIR
from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
    CorSensitivitySynthese,
)
from geonature.core.gn_synthese.routes import (
    taxa_distribution,
    get_bbox
)
from geonature.core.ref_geo.models import LAreas

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError
from pypnusershub.db.models import User

from binascii import a2b_base64

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    CorDatasetProtocol,
    CorDatasetTerritory,
    CorModuleDataset,
    TAcquisitionFramework,
    TAcquisitionFrameworkDetails,
    CorAcquisitionFrameworkActor,
    CorAcquisitionFrameworkObjectif,
    CorAcquisitionFrameworkVoletSINP,
)
from geonature.core.gn_commons.models import TModules
from geonature.core.users.models import VUserslistForallMenu
from geonature.core.gn_meta.repositories import (
    get_datasets_cruved,
    get_af_cruved,
    get_dataset_details_dict,
    filtered_af_query,
    filtered_ds_query,
)
from utils_flask_sqla.response import json_resp, to_csv_resp, generate_csv_content
from werkzeug.datastructures import Headers
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_meta.mtd import mtd_utils
import geonature.utils.filemanager as fm
import geonature.utils.utilsmails as mail


import threading

routes = Blueprint("gn_meta", __name__)

# get the root logger
log = logging.getLogger()
gunicorn_error_logger = logging.getLogger("gunicorn.error")


@routes.route("/list/datasets", methods=["GET"])
@json_resp
def get_datasets_list():
    q = DB.session.query(TDatasets)
    data = q.all()
    return [d.as_dict(columns=("id_dataset", "dataset_name")) for d in data]


# TODO: quel cruved on recupère sur une route comme celle là
# celui du module admin (meta) ou celui de geonature (route utilisé dans tous les modules...)
@routes.route("/datasets", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_datasets(info_role):
    """
    Get datasets list
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
    :query boolean active: filter on active fiel
    :query int id_acquisition_framework: get only dataset of given AF
    :returns:  `dict{'data':list<TDatasets>, 'with_erros': <boolean>}`
    """
    with_mtd_error = False
    if current_app.config["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"]:
        # synchronise the CA and JDD from the MTD WS
        try:
            mtd_utils.post_jdd_from_user(
                id_user=info_role.id_role, id_organism=info_role.id_organisme
            )
        except Exception as e:
            gunicorn_error_logger.info(e)
            log.error(e)
            with_mtd_error = True
    params = request.args.to_dict()
    recursif = params.get("recursif", True)
    if recursif == "false":
        recursif = False
    datasets = get_datasets_cruved(info_role, params, recursif=recursif)
    datasets_resp = {"data": datasets}
    if with_mtd_error:
        datasets_resp["with_mtd_errors"] = True
    if not datasets:
        return datasets_resp, 404
    return datasets_resp


@routes.route("/af_datasets_metadata", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_af_and_ds_metadata(info_role):
    """
    Get all AF with their datasets 
    The Cruved in only apply on dataset in order to see all the AF
    where the user have rights with its dataset
    Use in maplist
    Add the CRUVED permission for each row (Dataset and AD)
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
    :returns:  `dict{'data':list<AF with Datasets>, 'with_erros': <boolean>}`
    """
    with_mtd_error = False
    if current_app.config["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"]:
        # synchronise the CA and JDD from the MTD WS
        try:
            mtd_utils.post_jdd_from_user(
                id_user=info_role.id_role, id_organism=info_role.id_organisme
            )
        except Exception as e:
            gunicorn_error_logger.info(e)
            log.error(e)
            with_mtd_error = True
    params = request.args.to_dict()
    params["orderby"] = "dataset_name"
    if "selector" not in params:
        params["selector"] = None
    datasets = filtered_ds_query(info_role, params).distinct().all()
    if len(datasets) == 0:
        return {"data": []}
    ids_dataset_user = TDatasets.get_user_datasets(info_role, only_user=True)

    ids_dataset_organisms = TDatasets.get_user_datasets(info_role, only_user=False)
    ids_afs_user = TAcquisitionFramework.get_user_af(info_role, only_user=True)
    ids_afs_org = TAcquisitionFramework.get_user_af(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]


    #  get all af from the JDD filtered with cruved or af where users has rights
    ids_afs_cruved = (
        [d.id_acquisition_framework for d in get_af_cruved(info_role, as_model=True)]
        if not params["selector"]
        else []
    )
    list_id_af = [d.id_acquisition_framework for d in datasets] + ids_afs_cruved
    afs = (
        filtered_af_query(request.args)
        .filter(TAcquisitionFramework.id_acquisition_framework.in_(list_id_af))
        .order_by(TAcquisitionFramework.acquisition_framework_name)
        .all()
    )
    list_id_af = [af.id_acquisition_framework for af in afs]

    afs_dict = []
    #  get cruved for each AF and prepare dataset
    for af in afs:
        af_dict = af.as_dict(
            True,
            relationships=[
                "creator",
                "cor_af_actor",
                "nomenclature_actor_role",
                "organism",
                "role",
            ],
        )
        af_dict["cruved"] = af.get_object_cruved(
            user_cruved=user_cruved,
            id_object=af.id_acquisition_framework,
            ids_object_user=ids_afs_user,
            ids_object_organism=ids_afs_org,
        )
        af_dict["datasets"] = []
        af_dict["deletable"] = is_af_deletable(af.id_acquisition_framework)
        afs_dict.append(af_dict)

    #  get cruved for each ds and push them in the af
    for d in datasets:
        dataset_dict = d.as_dict(
            recursif=True,
            relationships=[
                "creator",
                "cor_dataset_actor",
                "nomenclature_actor_role",
                "organism",
                "role",
            ],
        )
        if d.id_acquisition_framework not in list_id_af:
            continue
        dataset_dict["cruved"] = d.get_object_cruved(
            user_cruved=user_cruved,
            id_object=d.id_dataset,
            ids_object_user=ids_dataset_user,
            ids_object_organism=ids_dataset_organisms,
        )
        # dataset_dict["observation_count"] = (
        #     DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset == d.id_dataset).count()
        # )
        dataset_dict["deletable"] = is_dataset_deletable(d.id_dataset)
        af_of_dataset = get_af_from_id(d.id_acquisition_framework, afs_dict)
        af_of_dataset["datasets"].append(dataset_dict)

    afs_resp = {"data": afs_dict}
    if with_mtd_error:
        afs_resp["with_mtd_errors"] = True
    if not datasets:
        return afs_resp, 404
    return afs_resp


def is_dataset_deletable(id_dataset):
    datas = DB.session.query(Synthese.id_synthese).filter(Synthese.id_dataset == id_dataset).all()
    if datas:
        return False
    return True


def is_af_deletable(id_af):
    datasets = (
        DB.session.query(TDatasets.id_dataset)
        .filter(TDatasets.id_acquisition_framework == id_af)
        .all()
    )
    if datasets:
        return False
    return True


def get_af_from_id(id_af, af_list):
    found_af = None
    for af in af_list:
        if af["id_acquisition_framework"] == id_af:
            found_af = af
            break
    return found_af


@routes.route("/dataset/<id_dataset>", methods=["GET"])
@json_resp
def get_dataset(id_dataset):
    """
    Get one dataset

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDataset>
    """
    data = DB.session.query(TDatasets).get(id_dataset)
    cor = data.cor_dataset_actor
    dataset = data.as_dict(True)
    organisms = []
    for c in cor:
        if c.organism:
            organisms.append(c.organism.as_dict())
        else:
            organisms.append(None)
    i = 0
    for o in organisms:
        dataset["cor_dataset_actor"][i]["organism"] = o
        i = i + 1
    return dataset


@routes.route("/dataset_details/<int:id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_dataset_details(info_role, id_dataset):
    """
    Get one dataset with nomenclatures and af

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDatasetDetails>
    """

    return get_dataset_details_dict(id_dataset, info_role)

def decode_bytesio(b):
    """ Return the decoded value of a map/chart image saved in a BytesIO
    """
    base = base64.b64encode(b.getvalue())
    decoded = base.decode('ascii')
    return decoded

def create_taxa_chart(id_dataset=None, id_af=None):
    """Create a png chart of the taxonomic distribution using the matplotlib library
    """
    import matplotlib.pyplot as plt
    import numpy as np

    if (id_dataset):
        response = taxa_distribution(id_dataset=id_dataset, rank="group2_inpn")
    elif (id_af):
        response = taxa_distribution(id_af=id_af, rank="group2_inpn")
        
    distribution = json.loads(response.data)
    try:
        if distribution['message'] == "not found":
            return
    except TypeError:
        pass

    count = []
    group = []
    for taxa in distribution:
        count.append(taxa['count'])
        group.append(taxa['group'])

    def func(pct, allvals):
        absolute = int(pct/100.*np.sum(allvals))
        return "{:.1f}%\n({:d})".format(pct, absolute)

    fig, ax = plt.subplots(figsize=(6, 3.5), subplot_kw=dict(aspect="equal"))

    wedges, texts, autotexts = ax.pie(count,
        autopct=lambda pct: func(pct, count),
        wedgeprops=dict(width=0.65),
        startangle=-40,
        radius=1.5,
        pctdistance=0.75)

    bbox_props = dict(boxstyle="square,pad=0.3", fc="w", ec="k", lw=0.72)
    kw = dict(arrowprops=dict(arrowstyle="-"),
            bbox=bbox_props, zorder=0, va="center")

    ax.legend(wedges, group,
          loc="center left",
          bbox_to_anchor=(0, 0.5),
          bbox_transform=plt.gcf().transFigure,
          fontsize="x-large")

    plt.setp(autotexts, size='x-large')
    plt.tight_layout()
    plt.subplots_adjust(left=0.35)

    b = io.BytesIO()
    plt.savefig(b, format='png')
    return decode_bytesio(b)


def create_taxa_map(id_dataset=None, bbox=None):
    """ Create a svg map of the taxonomic repartition using the staticmaps libary
    """
    import staticmaps

    if not bbox:
        response = get_bbox(id_dataset=id_dataset)
        bbox = json.loads(response.data)
        try:
            if bbox['message'] == "not found":
                return
        except KeyError:
            pass

    if bbox['coordinates']:
        context = staticmaps.Context()
        context.set_tile_provider(staticmaps.tile_provider_OSM)
        
        if bbox['type'] == 'Point':
            bbox_coordinates = staticmaps.create_latlng(bbox['coordinates'][1], bbox['coordinates'][0])
            context.add_object(staticmaps.Marker(bbox_coordinates, color=staticmaps.BLUE, size=12))
            
        elif bbox['type'] == 'Polygon':
            bbox_coordinates = []
            for coordinates in bbox['coordinates'][0]:
                reversed = coordinates.copy()
                reversed.reverse()
                bbox_coordinates.append(reversed)
            context.add_object(
                staticmaps.Area(
                    [staticmaps.create_latlng(lat, lng) for lat, lng in bbox_coordinates],
                    fill_color=staticmaps.parse_color("#87CEFA3F"),
                    width=2,
                    color=staticmaps.BLUE,
                )
            )

        b = io.BytesIO()
        image = context.render_cairo(800, 500)
        image.write_to_png(b)
        return decode_bytesio(b)


@routes.route("/dataset/<int:ds_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
@json_resp
def delete_dataset(info_role, ds_id):
    """
    Delete a dataset

    .. :quickref: Metadata;
    """

    if not is_dataset_deletable(ds_id):
        raise GeonatureApiError(
            "La suppression du jeu de données n'est pas possible car des données y sont rattachées dans la Synthèse",
            500,
        )

    DB.session.query(CorDatasetActor).filter(CorDatasetActor.id_dataset == ds_id).delete()

    DB.session.query(CorDatasetProtocol).filter(CorDatasetProtocol.id_dataset == ds_id).delete()

    DB.session.query(CorDatasetTerritory).filter(CorDatasetTerritory.id_dataset == ds_id).delete()

    DB.session.query(CorModuleDataset).filter(CorModuleDataset.id_dataset == ds_id).delete()

    DB.session.query(TDatasets).filter(TDatasets.id_dataset == ds_id).delete()

    DB.session.commit()

    return "OK"


@routes.route("/uuid_report", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def uuid_report(info_role):
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """

    params = request.args
    ds_id = params.get("id_dataset")
    id_import = params.get("id_import")
    id_module = params.get("id_module")

    query = DB.session.query(Synthese).select_from(Synthese)

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    if ds_id:
        query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
        )

    data = query.all()

    data = [
        {
            "identifiantOrigine": row.entity_source_pk_value,
            "identifiant_gn": row.id_synthese,
            "identifiantPermanent (SINP)": row.unique_id_sinp,
            "nomcite": row.nom_cite,
            "jourDateDebut": row.date_min,
            "jourDatefin": row.date_max,
            "observateurIdentite": row.observers,
        }
        for row in query.all()
    ]

    return to_csv_resp(
        filename="filename",
        data=data,
        columns=[
            "identifiantOrigine",
            "identifiant_gn",
            "identifiantPermanent (SINP)",
            "nomcite",
            "jourDateDebut",
            "jourDatefin",
            "observateurIdentite",
        ],
    )


@routes.route("/sensi_report", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def sensi_report(info_role):
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """

    params = request.args
    ds_id = params["id_dataset"]
    dataset = TDatasets.query.get_or_404(ds_id)
    id_import = params.get("id_import")
    id_module = params.get("id_module")

    query = (
        DB.session.query(
            Synthese,
            func.taxonomie.find_cdref(Synthese.cd_nom).label("cd_ref"),
            func.array_agg(LAreas.area_name).label("codeDepartementCalcule"),
            func.ref_nomenclatures.get_cd_nomenclature(Synthese.id_nomenclature_sensitivity).label(
                "cd_sensi"
            ),
            func.ref_nomenclatures.get_nomenclature_label(
                Synthese.id_nomenclature_bio_status, "fr"
            ).label("occStatutBiologique"),
            func.min(CorSensitivitySynthese.meta_update_date).label("sensiDateAttribution"),
            func.min(CorSensitivitySynthese.sensitivity_comment).label("sensiAlerte"),
            TNomenclatures.cd_nomenclature,
            TNomenclatures.label_fr
        )
        .select_from(Synthese)
        .outerjoin(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
        .outerjoin(LAreas, LAreas.id_area == CorAreaSynthese.id_area)
        .outerjoin(
            CorSensitivitySynthese,
            CorSensitivitySynthese.uuid_attached_row == Synthese.unique_id_sinp,
        )
        .outerjoin(
            TNomenclatures, TNomenclatures.id_nomenclature == Synthese.id_nomenclature_sensitivity
        )
        .filter(LAreas.id_type == func.ref_geo.get_id_area_type("DEP"))
    )

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
        )

    data = query.group_by(Synthese.id_synthese, TNomenclatures.cd_nomenclature, TNomenclatures.label_fr).all()

    str_productor = ""
    header = ""
    if len(data) > 0:
        index_productor = -1
        if dataset.cor_dataset_actor:
            for index, actor in enumerate(dataset.cor_dataset_actor):
                # cd_nomenclature producteur = 6
                if actor.nomenclature_actor_role.cd_nomenclature == "6":
                    index_productor = index
            productor = (
                dataset.cor_dataset_actor[index_productor] if index_productor != -1 else None
            )
            if productor:
                if not productor.organism:
                    str_productor = productor.role.nom_complet
                else:
                    str_productor = productor.organism.nom_organisme
    data = [
        {
            "cdNom": row.Synthese.cd_nom,
            "cdRef": row.cd_ref,
            "codeDepartementCalcule": ", ".join(row.codeDepartementCalcule),
            "identifiantOrigine": row.Synthese.entity_source_pk_value,
            "occStatutBiologique": row.occStatutBiologique,
            "identifiantPermanent": row.Synthese.unique_id_sinp,
            "sensiAlerte": row.sensiAlerte,
            "sensible": "Oui" if row.cd_sensi != "0" else "Non",
            "sensiDateAttribution": row.sensiDateAttribution,
            "sensiNiveau": f"{row.cd_nomenclature} = {row.label_fr}" ,
        }
        for row in data
    ]
    sensi_version = DB.session.query(func.gn_commons.get_default_parameter('ref_sensi_version')).one_or_none()
    if sensi_version:
        sensi_version = sensi_version[0]
    # set an header only if the rapport is on a dataset
    header = f""""Rapport de sensibilité"
        "Jeu de données";"{dataset.dataset_name}"
        "Identifiant interne";"{dataset.id_dataset}"
        "Identifiant SINP";"{dataset.unique_dataset_id}"
        "Organisme/personne fournisseur";"{str_productor}"
        "Date de création du rapport";"{dt.datetime.now().strftime("%d/%m/%Y %Hh%M")}"
        "Nombre de données sensibles";"{len(list(filter(lambda row: row["sensible"] == "Oui", data)))}"
        "Nombre de données total dans le fichier";"{len(data)}"
        "sensiVersionReferentiel";"{sensi_version}"
        """

    return my_csv_resp(
        filename="filename",
        data=data,
        columns=[
            "cdNom",
            "cdRef",
            "codeDepartementCalcule",
            "identifiantOrigine",
            "occStatutBiologique",
            "identifiantPermanent",
            "sensiAlerte",
            "sensible",
            "sensiDateAttribution",
            "sensiNiveau",
        ],
        _header=header,
    )


def my_csv_resp(filename, data, columns, _header, separator=";"):

    headers = Headers()
    headers.add("Content-Type", "text/plain")
    headers.add("Content-Disposition", "attachment", filename="export_%s.csv" % filename)
    out = _header + generate_csv_content(columns, data, separator)
    return Response(out, headers=headers)


@routes.route("/update_sensitivity", methods=["GET"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
def update_sensitivity(info_role):
    """
    Update sensitivity of all datasets

    .. :quickref: Metadata;
    """

    params = request.args
    id_import = params.get("id_import")
    id_source = params.get("id_source")
    ds_id = params.get("ds_id")
    id_module = params.get("id_module")
    id_synthese = params.get("id_synthese")

    query = DB.session.query(Synthese.id_synthese).select_from(Synthese)

    if id_source:
        query = query.filter(Synthese.id_source == id_source)

    if id_synthese:
        query = query.filter(Synthese.id_synthese == id_synthese)

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    if ds_id:
        query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
        )

    id_syntheses = query.all()

    # id_syntheses = DB.session.query(Synthese.id_synthese).all()
    id_syntheses = [id[0] for id in id_syntheses]

    if len(id_syntheses) == 0:
        return "OK"

    if len(id_syntheses) > current_app.config["NB_MAX_DATA_SENSITIVITY_REPORT"]:

        @copy_current_request_context
        def update_sensitivity_task(id_syntheses):
            return update_sensitivity_query(id_syntheses)

        a = threading.Thread(
            name="update_sensitivity_task",
            target=update_sensitivity_task,
            kwargs={"id_syntheses": id_syntheses},
        )
        a.start()

        return "Processing"

    else:
        return update_sensitivity_query(id_syntheses)


# TODO: a écrire dans cor_sensitivy_synthese
def update_sensitivity_query(id_syntheses):

    queryStr = (
        """
        UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = gn_sensitivity.get_id_nomenclature_sensitivity(
            date_min::date,
            taxonomie.find_cdref(cd_nom),
            the_geom_local,
            ('{"STATUT_BIO": ' || id_nomenclature_bio_status::text || '}')::jsonb)
            where id_synthese in ("""
        + str(id_syntheses).strip("[]")
        + """)
        ; """
    )

    DB.engine.execute(queryStr)

    return "OK"


@routes.route("/dataset", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
@json_resp
def post_dataset(info_role):
    """
    Post a dataset

    .. :quickref: Metadata;
    """
    data = dict(request.get_json())
    cor_dataset_actor = data.pop("cor_dataset_actor")
    modules = data.pop("modules")

    dataset = TDatasets(**data)
    for cor in cor_dataset_actor:
        # remove id_cda if None otherwise merge no working well
        if "id_cda" in cor and cor.get("id_cda") is None:
            cor.pop("id_cda")
        dataset.cor_dataset_actor.append(CorDatasetActor(**cor))

    # init the relationship as an empty list
    modules_obj = DB.session.query(TModules).filter(TModules.id_module.in_(modules)).all()
    dataset.modules = modules_obj
    if dataset.id_dataset:
        DB.session.merge(dataset)
    # add id_digitiser only on creation
    else:
        dataset.id_digitizer = info_role.id_role
        DB.session.add(dataset)
    DB.session.commit()
    return dataset.as_dict(True)


@routes.route("/dataset/export_pdf/<id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_dataset(id_dataset, info_role):
    """
    Get a PDF export of one dataset
    """
    df = get_dataset_details_dict(id_dataset, info_role)

    if info_role.value_filter != "3":
        try:
            user_actor = [cor["id_role"] for cor in df["cor_dataset_actor"] if cor["id_role"]]
            user_actor.append(df.get('id_digitizer'))
            if info_role.value_filter == "1":
                assert info_role.id_role in user_actor
            elif info_role.value_filter == "2":
                organisms = [cor["id_organism"] for cor in df["cor_dataset_actor"] if cor["id_organism"]]
                assert info_role.id_role in user_actor or info_role.id_organisme in organisms
        except AssertionError:
            raise InsufficientRightsError(
                ('User "{}" cannot export this current dataset').format(info_role.id_role), 403,
            )

    if not df:
        return (
            render_template(
                "error.html",
                error="Le dataset presente des erreurs",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

    if len(df["dataset_desc"]) > 240:
        df["dataset_desc"] = df["dataset_desc"][:240] + "..."

    df["css"] = {
        "logo": "Logo_pdf.png",
        "bandeau": "Bandeau_pdf.png",
        "entite": "sinp",
    }
    df["title"] = current_app.config["METADATA"]["DS_PDF_TITLE"]

    date = dt.datetime.now().strftime("%d/%m/%Y")

    df["footer"] = {
        "url": current_app.config["URL_APPLICATION"] + "/#/metadata/dataset_detail/" + id_dataset,
        "date": date,
    }

    filename = "jdd_{}_{}_{}.pdf".format(
        id_dataset,
        df["dataset_shortname"].replace(" ", "_"),
        dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
    )
    
    chart = create_taxa_chart(id_dataset=id_dataset)
    if chart:
        df["chart"] = chart

    map = create_taxa_map(id_dataset=id_dataset)
    if map:
        df["map"] = map

    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf("dataset_template_pdf.html", df, filename)
    pdf_file_posix = Path(pdf_file)

    return send_from_directory(str(pdf_file_posix.parent), pdf_file_posix.name, as_attachment=True)


@routes.route("/acquisition_frameworks", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_acquisition_frameworks(info_role):
    """
    Get all AF with cruved filter

    .. :quickref: Metadata;

    """
    params = request.args
    return get_af_cruved(info_role, params)


@routes.route("/acquisition_frameworks/export_pdf/<id_acquisition_framework>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_acquisition_frameworks(id_acquisition_framework, info_role):
    """
    Get a PDF export of one acquisition
    """

    # Recuperation des données
    af = DB.session.query(TAcquisitionFrameworkDetails).get(id_acquisition_framework)
    acquisition_framework = af.as_dict(True)

    q = DB.session.query(TDatasets).distinct()
    data = q.filter(TDatasets.id_acquisition_framework == id_acquisition_framework).all()
    dataset_ids = [d.id_dataset for d in data]
    acquisition_framework["datasets"] = [d.as_dict(True) for d in data]
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .first()[0]
    )
    if geojsonData:
        acquisition_framework["bbox"] = json.loads(geojsonData)
    else:
        acquisition_framework["bbox"] = None
    nb_data = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset.in_(dataset_ids)).count()
    )
    nb_habitat = 0

    # Check if pr_occhab exist
    check_schema_query = exists(
        select([text("schema_name")])
        .select_from(text("information_schema.schemata"))
        .where(text("schema_name = 'pr_occhab'"))
    )

    if DB.session.query(check_schema_query).scalar() and nb_data > 0:
        query = (
            "SELECT count(*) FROM pr_occhab.t_stations s, pr_occhab.t_habitats h WHERE s.id_station = h.id_station AND s.id_dataset in \
        ("
            + str(dataset_ids).strip("[]")
            + ")"
        )

        nb_habitat = DB.engine.execute(text(query)).first()[0]

    acquisition_framework["stats"] = {
        "nb_data": nb_data,
        "nb_taxons": nb_taxons,
        "nb_observations": nb_observations,
        "nb_habitats": nb_habitat,
    }

    if acquisition_framework:
        acquisition_framework[
            "nomenclature_territorial_level"
        ] = af.nomenclature_territorial_level.as_dict()
        acquisition_framework[
            "nomenclature_financing_type"
        ] = af.nomenclature_financing_type.as_dict()
        if acquisition_framework["acquisition_framework_start_date"]:
            start_date = dt.datetime.strptime(
                acquisition_framework["acquisition_framework_start_date"], "%Y-%m-%d"
            )
            acquisition_framework["acquisition_framework_start_date"] = start_date.strftime(
                "%d/%m/%Y"
            )
        if acquisition_framework["acquisition_framework_end_date"]:
            end_date = dt.datetime.strptime(
                acquisition_framework["acquisition_framework_end_date"], "%Y-%m-%d"
            )
            acquisition_framework["acquisition_framework_end_date"] = end_date.strftime("%d/%m/%Y")
        acquisition_framework["css"] = {
            "logo": "Logo_pdf.png",
            "bandeau": "Bandeau_pdf.png",
            "entite": "sinp",
        }
        acquisition_framework["pdf_title"] = current_app.config['METADATA']["AF_PDF_TITLE"]
        date = dt.datetime.now().strftime("%d/%m/%Y")
        acquisition_framework["footer"] = {
            "url": current_app.config["URL_APPLICATION"]
            + "/#/metadata/af-card/"
            + id_acquisition_framework,
            "date": date,
        }
        params = {"id_acquisition_frameworks": id_acquisition_framework}

    else:
        return (
            render_template(
                "error.html",
                error="Le dataset presente des erreurs",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )
    if af.initial_closing_date:
        acquisition_framework['initial_closing_date'] = af.initial_closing_date.strftime('%d-%m-%Y %H:%M')
        filename = "{}_{}_{}.pdf".format(
            id_acquisition_framework,
            acquisition_framework["acquisition_framework_name"][0:31].replace(" ", "_"),
            af.initial_closing_date.strftime("%d%m%Y_%H%M%S")
        )
        acquisition_framework["closed_title"] = current_app.config["METADATA"]["CLOSED_AF_TITLE"]

    else:
        filename = "{}_{}_{}.pdf".format(
            id_acquisition_framework,
            acquisition_framework["acquisition_framework_name"][0:31].replace(" ", "_"),
            dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
        )

    chart = create_taxa_chart(id_af=id_acquisition_framework)
    if chart:
        acquisition_framework["chart"] = chart

    if acquisition_framework["bbox"]:
        map = create_taxa_map(bbox=acquisition_framework["bbox"])
        if map:
            acquisition_framework["map"] = map

    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf(
        "acquisition_framework_template_pdf.html", acquisition_framework, filename
    )
    pdf_file_posix = Path(pdf_file)

    return send_from_directory(str(pdf_file_posix.parent), pdf_file_posix.name, as_attachment=True)


@routes.route("/acquisition_frameworks_metadata", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_acquisition_frameworks_metadata(info_role):
    """
    Get all AF with cruved filter
    Use for metadata module. 
    Add the cruved permission for each row

    .. :quickref: Metadata;

    """
    params = request.args
    afs = get_af_cruved(info_role, params, as_model=True)
    id_afs_user = TAcquisitionFramework.get_user_af(info_role, only_user=True)
    id_afs_org = TAcquisitionFramework.get_user_af(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]
    afs_dict = []
    for af in afs:
        af_dict = af.as_dict()
        af_dict["cruved"] = af.get_object_cruved(
            user_cruved=user_cruved,
            id_object=af.id_acquisition_framework,
            ids_object_user=id_afs_user,
            ids_object_organism=id_afs_org,
        )
        afs_dict.append(af_dict)
    return afs_dict


@routes.route("/acquisition_framework/<id_acquisition_framework>", methods=["GET"])
@json_resp
def get_acquisition_framework(id_acquisition_framework):
    """
    Get one AF

    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    af = DB.session.query(TAcquisitionFramework).get(id_acquisition_framework)

    if af:
        return af.as_dict(True)
    return None


@routes.route("/acquisition_framework_details/<id_acquisition_framework>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_acquisition_framework_details(info_role, id_acquisition_framework):
    """
    Get one AF

    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    af = DB.session.query(TAcquisitionFrameworkDetails).get(id_acquisition_framework)
    if not af:
        return None
    acquisition_framework = af.as_dict(True)

    datasets = acquisition_framework["datasets"] if "datasets" in acquisition_framework else []
    dataset_ids = [d["id_dataset"] for d in datasets]
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .first()[0]
    )
    if geojsonData:
        acquisition_framework["bbox"] = json.loads(geojsonData)
    nb_data = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset.in_(dataset_ids)).count()
    )
    nb_habitat = 0

    # Check if pr_occhab exist
    check_schema_query = exists(
        select([text("schema_name")])
        .select_from(text("information_schema.schemata"))
        .where(text("schema_name = 'pr_occhab'"))
    )

    if DB.session.query(check_schema_query).scalar() and nb_data > 0:
        query = (
            "SELECT count(*) FROM pr_occhab.t_stations s, pr_occhab.t_habitats h WHERE s.id_station = h.id_station AND s.id_dataset in \
        ("
            + str(dataset_ids).strip("[]")
            + ")"
        )

        nb_habitat = DB.engine.execute(text(query)).first()[0]

    acquisition_framework["stats"] = {
        "nb_data": nb_data,
        "nb_taxons": nb_taxons,
        "nb_observations": nb_observations,
        "nb_habitats": nb_habitat,
    }
    ids_afs_user = TAcquisitionFramework.get_user_af(info_role, only_user=True)
    ids_afs_org = TAcquisitionFramework.get_user_af(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]
    acquisition_framework["cruved"] = af.get_object_cruved(
        user_cruved=user_cruved,
        id_object=af.id_acquisition_framework,
        ids_object_user=ids_afs_user,
        ids_object_organism=ids_afs_org,
    )

    return acquisition_framework


@routes.route("/acquisition_framework/<int:af_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
@json_resp
def delete_acquisition_framework(info_role, af_id):
    """
    Delete an acquisition framework
    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" an acquisition_framework').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )

    if not is_af_deletable(af_id):
        raise GeonatureApiError(
            "La suppression du cadre d'acquisition n'est pas possible car des jeux de données y sont rattachées",
            500,
        )

    DB.session.query(CorAcquisitionFrameworkActor).filter(
        CorAcquisitionFrameworkActor.id_acquisition_framework == af_id
    ).delete()

    DB.session.query(CorAcquisitionFrameworkObjectif).filter(
        CorAcquisitionFrameworkObjectif.id_acquisition_framework == af_id
    ).delete()

    DB.session.query(CorAcquisitionFrameworkVoletSINP).filter(
        CorAcquisitionFrameworkVoletSINP.id_acquisition_framework == af_id
    ).delete()

    DB.session.query(TAcquisitionFramework).filter(
        TAcquisitionFramework.id_acquisition_framework == af_id
    ).delete()

    DB.session.commit()

    return "OK"


@routes.route("/acquisition_framework", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
@json_resp
def post_acquisition_framework(info_role):
    """
    Post an acquisition framework
    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(info_role.id_role, info_role.code_action),
            403,
        )
    data = dict(request.get_json())

    cor_af_actor = data.pop("cor_af_actor")
    cor_objectifs = data.pop("cor_objectifs")
    cor_volets_sinp = data.pop("cor_volets_sinp")

    af = TAcquisitionFramework(**data)

    for cor in cor_af_actor:
        # remove id_cda if None otherwise merge no working well
        if "id_cafa" in cor and cor["id_cafa"] is None:
            cor.pop("id_cafa")
        af.cor_af_actor.append(CorAcquisitionFrameworkActor(**cor))

    if cor_objectifs is not None:
        objectif_nom = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature.in_(cor_objectifs))
            .all()
        )
        for obj in objectif_nom:
            af.cor_objectifs.append(obj)

    if cor_volets_sinp is not None:
        volet_nom = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature.in_(cor_volets_sinp))
            .all()
        )
        for volet in volet_nom:
            af.cor_volets_sinp.append(volet)
    if af.id_acquisition_framework:
        DB.session.merge(af)
    else:
        af.id_digitizer = info_role.id_role
        DB.session.add(af)
    DB.session.commit()
    return af.as_dict()

def publish_acquisition_framework_mail(af, info_role):
    """
    Method for sending a mail during the publication process
    """

    # Parsing the AF XML from MTD to get the idTPS parameter
    af_xml = mtd_utils.get_acquisition_framework(str(af.unique_acquisition_framework_id).upper())
    xml_parser = ET.XMLParser(ns_clean=True, recover=True, encoding="utf-8")
    namespace = current_app.config["XML_NAMESPACE"]
    root = ET.fromstring(af_xml, parser=xml_parser)
    try:
        ca = root.find(".//" + namespace + "CadreAcquisition")
        ca_idtps = mtd_utils.get_tag_content(ca, "idTPS")
    except AttributeError:
        ca_idtps = ""

    # Generate the links for the AF's deposite certificate and framework download
    pdf_url = current_app.config["API_ENDPOINT"] + "/meta/acquisition_frameworks/export_pdf/" + str(af.id_acquisition_framework)

    # Mail subject
    mail_subject = "Dépôt du cadre d'acquisition " + str(af.unique_acquisition_framework_id).upper()
    mail_subject_base = current_app.config["METADATA"]["MAIL_SUBJECT_AF_CLOSED_BASE"]
    if mail_subject_base:
        mail_subject = mail_subject_base + " " + mail_subject
    if ca_idtps:
        mail_subject = mail_subject + " pour le dossier {}".format(ca_idtps)

    # Mail content
    mail_content = f"""Bonjour,<br>
    <br>
    Le cadre d'acquisition <i> "{af.acquisition_framework_name}" </i> dont l’identifiant est
    "{str(af.unique_acquisition_framework_id).upper()}" que vous nous avez transmis a été déposé"""
    

    mail_content_additions = current_app.config["METADATA"]["MAIL_CONTENT_AF_CLOSED_ADDITION"]
    mail_content_pdf = current_app.config['METADATA']["MAIL_CONTENT_AF_CLOSED_PDF"]
    mail_content_greetings = current_app.config['METADATA']["MAIL_CONTENT_AF_CLOSED_GREETINGS"]

    if ca_idtps:
        mail_content = mail_content + f"dans le cadre du dossier {ca_idtps}"

    if mail_content_additions:
        mail_content = mail_content + mail_content_additions
    else:
        mail_content = mail_content + ".<br>"

    if mail_content_pdf:
        mail_content = mail_content + mail_content_pdf.format(pdf_url) + pdf_url + "<br>"

    if mail_content_greetings:
        mail_content = mail_content + mail_content_greetings

    # Mail recipients : if the publisher is the the AF digitizer, we send a mail to both of them
    mail_recipients = set()
    cur_user = DB.session.query(User).get(info_role.id_role)
    if cur_user and cur_user.email:
        mail_recipients.add(cur_user.email)

    if af.id_digitizer:
        digitizer = DB.session.query(User).get(af.id_digitizer)
        if digitizer and digitizer.email:
            mail_recipients.add(digitizer.email)
    # Mail sent
    if mail_subject and mail_content and len(mail_recipients) > 0:
        mail.send_mail(list(mail_recipients), mail_subject, mail_content)


@routes.route("/acquisition_framework/publish/<int:af_id>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
@json_resp
def publish_acquisition_framework(info_role, af_id):
    """
    Publish an acquisition framework
    .. :quickref: Metadata;
    """

    # The AF must contain DS to be published
    datasets = TDatasets.query.filter_by(id_acquisition_framework=af_id).all()

    if not datasets:
        return (
            render_template(
                "error.html",
                error="Le cadre doit contenir des jeux de données",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

    # After publishing an AF, we set it as closed and all its DS as inactive
    for dataset in datasets:
        dataset.active=False

    # If the AF if closed for the first time, we set it an initial_closing_date as the actual time
    af = DB.session.query(TAcquisitionFramework).get(af_id)
    af.opened=False
    if (af.initial_closing_date is None):
        af.initial_closing_date=dt.datetime.now()

    # first commit before sending mail
    DB.session.commit()
    try:
        # We send a mail to notify the AF publication
        publish_acquisition_framework_mail(af, info_role)
    except Exception:
        return {
            'error': 'error while sending mail',
            'name': 'mailError'
            }, 500

    return af.as_dict()


def get_cd_nomenclature(id_type, cd_nomenclature):
    query = "SELECT ref_nomenclatures.get_id_nomenclature(:id_type, :cd_n)"
    result = DB.engine.execute(text(query), id_type=id_type, cd_n=cd_nomenclature).first()
    value = None
    if len(result) >= 1:
        value = result[0]
    return value


@routes.route("/aquisition_framework_mtd/<uuid_af>", methods=["POST"])
@json_resp
def post_acquisition_framework_mtd(uuid=None, id_user=None, id_organism=None):
    """ 
    Post an acquisition framwork from MTD web service in XML
    .. :quickref: Metadata;
    """
    return mtd_utils.post_acquisition_framework(
        uuid=uuid, id_user=id_user, id_organism=id_organism
    )


@routes.route("/dataset_mtd/<id_user>", methods=["POST"])
@routes.route("/dataset_mtd/<id_user>/<id_organism>", methods=["POST"])
@json_resp
def post_jdd_from_user_id(id_user=None, id_organism=None):
    """ 
    Post a jdd from the mtd XML
    .. :quickref: Metadata;
    """
    return mtd_utils.post_jdd_from_user(id_user=id_user, id_organism=id_organism)


@routes.route("/caSearch", methods=["GET"])
@json_resp
def ca_search():

    args = request.args
    return {"data": [d.as_dict(True) for d in filtered_af_query(args).all()]}


@routes.route("/jdSearch", methods=["GET"])
@json_resp
def jdd_search():

    args = request.args
    return {"data": [d.as_dict(True) for d in filtered_ds_query(args).all()]}

