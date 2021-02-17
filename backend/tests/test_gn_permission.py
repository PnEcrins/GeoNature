import pytest


from flask import url_for, current_app, request, Response
from werkzeug.exceptions import Unauthorized

from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError,
    UnreadableAccessRightsError,
)
from .bootstrap_test import app, json_of_response, get_token
from pypnusershub.db.tools import InsufficientRightsError
from geonature.core.gn_permissions.models import (
    VUsersPermissions,
    CorRoleActionFilterModuleObject,
    BibFiltersType,
    TObjects,
)
from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB


from geonature.core.gn_permissions.tools import (
    user_from_token,
    get_user_from_token_and_raise,
    cruved_scope_for_user_in_module,
    UserCruved,
)

# from geonature.core.gn_permissions.decorators import get_max_perm
from geonature.core.gn_permissions.models import VUsersPermissions


@pytest.mark.usefixtures("client_class")
class TestGnPermissionsTools:
    """ Test of gn_permissions tools functions"""

    def test_user_from_token(self):
        with pytest.raises(UnreadableAccessRightsError):
            user = user_from_token("lapojfdzpijdspiv")

        token = get_token(self.client)
        user = user_from_token(token)
        assert isinstance(user, dict)
        assert user["nom_role"] == "Administrateur"

    def test_user_from_token_and_raise_fail(self):
        # no cookie
        with pytest.raises(Unauthorized, match="No token"):
            user = get_user_from_token_and_raise(request)
        
        # set a fake cookie
        self.client
        self.client.set_cookie("/", "token", "fake token")
        # fake request to set cookie
        response = self.client.get(
            url_for("gn_permissions.get_all_modules", id_filter_type=4),
            headers={'Accept': 'application/json'},
        )
        with pytest.raises(Unauthorized) as exc_info:
            user = get_user_from_token_and_raise(request)
        assert 401 == exc_info.value.response.status_code
        assert "Token corrupted." in str(exc_info.value.response.get_data())

    def test_get_user_permissions(self):
        # set a real cookie
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        # fake request to set cookie
        response = self.client.get(
            url_for("gn_permissions.get_all_modules")
        )
        user = get_user_from_token_and_raise(request)
        assert isinstance(user, dict)

    def test_get_user_permissions(self):
        """
        Test get_user_permissions
        """
        user_ok = {"id_role": 1, "nom_role": "Administrateur"}
        perms, is_herited, herited_object, other_filters_perm = UserCruved(
            id_role=user_ok["id_role"], code_filter_type="SCOPE", module_code="GEONATURE"
        ).get_perm_for_one_action("C")

        assert isinstance(perms, VUsersPermissions)
        assert perms.value_filter == "3"

        # with module code
        perms = perms, is_herited, herited_object, other_filters_perm = UserCruved(
            id_role=user_ok["id_role"], 
            code_filter_type="SCOPE", 
            module_code="ADMIN"
        ).get_perm_for_one_action("C")
        assert perms.value_filter == "3"

        # with code_object -> heritage
        perms = perms, is_herited, herited_object, other_filters_perms = UserCruved(
            id_role=user_ok["id_role"],
            code_filter_type="SCOPE",
            module_code="GEONATURE",
            object_code="PERMISSIONS",
        ).get_perm_for_one_action("C")
        assert isinstance(perms, VUsersPermissions)
        assert perms.value_filter == "3"

    def test_cruved_scope_for_user_in_module(self):
        # get cruved for geonature
        cruved, herited = cruved_scope_for_user_in_module(id_role=9, module_code="GEONATURE")
        assert herited == False
        assert cruved == {"C": "3", "R": "3", "U": "3", "V": "3", "E": "3", "D": "3"}
