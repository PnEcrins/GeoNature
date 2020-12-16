import json

import pytest

from flask import url_for, current_app
from cookies import Cookie

from geonature import create_app
from geonature.utils.env import load_config, get_config_file_path

# TODO: fixture pour mettre des données test dans la base a chaque test


@pytest.fixture
def app():
    config_path = get_config_file_path()
    config = load_config(config_path)
    app = create_app(config)
    app.config["TESTING"] = True
    app.config["WTF_CSRF_ENABLED"] = False
    return app


def post_json(client, url, json_dict, query_string=None):
    """Send dictionary json_dict as a json to the specified url """
    return client.post(
        url,
        data=json.dumps(json_dict),
        content_type="application/json",
        query_string=query_string,
    )


def json_of_response(response):
    """Decode json from response"""
    return json.loads(response.data.decode("utf8"))


mimetype = "application/json"
headers = {"Content-Type": mimetype, "Accept": mimetype}


def get_token(client, login="admin", password="admin"):
    data = {
        "login": login,
        "password": password,
        "id_application": current_app.config["ID_APPLICATION_GEONATURE"],
    }
    response = client.post(url_for("auth.login"), data=json.dumps(data), headers=headers)
    try:
        token = Cookie.from_string(response.headers["Set-Cookie"])
        return token.value
    except Exception:
        raise Exception("Invalid login {}, {}".format(login, password))


@pytest.fixture()
def releve_data(client):

    response = client.get(url_for("pr_occtax.getDefaultNomenclatures"))
    default_nomenclatures = json_of_response(response)
    data = {
        "geometry": {"type": "Point", "coordinates": [3.428936004638672, 44.276611357355904],},
        "properties": {
            "id_dataset": 1,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "hour_min": None,
            "hour_max": None,
            "altitude_min": None,
            "altitude_max": None,
            "meta_device_entry": "web",
            "comment": None,
            "id_nomenclature_obs_technique": default_nomenclatures["TECHNIQUE_OBS"],
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": default_nomenclatures["TYP_GRP"],
            "t_occurrences_occtax": [
                {
                    "id_nomenclature_naturalness": default_nomenclatures["NATURALITE"],
                    "id_nomenclature_obs_technique": default_nomenclatures["METH_OBS"],
                    "digital_proof": None,
                    "cor_counting_occtax": [
                        {
                            "count_min": 1,
                            "validation_comment": None,
                            "id_nomenclature_life_stage": 2,
                            "count_max": 1,
                            "id_nomenclature_sex": default_nomenclatures["SEXE"],
                            "id_validator": None,
                            "id_nomenclature_type_count": default_nomenclatures["TYP_DENBR"],
                            "id_nomenclature_obj_count": default_nomenclatures["OBJ_DENBR"],
                        }
                    ],
                    "nom_cite": "Ablette = Alburnus alburnus (Linnaeus, 1758)",
                    "meta_v_taxref": "Taxref V9.0",
                    "id_nomenclature_blurring": default_nomenclatures["DEE_FLOU"],
                    "id_nomenclature_bio_status": default_nomenclatures["STATUT_BIO"],
                    "id_nomenclature_bio_condition": default_nomenclatures["ETA_BIO"],
                    "comment": None,
                    "id_nomenclature_observation_status": default_nomenclatures["STATUT_OBS"],
                    "id_nomenclature_determination_method": default_nomenclatures["METH_DETERMIN"],
                    "non_digital_proof": None,
                    "id_nomenclature_exist_proof": default_nomenclatures["PREUVE_EXIST"],
                    "cd_nom": 67111,
                    "sample_number_proof": None,
                    "determiner": None,
                }
            ],
        },
    }

    return data
