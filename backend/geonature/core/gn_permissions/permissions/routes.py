import json
import uuid

import logging
from flask import current_app, request
from sqlalchemy import (and_, distinct, func, or_, exc)

from pypnusershub.db.models import User, AppRole
from utils_flask_sqla.response import json_resp

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.models import (
    BibFiltersType,
    BibFiltersValues,
    CorModuleActionObjectFilter,
    CorRoleActionFilterModuleObject,
    TActions,
    TObjects,
)
from geonature.utils.env import DB
from geonature.core.users.models import BibOrganismes, CorRole
from geonature.core.gn_commons.models import TModules


from geonature.core.gn_permissions.tools import (
    PermissionsManager, UserPermissions, split_value_filter, unduplicate_values,
    format_geographic_filter_values, get_areas_infos, format_taxonomic_filter_values,
    get_taxons_infos, build_value_filter_from_list, prepare_input, prepare_output, format_role_name
)
from geonature.core.gn_permissions.repositories import PermissionRepository

from ..routes import routes

log = logging.getLogger()

# TODO: Delete if not used !
# @routes.route("/actions", methods=["GET"])
# @permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="PERMISSIONS")
# @json_resp
# def get_all_actions():
#     """
#     Retourne toutes les actions.

#     .. :quickref: Permissions;

#     :returns: un tableau de dictionnaire contenant les infos des actions.
#     """
#     q = DB.session.query(TActions)
#     actions = []
#     for act in q.all():
#         actions.append(act.as_dict())

#     output = prepare_output(actions, remove_in_key="action")
#     return output


# # TODO: Delete if not used !
# @routes.route("/filters", methods=["GET"])
# @permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="PERMISSIONS")
# @json_resp
# def get_all_filters():
#     """
#     Retourne tous les types de filtres.

#     .. :quickref: Permissions;

#     :returns: un tableau de dictionnaire contenant les infos des filtres.
#     """
#     q = DB.session.query(BibFiltersType)
#     filters = []
#     for fit in q.all():
#         filters.append(fit.as_dict())
    
#     output = prepare_output(filters, remove_in_key="filter_type")
#     return output

@routes.route("/filters-values", methods=["GET"])
@permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_all_filters_values():
    """
    Retourne toutes les valeurs des différents types de filtres.

    .. :quickref: Permissions;

    :returns: un dictionnaire dont les attributs correspondent aux codes 
    des types de filtres et les valeurs à des tableaux des valeurs des
    filtres correspondantes.
    """
    q = (
        DB.session
        .query(BibFiltersValues, BibFiltersType.code_filter_type)
        .join(
            BibFiltersType, 
            BibFiltersType.id_filter_type == BibFiltersValues.id_filter_type
        )
        .order_by(
            BibFiltersValues.id_filter_type,
            BibFiltersValues.value_or_field,
        )
    )

    filters_values = {}
    for item in q.all():
        (bib_filter_value, code) = item
        
        if code not in filters_values.keys():
            filters_values[code] = []
        
        # Prepare filter value
        fvalue = bib_filter_value.as_dict()
        fvalue["filter_type_code"] = code
        fvalue["filter_type_id"] = fvalue["id_filter_type"]
        del fvalue["id_filter_type"]
        if (fvalue["predefined"]):
            fvalue["value"] = fvalue["value_or_field"]

        filters_values[code].append(fvalue)
    
    return prepare_output(filters_values, remove_in_key="filter_value")



@routes.route("/objects", methods=["GET"])
@permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_all_objects():
    """
    Retourne toutes les objets.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos des objets.
    """
    q = DB.session.query(TObjects)
    objects = []
    for obj in q.all():
        objects.append(obj.as_dict())

    return prepare_output(objects, remove_in_key="object")


@routes.route("/roles", methods=["GET"])
@permissions.check_cruved_scope("R", get_role=True, module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_permissions_for_all_roles(info_role):
    """
    Retourne tous les rôles avec leurs permissions.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos du rôle et 
    ses permissions.
    """
    # Get params
    params = request.args.to_dict()

    # Subquery to get only implemented permissions (= link to cor_module_action_object_filter)
    gatherings_for_roles = (
        DB.session.query(
            CorRoleActionFilterModuleObject.id_role, 
            CorRoleActionFilterModuleObject.gathering
        )
        .distinct(CorRoleActionFilterModuleObject.gathering)
        .join(
            CorModuleActionObjectFilter, 
            (CorModuleActionObjectFilter.id_module == CorRoleActionFilterModuleObject.id_module)
            &
            (CorModuleActionObjectFilter.id_action == CorRoleActionFilterModuleObject.id_action)
            &
            (CorModuleActionObjectFilter.id_object == CorRoleActionFilterModuleObject.id_object)
            &
            (CorModuleActionObjectFilter.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type)
        )
        .subquery()
    )

    # Get roles with permissions
    # TODO: use AppRole instead of User and BibOrganismes
    query = (
        DB.session.query(
                User, 
                BibOrganismes, 
                func.count(distinct(gatherings_for_roles.c.gathering))
            )
            .join(AppRole, AppRole.id_role == User.id_role)
            .outerjoin(gatherings_for_roles, gatherings_for_roles.c.id_role == User.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == User.id_organisme)
            .filter(AppRole.id_application == current_app.config["ID_APPLICATION_GEONATURE"])
            .group_by(
                User.id_role,
                BibOrganismes.id_organisme
            )
            .order_by(User.groupe.desc(), User.prenom_role, User.nom_role)
    )

    # Filter with user authentified permissions
    if info_role.value_filter == "2":
        query = query.filter(BibOrganismes.id_organisme == info_role.id_organisme)
    elif info_role.value_filter == "1":
        query = query.filter(User.id_role == info_role.id_role)
    
    results = query.all()
    
    roles = []
    for result in results:
        (user, organism, permissions_number) = result
        role = format_role(user, organism)
        role["permissions_nbr"] = permissions_number
        roles.append(role)
    
    # Send response
    output = prepare_output(roles)
    return output
    

def format_role(user, organism):
    return {
        "id": user.id_role,
        "user_name": format_role_name(user),
        "organism_name": (organism.nom_organisme if organism else None),
        "type": "GROUP" if user.groupe == True else "USER",
    }



@routes.route("/roles/<int:id_role>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_permissions_by_role_id(id_role):
    """
    Retourne un rôle avec ses permissions.

    .. :quickref: Permissions;
    
    Params:
    :param with-inheritance: booléen indiquant si oui (=true) 
    ou non (=false) les permissions héritées doivent être retournée.
    
    :returns: un dictionnaire avec les infos du rôle et ses permissions.
    """
    # Get request parameters
    params = request.args.to_dict()
    user_permissions = UserPermissions(id_role=id_role)
    # Get role infos
    query = (
        DB.session
        .query(User, BibOrganismes)
        .outerjoin(BibOrganismes, BibOrganismes.id_organisme == User.id_organisme)
        .filter(User.id_role == id_role)
    )
    result = query.first()

    # Prepare role infos
    if not result:
        response = {
            "message": f"Id de rôle introuvable : {id_role} .",
            "status": "error"
        }
        return response, 404
    (user, organism) = result
    role = format_role(user, organism)

    # Get, prepare and add groups of an user (for permissions inheritance)
    role["groups"] = []
    for role_group in get_user_groups(id_role):
        role["groups"].append({
            "id": role_group.id_role, 
            "group_name": format_role_name(role_group), 
        })

    # Prepare permissions

    # Get permissions uninherited
    results = PermissionRepository().get_all_personal_permissions(id_role=id_role)
    for result in results:
        (
            id_role, label, code, module, action_code, object_code,
            end_date, gathering, filter_type, filter_value
        ) = result
        user_permissions.append_permission(
            label=label,
            code=code,
            module_code=module,
            action_code=action_code,
            object_code=object_code,
            end_date=end_date,
            gathering=gathering,
            filter_type=filter_type,
            filter_value=filter_value,
            is_inherited=False
        )
    
    # return user_permissions.permissions

    # Recover inherited permissions if necessary
    if ("with-inheritance" in params and is_true(params["with-inheritance"])):
        inheritance = []
        # Get all modules
        modules = DB.session.query(TModules).order_by(TModules.module_order).all()
        for module in modules:
            # Initialize variables
            module_code = module.module_code

            # Get max_perm for each action code in CRUVED for this module
            for action_code in PermissionsManager.get_actions_codes():
                perm_infos = PermissionsManager(
                    id_role=id_role,
                    module_code=module_code,
                    action_code=action_code,
                    without_outdated=False
                ).get_full_access_permission()
                if perm_infos is None:
                    continue
                else:
                    max_perm = perm_infos["higher_perm"]
                    is_inherited_by_module = perm_infos["is_inherited"]
                    inherited_by = perm_infos["inherited_by"]
                    other_filters_permissions = perm_infos["other_filters"]
                prepared_inherited_by = prepare_inherited_by(
                    role, max_perm, inherited_by, is_inherited_by_module
                )
                is_inherited = (
                    prepared_inherited_by["by_group"] or prepared_inherited_by["by_module"]
                )
                for perm in [max_perm, *other_filters_permissions]:
                    inheritance.append({
                        "module_code": module_code,
                        "action_code": action_code,
                        "object_code": perm.code_object,
                        "gathering": str(perm.gathering),
                        "label": perm.permission_label, 
                        "code": perm.permission_code, 
                        "end_date": perm.end_date, 
                        "filter_type": perm.code_filter_type, 
                        "filter_value": perm.value_filter,
                        "is_inherited": is_inherited,
                        "inherited_by": prepared_inherited_by,
                    })

            # For this module get its related objects
            module_objects = PermissionRepository().get_module_objects(module.id_module)
            
            # For each object get herited permissions for each CRUVED action and filter SCOPE
            for mo in module_objects:
                # Initialize variables
                object_code = mo.code_object

                # Get max_perm for each action code in CRUVED for this object in this module
                # max_perm : permission with max value filter for property filter type (="SCOPE").
                for action_code in PermissionsManager.get_actions_codes():
                    perm_infos = PermissionsManager(
                        id_role=id_role,
                        module_code=module_code,
                        action_code=action_code,
                        object_code=object_code,
                        without_outdated=True
                    ).get_full_access_permission()
                    if perm_infos is None:
                        continue
                    else:
                        max_perm = perm_infos["higher_perm"]
                        is_inherited_by_module = perm_infos["is_inherited"]
                        inherited_by = perm_infos["inherited_by"]
                        other_filters_permissions = perm_infos["other_filters"]
                    
                    prepared_inherited_by = prepare_inherited_by(
                        role, max_perm, inherited_by, is_inherited_by_module
                    )
                    is_inherited = (
                        prepared_inherited_by["by_group"] or prepared_inherited_by["by_module"]
                    )

                    for perm in [max_perm, *other_filters_permissions]:
                        inheritance.append({
                            "module_code": module_code,
                            "action_code": action_code,
                            "object_code": object_code,
                            "gathering": str(perm.gathering),
                            "label": perm.permission_label, 
                            "code": perm.permission_code, 
                            "end_date": perm.end_date, 
                            "filter_type": perm.code_filter_type, 
                            "filter_value": perm.value_filter,
                            "is_inherited": is_inherited,
                            "inherited_by": prepared_inherited_by,
                        })

        # Append inherited permissions
        for perm in inheritance:
            #perm_detail = gatherings[perm["gathering"]]
            if perm["label"] is None and perm["code"] is None:
                log.warn(
                    "Permission not implemented detected (see cor_module_action_object_filter table). "+
                    "Please remove this useless permission from cor_role_action_filter_module_object:"+
                    f" {perm}"
                )
            elif perm["is_inherited"] and perm["module_code"] != "GEONATURE":
                # WARNING : only add an inherited permission by an object if a 
                # corresponding entry was found in cor_module_action_object_filter table
                object_permission_infos = PermissionRepository().get_permission_available(
                    module_code=perm["module_code"], 
                    action_code=perm["action_code"], 
                    object_code=perm["object_code"], 
                    filter_type_code=perm["filter_type"],
                )
                if object_permission_infos:
                    # If it's an inherited permission for a specific object, label and code must be updated
                    perm["label"] = object_permission_infos["label"]
                    perm["code"] = object_permission_infos["code"]
                    
                    user_permissions.append_permission(**perm)
            else:
                user_permissions.append_permission(**perm)

    # Add permissions list to role (remove "gathering from output")
    for module_name in user_permissions.permissions:
        user_permissions.permissions[module_name] = list(user_permissions.permissions[module_name].values())
    role["permissions"] = user_permissions.permissions

    # Send response
    return prepare_output(role)


def get_user_groups(id_role):
    """
    Fournit tous les groupes d'un utilisateur.
    Parameters:
        id_role (int): identifiant de l'utilisateur.
    Return:
        Array<User>
    """
    return (
        DB.session.query(User)
            .join(CorRole, User.id_role == CorRole.id_role_groupe)
            .filter(CorRole.id_role_utilisateur == id_role)
            .all()
    )


def prepare_inherited_by(role, permission, inherited_by, is_inherited_by_module):
    group_name = (permission.group_name if permission.group_name else None)
    itself = (True if (role["type"] == "GROUP" and role["user_name"] == group_name) else False)
    by_group = (True if (group_name and not itself) else False)
    group_name = (group_name if by_group else None)
    return {
        "by_module": is_inherited_by_module,
        "module_code": (inherited_by[0] if inherited_by else None),
        "object_code": (inherited_by[1] if inherited_by else None),
        "by_group": by_group,
        "group_name": group_name,
    }




def is_true(param):
    return True if (param.lower() in ["true", "1"]) else False
    


@routes.route("/<gathering>", methods=["DELETE"])
@permissions.check_cruved_scope("D", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def delete_permission(gathering):
    """
    Supprime une permissions par son hash de groupement.

    Notes : il est plus simple de supprimer une permission et tous les 
    filtres qui lui son associé à l'aide du hash de regroupement plutôt 
    que par une liste d'identifiant.

    .. :quickref: Permissions;

    :returns: code http 204 et un corps de réponse vide si tout est OK.
    """
    # Delete permission
    try:
        PermissionRepository().delete_permission_by_gathering(gathering)
        DB.session.commit()
        DB.session.flush()
    except exc.NoResultFound:
        log.info(f"No permissions found for gathering {gathering}")
        response = {
            "message": f"Aucune permission trouvé pour le groupement : {gathering} .",
            "status": "error"
        }
        return response, 404
    except Exception as exp:
        log.error("Error %s", exp)
        response = {
            "message": f"Une exception est survenue durant la suppression : {exp} .",
            "status": "error"
        }
        return response, 500
    
    return "", 204




@routes.route("/availables/actions-objects", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_availables_actions_objects():
    """
    Retourne tous les ensembles action-object disponibles.

    .. :quickref: Permissions;

    Params:
    :param module: filtre permetant de récupérer seulement les ensembles
    action-object disponibles pour un module donné.

    :returns: un tableau des ensembles action-object possibles.
    """
    # Extract params
    params = request.args.to_dict()

    # Build query
    query = (DB.session
        .query(
            CorModuleActionObjectFilter.label,
            TActions.code_action,
            TObjects.code_object,
            TModules.module_code,
        )
        .distinct()
        .join(
            TModules, 
            TModules.id_module == CorModuleActionObjectFilter.id_module
        )
        .join(
            TActions, 
            TActions.id_action == CorModuleActionObjectFilter.id_action
        )
        .join(
            TObjects, 
            TObjects.id_object == CorModuleActionObjectFilter.id_object
        )
        .order_by(
            CorModuleActionObjectFilter.id_action,
            CorModuleActionObjectFilter.id_object,
        )
    )
    
    # Manage parameters
    if "module" in params:
        query = query.filter(TModules.module_code == params["module"])

    # Build output
    availables = []
    for result in query.all():
        (label, action_code, object_code, module_code) = result
        
        availables.append({
            "module_code": module_code,
            "action_code": action_code,
            "object_code": object_code,
            "label": label,
        })
    
    return prepare_output(availables)

@routes.route("/availables/actions-objects-filters", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def get_availables_actions_objects_filters():
    """
    Retourne tous les ensembles action-object-filter disponibles.

    .. :quickref: Permissions;

    Params:
    :param module: filtre permetant de récupérer seulement les permissions
        disponibles pour un module donné.
    :param action: filtre permetant de récupérer seulement les permissions
        disponibles pour une action (CRUVED) donnée.
    :param object: filtre permetant de récupérer seulement les permissions
        disponibles pour un objet donné.

    :returns: un dictionnaire contenant en clé le code des modules et en
    valeur un tableau des ensembles action-object-filter possibles.
    Si le paramètres "module" est utilisé, retourne seulement le tableau
    des ensembles action-object-filter possibles
    """
    # Extract params
    params = request.args.to_dict()

    # Build query
    query = (DB.session
        .query(
            TActions.code_action,
            TObjects.code_object,
            BibFiltersType.code_filter_type,
            CorModuleActionObjectFilter.code,
            CorModuleActionObjectFilter.description,
            TModules.module_code,
        )
        .distinct()
        .join(
            TModules, 
            TModules.id_module == CorModuleActionObjectFilter.id_module
        )
        .join(
            TActions, 
            TActions.id_action == CorModuleActionObjectFilter.id_action
        )
        .join(
            TObjects, 
            TObjects.id_object == CorModuleActionObjectFilter.id_object
        )
        .join(
            BibFiltersType, 
            BibFiltersType.id_filter_type == CorModuleActionObjectFilter.id_filter_type
        )
        .order_by(
            CorModuleActionObjectFilter.id_action,
            CorModuleActionObjectFilter.id_object,
            CorModuleActionObjectFilter.id_filter_type,
        )
    )
    
    # Manage parameters
    if "module" in params:
        query = query.filter(TModules.module_code == params["module"])
    if "action" in params:
        query = query.filter(TActions.code_action == params["action"])
    if "object" in params:
        query = query.filter(TObjects.code_object == params["object"])

    # Build output
    availables = []
    for result in query.all():
        (action_code, object_code, filter_type_code, code, description, module_code) = result
        
        availables.append({
            "module_code": module_code,
            "action_code": action_code,
            "object_code": object_code,
            "filter_type_code": filter_type_code,
            "code": code,
            "description": description,
        })
    
    return prepare_output(availables)


@routes.route("", methods=["POST"])
@permissions.check_cruved_scope("C", get_role=True, module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def post_permission(info_role):
    """
    Ajouter une permission.

    .. :quickref: Permissions;
    """
    # Transform received data
    gathering = uuid.uuid4()
    data = prepare_input(dict(request.get_json()))
    exp = None
    
    try:
        permission_repo = PermissionRepository()
        # Create permssion
        permission_repo.create_permission(gathering, data)
        
        # Write in database
        DB.session.commit()
        DB.session.flush()
    except exc.SQLAlchemyError as _exp:
        log.error("Error SQLAlchemy %s", _exp)
        exp = _exp
    except Exception as _exp:
        log.error("Error %s", _exp)
        exp = _exp
    
    # Return response
    if exp:
        response = {
            "message": f"Une erreur est survenue durant l'ajout de la permission : {exp} .",
            "status": "error"
        }
        code = 500
    else:
        response = {
            "message": "Succès de l'ajout de la permission.",
            "status": "success"
        }
        code = 200
    
    return response, code


@routes.route("<gathering>", methods=["PUT"])
@permissions.check_cruved_scope("U", get_role=True, module_code="ADMIN", object_code="PERMISSIONS")
@json_resp
def update_permission(info_role, gathering):
    """
    Modifier une permission.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la permission modifiée.
    """
    # Transform received data
    
    role = DB.session.query(User).get(info_role.id_role).as_dict()
    data = prepare_input(dict(request.get_json()))
    exp = None

    try:
        # TODO: get values from fields in database (id_request) not in request data. 
        # Then insert them inside data.
        # Delete permission before create new one
        gathering = uuid.uuid4()
        permsission_repo = PermissionRepository()
        permsission_repo.delete_permission_by_gathering(gathering)
        permsission_repo.create_permission(gathering, data)

        # Write in database
        DB.session.commit()
        DB.session.flush()
    except exc.SQLAlchemyError as exp:
        log.error("Error SQLAlchemy %s", exp)
    except Exception as exp:
        log.error("Error %s", exp)
    
    # Return response
    if exp:
        response = {
            "message": f"Une erreur est survenue durant la mise à jour de la permission : {exp} .",
            "status": "error"
        }
        code = 500
    else:
        response = {
            "message": "Succès de la modification de la permission.",
            "status": "success"
        }
        code = 200
    
    return response, code
