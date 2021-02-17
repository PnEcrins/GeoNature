"""
Routes of the gn_permissions blueprint
"""

import copy
import locale
import logging

from flask import (
    Blueprint,
    request,
    Response,
    session,
    jsonify
)
from utils_flask_sqla.response import json_resp

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions import decorators as permissions

from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_permissions.repositories import PermissionRepository

from geonature.utils.env import DB


# TODO : see how to define locale globaly => bug with python 3.7?
print(f"Current locale: {locale.getlocale(locale.LC_TIME)}")
locale.setlocale(locale.LC_TIME, "fr_FR.UTF-8")

log = logging.getLogger(__name__)

routes = Blueprint("gn_permissions", __name__, template_folder="templates")

from .access_request.routes import *
from .permissions.routes import *

@routes.route("/cruved", methods=["GET"])
@permissions.check_cruved_scope(action="R", get_role=True, module_code="GEONATURE")
@json_resp
def get_cruved(info_role):
    """
    Get the cruved for a user

    .. :quickref: Permissions;

    Params:
    :param user: the user who ask the route, auto kwargs via @check_cruved_scope
    :type user: User
    :param module_code: the code of the requested module, or multiples codes comma separated - as querystring
    :type module_code: str

    :returns: dict of the CRUVED
    """
    params = request.args.to_dict()

    # get modules
    q = DB.session.query(TModules)
    if "module_code" in params:
        codes = params["module_code"].split(',')
        q = q.filter(TModules.module_code.in_(codes))
    modules = q.all()

    # for each modules get its cruved
    # then get its related object and their cruved
    modules_with_cruved = {}
    for mod in modules:
        mod_as_dict = mod.as_dict()
        # get mod objects
        module_objects = PermissionRepository().get_module_objects(mod_as_dict["id_module"])

        module_cruved, herited = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code=mod_as_dict["module_code"]
        )
        mod_as_dict["cruved"] = module_cruved

        module_objects_as_dict = {}
        # get cruved for each object
        for _object in module_objects:
            object_as_dict = _object.as_dict()
            object_cruved, herited = cruved_scope_for_user_in_module(
                id_role=info_role.id_role,
                module_code=mod_as_dict["module_code"],
                object_code=_object.code_object,
            )
            object_as_dict["cruved"] = object_cruved
            module_objects_as_dict[object_as_dict["code_object"]] = object_as_dict

            mod_as_dict["module_objects"] = module_objects_as_dict

        modules_with_cruved[mod_as_dict["module_code"]] = mod_as_dict

    return modules_with_cruved


@routes.route("/logout_cruved", methods=["GET"])
def logout():
    """
    Route to logout with cruved

    .. :quickref: Permissions;

    To avoid multiples server call, we store the cruved in the session
    when the user logout we need clear the session to get the new cruved session
    """
    copy_session_key = copy.copy(session)
    for key in copy_session_key:
        session.pop(key)
    return Response("Logout", 200)




@routes.route("/modules", methods=["GET"])
@permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="PERMISSIONS")
def get_all_modules():
    """
    Retourne tous les modules.

    .. :quickref: Permissions;

    Params:
    :param codes: filtre permetant de récupérer seulement les modules
    pour un ou plusieurs codes données séparés par des virgules.

    :returns: un tableau de dictionnaire contenant les infos des modules.
    """
    # Get params
    params = request.args.to_dict()

    query = DB.session.query(TModules)
    if "codes" in params:
        codes = params["codes"].split(',')
        query = query.filter(TModules.module_code.in_(codes))

    modules = []
    for mdl in query.all():
        modules.append(mdl.as_dict())

    output = prepare_output(modules, remove_in_key="module")
    return jsonify(output), 200




