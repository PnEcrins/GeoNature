from flask import current_app
from werkzeug.datastructures import ImmutableDict

import pytest

from flask import url_for, current_app

from .bootstrap_test import app, post_json, json_of_response, get_token


@pytest.mark.usefixtures("client_class")
class TestSynthese:
    def test_list_sources(self):
        response = self.client.get(url_for("gn_synthese.get_sources"))

        assert response.status_code == 200

    def test_get_defaut_nomenclature(self):
        response = self.client.get(url_for("gn_synthese.getDefaultsNomenclatures"))
        assert response.status_code == 200

    def test_get_synthese_data(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)
        # test on synonymy and taxref attrs
        query_string = {
            "cd_ref": 209902,
            "taxhub_attribut_102": "eau",
            "taxonomy_group2_inpn": "Insectes",
            "taxonomy_id_hab": 3,
        }
        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string=query_string
        )
        data = json_of_response(response)
        assert len(data["data"]["features"]) == 1
        # clés obligatoire pour le fonctionnement du front
        assert "cd_nom" in data["data"]["features"][0]["properties"]
        assert "id" in data["data"]["features"][0]["properties"]
        assert "url_source" in data["data"]["features"][0]["properties"]
        assert "entity_source_pk_value" in data["data"]["features"][0]["properties"]
        assert data["data"]["features"][0]["properties"]["cd_nom"] == 713776

        assert response.status_code == 200

        # test geometry filters
        key_municipality = "area_" + str(current_app.config["BDD"]["id_area_type_municipality"])
        query_string = {
            "geoIntersection": """
                POLYGON ((5.580368041992188 43.42100882994726, 5.580368041992188 45.30580259943578, 8.12919616699219 45.30580259943578, 8.12919616699219 43.42100882994726, 5.580368041992188 43.42100882994726))
                """,
            key_municipality: 28290,
        }
        response = self.client.get(url_for("gn_synthese.get_observations_for_web"), query_string=query_string)
        data = json_of_response(response)
        assert len(data["data"]) >= 2

        # test geometry filter with circle radius
        query_string = {
            "geoIntersection": "POINT (6.121788024902345 45.06794388950998)",
            "radius": "83883.94104436478",
        }

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"), query_string=query_string)
        data = json_of_response(response)
        assert len(data["data"]) >= 2

        # test organisms and multiple same arg in query string

        response = self.client.get("/synthese/for_web?id_organism=1&id_organism=2")
        data = json_of_response(response)
        assert len(data["data"]) >= 2

    def test_get_synthese_data_cruved(self):
        # test cruved
        token = get_token(self.client, login="partenaire", password="admin")
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = json_of_response(response)
        assert len(data["data"]["features"]) == 0
        assert response.status_code == 200

    def test_filter_cor_observers(self):
        """
            Test avec un cruved R2 qui join sur cor_synthese_observers
        """
        token = get_token(self.client, login="test_cruved_r2", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = json_of_response(response)

        # le résultat doit être supérieur ou égal à 2
        assert len(data["data"]["features"]) != 0
        # le requete doit etre OK marlgré la geom NULL
        assert response.status_code == 200

    def test_export(self):
        # Set config param because "shapefile" is not set by default
        current_app.config["SYNTHESE"]["EXPORT_FORMAT"] = ["csv", "geojson", "shapefile", "gpkg"]
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)

        # csv
        response = post_json(
            self.client,
            url_for("gn_synthese.export_observations_web"),
            json_dict=[1, 2, 3],
            query_string={"export_format": "csv"},
        )

        assert response.status_code == 200

        response = post_json(
            self.client,
            url_for("gn_synthese.export_observations_web"),
            json_dict=[1, 2, 3],
            query_string={"export_format": "geojson"},
        )
        assert response.status_code == 200

        response = post_json(
            self.client,
            url_for("gn_synthese.export_observations_web"),
            json_dict=[1, 2, 3],
            query_string={"export_format": "shapefile"},
        )
        assert response.status_code == 200

        response = post_json(
            self.client,
            url_for("gn_synthese.export_observations_web"),
            json_dict=[1, 2, 3],
            query_string={"export_format": "gpkg"},
        )
        assert response.status_code == 200

    def test_export_status(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.post(url_for("gn_synthese.export_status"))

        assert response.status_code == 200

    def test_export_metadata(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_synthese.export_metadata"))

        assert response.status_code == 200

    def test_general_stat(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_synthese.general_stats"))

        assert response.status_code == 200

    def test_get_one_synthese_reccord(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_synthese.get_one_synthese", id_synthese=2))

        assert response.status_code == 200

    def test_color_taxon(self):
        response = self.client.get(url_for("gn_synthese.get_color_taxon"))
        data = json_of_response(response)
        one_line = data[0]
        mandatory_columns = ["cd_nom", "id_area", "color", "nb_obs", "last_date"]
        for attr in mandatory_columns:
            assert attr in one_line
        assert response.status_code == 200
