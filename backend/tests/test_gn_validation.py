import json
import pytest
from flask import url_for, session, Response, request
from .bootstrap_test import app, releve_data, post_json, json_of_response, get_token


@pytest.mark.usefixtures("client_class")
class TestValidation:
    def test_get_data(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("validation.get_synthese_data"))

        assert response.status_code == 200
        data = json_of_response(response)
        mandatory_columns = [
            "cd_nomenclature_validation_status",
            "date_min",
            "id_synthese",
            "nom_vern_or_lb_nom",
            "observers",
            "validation_auto",
            "validation_date",
            "cd_nom",
            "unique_id_sinp",
            "meta_update_date",
            "id_nomenclature_valid_status",
            "entity_source_pk_value",
            "mnemonique",
            "label_default",
            "nom_vern",
            "lb_nom"
        ]
        response_key = data["data"]["features"][0]["properties"].keys()
        for c in mandatory_columns:
            assert c in response_key
