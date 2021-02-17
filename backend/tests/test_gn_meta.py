import pytest

from flask import url_for, current_app
from sqlalchemy.sql import func

from .bootstrap_test import app, post_json, json_of_response, get_token

from geonature.core.users import routes as users


@pytest.mark.usefixtures("client_class")
class TestGnMeta:
    def test_list_datasets(self):
        """
        Api to get all datasets
        """
        # token = get_token(self.client)
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_meta.get_datasets"))

        # check fields for mobile
        data = json_of_response(response)
        ds = data["data"][0]
        mandatory_attr = [
            "id_dataset",
            "dataset_name",
            "dataset_desc",
            "active",
            "meta_create_date",
            "modules",
        ]
        for attr in mandatory_attr:
            assert attr in ds
        module = ds["modules"][0]
        assert "module_path" in module
        assert response.status_code == 200

    def test_one_dataset(self):
        """
        API to get one dataset from id_dataset
        """
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=1))
        assert response.status_code == 200

    def test_dataset_cruved_2(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 2
        """
        token = get_token(self.client, login="agent", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_meta.get_datasets"))
        dataset_list = json_of_response(response)
        assert response.status_code == 200 and len(dataset_list["data"]) == 2

    def test_dataset_cruved_1(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 1
        """
        token = get_token(self.client, login="partenaire", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_meta.get_datasets"))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200
            and len(dataset_list["data"]) == 1
            and dataset_list["data"][0]["id_dataset"] == 3
        )

    # def test_mtd_interraction(self):
    #     from geonature.core.gn_meta.mtd_utils import (
    #         post_jdd_from_user,
    #         get_jdd_by_user_id,
    #         parse_jdd_xml,
    #     )

    #     """
    #     Test du web service MTD
    #     A partir d'un utilisateur renvoyé par le CAS
    #     on insert l'utilisateur 'demo.geonature' et son organisme s'il existe pas
    #     puis on poste les CA et JDD renvoyé à le WS MTD
    #     """
    #     user = {
    #         "id_role": 10991,
    #         "identifiant": "test.mtd",
    #         "nom_role": "test_mtd",
    #         "prenom_role": "test_mtd",
    #         "id_organisme": 104,
    #     }

    #     organism = {"id_organisme": 104, "nom_organisme": "test"}
    #     resp = users.insert_organism(organism)
    #     assert resp.status_code == 200

    #     resp = users.insert_role(user)
    #     # id_role 10 = id_socle 1 in test
    #     users.insert_in_cor_role(10, user["id_role"])
    #     assert resp.status_code == 200

    #     jdds = post_jdd_from_user(id_user=10991, id_organism=104)
    #     assert len(jdds) >= 1

    def test_post_and_update_dataset(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        one_dataset = {
            "active": True,
            "bbox_east": None,
            "bbox_north": None,
            "bbox_south": None,
            "bbox_west": None,
            "cor_dataset_actor": [
                {
                    "id_cda": None,
                    "id_nomenclature_actor_role": 359,
                    "id_organism": 0,
                    "id_role": None,
                }
            ],
            "dataset_desc": "a",
            "dataset_name": "a",
            "dataset_shortname": "a",
            "id_acquisition_framework": 1,
            "id_dataset": 5,
            "id_nomenclature_collecting_method": 405,
            "id_nomenclature_data_type": 323,
            "id_nomenclature_dataset_objectif": 408,
            "id_nomenclature_resource_type": 321,
            "id_nomenclature_source_status": 73,
            "keywords": None,
            "marine_domain": False,
            "terrestrial_domain": True,
            "validable": True,
            "modules": [1],
        }
        response = post_json(self.client, url_for("gn_meta.post_dataset"), json_dict=one_dataset)
        dataset = json_of_response(response)
        assert len(dataset["modules"]) == 1
        assert response.status_code == 200

        # edition
        # fetch dataset
        response = self.client.get(
            url_for("gn_meta.get_dataset", id_dataset=dataset["id_dataset"])
        )
        fetched_dataset = json_of_response(response)
        # suppression du module associé
        fetched_dataset["modules"] = []

        for cor in fetched_dataset["cor_dataset_actor"]:
            cor.pop("organism")
            cor.pop("nomenclature_actor_role")
        # ajout d'un acteur
        fetched_dataset["cor_dataset_actor"].append(
            {"id_cda": None, "id_nomenclature_actor_role": 359, "id_organism": 1, "id_role": None,}
        )
        # modification du nom
        fetched_dataset["dataset_name"] = "new_name"
        response = post_json(
            self.client, url_for("gn_meta.post_dataset"), json_dict=fetched_dataset
        )
        updated_dataset = json_of_response(response)
        assert "modules" not in updated_dataset
        assert len(updated_dataset["cor_dataset_actor"]) == 2
        assert updated_dataset["dataset_name"] == "new_name"
        assert response.status_code == 200

    def test_post_ca(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        one_ca = {
            "acquisition_framework_desc": "ttt",
            "acquisition_framework_end_date": None,
            "acquisition_framework_name": "tt",
            "acquisition_framework_parent_id": None,
            "acquisition_framework_start_date": "2019-07-03",
            "cor_af_actor": [
                {
                    "id_cafa": None,
                    "id_nomenclature_actor_role": 359,
                    "id_organism": 0,
                    "id_role": None,
                }
            ],
            "cor_objectifs": [516],
            "cor_volets_sinp": [],
            "ecologic_or_geologic_target": "aaaa",
            "id_acquisition_framework": None,
            "id_nomenclature_financing_type": 383,
            "id_nomenclature_territorial_level": 355,
            "is_parent": False,
            "keywords": "ttt",
            "target_description": None,
            "territory_desc": "aaa",
        }

        response = post_json(
            self.client, url_for("gn_meta.post_acquisition_framework"), json_dict=one_ca
        )
        assert response.status_code == 200
