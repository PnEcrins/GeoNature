import copy
import datetime
import logging
import uuid

from flask import current_app, request, render_template, url_for, redirect
from sqlalchemy import  or_, exc
from sqlalchemy.orm import aliased



from pypnusershub.db.models import User
from utils_flask_sqla.response import json_resp ,json_resp_accept_empty_list

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.models import (
    BibFiltersType,
    CorRoleActionFilterModuleObject,
    TActions,
    TObjects,
    TRequests,
    RequestStates,
)
from geonature.utils.env import DB
from geonature.core.users.models import BibOrganismes
from geonature.core.gn_commons.models import TModules

from geonature.core.gn_permissions.tools import (
     split_value_filter, unduplicate_values,
    format_geographic_filter_values, format_taxonomic_filter_values,
    build_value_filter_from_list, prepare_input, prepare_output, format_role_name,
    format_end_access_date
)
from geonature.utils.utilsmails import send_mail



from ..routes import routes

log = logging.getLogger()

@routes.route("/requests", methods=["GET"])
@permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="ACCESS_REQUESTS")
@json_resp_accept_empty_list
def get_permissions_requests():
    """
    Retourne toutes les demandes de permissions avec des info sur 
    l'utilisateur ayant fait la demande.

    .. :quickref: Permissions;
    
    Params:
    :param state: filtre permetant de récupérer seulement les requêtes
    acceptées (accepted), refusées (refused), refusées et acceptées 
    (processed) ou en attentes (pending).
    :type state: 'accepted', 'refused', 'processed', 'pending'

    :returns: un tableau de dictionnaire contenant les infos des demandes
    de permissions.
    """
    # Get params
    params = request.args.to_dict()
    
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Check "state" values validity
    state_accepted_values = ["accepted", "refused", "processed", "pending"]
    if "state" in params and params["state"] not in state_accepted_values:
        msg = (
            f"Valeur « {params['state']} » du paramère « state » inconnue. "
            + f"Valeurs acceptées : {', '.join(state_accepted_values)}"
        )
        response = {
            "message": msg,
            "status": "warning"
        }
        return response, 400

    # Get requests
    UserAsker = aliased(User)
    UserValidator = aliased(User)
    query = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
            .outerjoin(UserValidator, UserValidator.id_role == TRequests.processed_by)
            .order_by(TRequests.meta_create_date)
    )
    
    if "state" in params:
        if params["state"] == "processed":
            query = query.filter(
                or_(
                    TRequests.processed_state == RequestStates.accepted, 
                    TRequests.processed_state == RequestStates.refused, 
                )
            )
        else:
            query = query.filter(TRequests.processed_state == RequestStates(params["state"]))
    results = query.all()

    requests = []
    for result in results:
        access_request = formatAccessRequest(*result)
        requests.append(access_request)
        
    return prepare_output(requests)

@routes.route("/access_requests", methods=["POST"])
@permissions.check_cruved_scope(action="R", get_role=True, module_code="GEONATURE")
@json_resp
def post_access_request(info_role):
    """
    Post an access request.

    .. :quickref: Permissions;
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Transform received data
    data = dict(request.get_json())
    data["additional_data"] = data.get("additional_data")
    end_access_date = format_end_access_date(data["end_access_date"])
    geographic_filter = build_value_filter_from_list(unduplicate_values(data["areas"]))
    taxonomic_filter = build_value_filter_from_list(unduplicate_values(data["taxa"]))
    user_id = info_role.id_role

    # Prepare TRequests
    trequest = TRequests(**{
        "id_role": user_id,
        "end_date": end_access_date,
        "processed_state": RequestStates.pending,
        "additional_data": data.get("additional_data"),
        "geographic_filter": geographic_filter,
        "taxonomic_filter": taxonomic_filter,
        "sensitive_access": data["sensitive_access"],
    })

    # Write request_data in database
    DB.session.add(trequest)
    DB.session.commit()

    # Inform about new access request by email
    try:
        send_email_after_access_request(
            data=data,
            user_id=user_id,
            request_token=trequest.token,
        )
    except Exception as exp:
        log.error(exp)
        response = {
            "message": f"Erreur lors de l'envoie de l'email aux administrateurs : {exp}.",
            "code": "AdminSendEmailError",
            "status": "error"
        }
        raise
        return response, 500

    response = {
        "message": "Succès de l'ajout de la demande d'accès.",
        "status": "success"
    }
    return response





def send_email_after_access_request(data, user_id, request_token):
    recipients = current_app.config["PERMISSION_MANAGEMENT"]["VALIDATOR_EMAIL"]
    app_name = current_app.config["appName"]
    subject = f"Demande de permissions d'accès {app_name}"
    msg_html = render_request_approval_tpl(user_id, data, request_token)
    send_mail(recipients, subject, msg_html)


def render_request_approval_tpl(user_id, data, request_token):
    template = "email_admin_request_approval.html"
    approval_url = url_for(
        "gn_permissions.manage_access_request_by_link",
        token=request_token,
        action="approve",
        _external=True,
    )
    refusal_url = url_for(
        "gn_permissions.manage_access_request_by_link",
        token=request_token,
        action="refuse",
        _external=True,
    )
    return render_template(
        template,
        app_name=current_app.config["appName"],
        end_date=format_end_access_date(data["end_access_date"], date_format="%x"),
        user = DB.session.query(User).get(user_id).as_dict(),
        geographic_filter_values=format_geographic_filter_values(data["areas"]),
        taxonomic_filter_values=format_taxonomic_filter_values(data["taxa"]),
        sensitive_permission=data["sensitive_access"],
        additional_fields=format_additional_fields(data["additional_data"]),
        approval_url=approval_url,
        refusal_url=refusal_url,
        app_url = current_app.config["URL_APPLICATION"] + "/#/permissions/requests/pending",
    )


@routes.route("/access_requests/<token>/<action>", methods=["GET"])
# Do not check CRUVED because this web service is called outside an app
def manage_access_request_by_link(token, action):
    """
        Approuve/Refuse une demande de permissions d'accès.
        ATTENTION : ce webservice modifie une demande d'accès via la
        méthode HTTP GET.
        Dénormalisation permettant de lancer ces actions via un lien
        envoyé par email.
    """
    # Check if permission management is enable on this GeoNature instance
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Check "action" URL parameter values
    accepted_actions = ["approve", "refuse"]
    if action not in accepted_actions:
        accepted_values_msg = f"Valeurs acceptées : {', '.join(accepted_actions)}."
        response = {
            "message": f"Type d'action '{action}' inconnu. {accepted_values_msg}",
            "status": "error"
        }
        return response, 400

    # Check access request token was defined
    if token is None:
        response = {
            "message": "Token de demande de permission non défini.",
            "status": "error"
        }
        return response, 404

    # Check access request token exists in DB
    request = get_request_by_token(token)
    if not request:
        response = {
            "message": "Token de demande de permission introuvable.",
            "status": "error"
        }
        return response, 404

    # Check if access request was not already approved or refused
    if request["processed_date"]:
        date = request["processed_date"]
        status = get_status(request["processed_state"])
        msg = f"Demande de permission déjà {status} le {date}. Utiliser l'interface d'administration.",
        response = {"message": msg, "status": "error"}
        return response, 400

    # Update access request
    request["processed_state"] = (
        RequestStates.accepted if action == "approve" else RequestStates.refused
    )
    request["processed_date"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    result = (DB.session
        .query(TRequests)
        .filter(TRequests.token == token)
        .update({
            TRequests.processed_state: request["processed_state"],
            TRequests.processed_date: request["processed_date"],
        })
    )

    # Add asked permissions to authorized permissions table if request approve
    if action == "approve":
        add_permission(request)

    # Commit DB session
    DB.session.commit()

    # Send email to user
    try:
        send_email_after_managing_request(request)
    except Exception as exp:
        response = {
            "message": f"Erreur lors de l'envoie de l'email à l'utilisateur : {exp}.",
            "code": "UserSendEmailError",
            "status": "error"
        }
        return response, 500
    

    # Redirect to GeoNature app home page
    return redirect(current_app.config["URL_APPLICATION"], code=302)


def get_request_by_token(token):
    try:
        data = (DB
            .session.query(TRequests)
            .filter(TRequests.token == token)
            .one()
            .as_dict()
        )
    except exc.NoResultFound:
        return False
    return data

def get_status(state):
    if state == RequestStates.accepted :
        return "acceptée"
    if state == RequestStates.pending :
        return "mise en attente"
    if state ==RequestStates.refused :
        return "refusée"


def add_permission(request):
    # Build default permissions for access request
    default_permissions = get_access_request_default_permissions(request)
    
    # Add additional data to each permission
    for perm in default_permissions:
        perm["id_request"] = request["id_request"]
        perm["gathering"] = uuid.uuid4()

    # Get new permission with filters added
    new_permissions = get_permissions_with_filters(request, default_permissions)

    # TODO: check if this permission with all this specific filters already exist

    # Persists permissions in database
    for permission in new_permissions:
        if not permission.is_already_exist():
            DB.session.add(permission)


def get_access_request_default_permissions(request):
    default_permissions = [
        {
            "module_code": "SYNTHESE", 
            "action_code": "R", 
            "object_code": "PRIVATE_OBSERVATION",
        },
        {
            "module_code": "SYNTHESE", 
            "action_code": "E", 
            "object_code": "PRIVATE_OBSERVATION",
        },
    ]
    
    if (DB.session.query(TModules).filter(TModules.module_code == "VALIDATION").first()):
         default_permissions.append({
            "module_code": "VALIDATION", 
            "action_code": "R", 
            "object_code": "PRIVATE_OBSERVATION",
        })

    # Add new permissions for sensitive observations
    if (request["sensitive_access"] is True):
        default_sensitive_permissions = copy.deepcopy(default_permissions)
        for permission in default_sensitive_permissions:
            permission["object_code"] = "SENSITIVE_OBSERVATION" 
        default_permissions.extend(default_sensitive_permissions)
    
    return default_permissions



def get_permissions_with_filters(request, default_permissions):
    permissions_with_filters = []

    # Add mandatory PROPERTY (=SCOPE) filter
    permissions = get_property_permissions(default_permissions)
    for perm in permissions:
        perm.id_role = request["id_role"]
        perm.end_date = request["end_date"]
        perm.value_filter = "3"# À tous le monde
        permissions_with_filters.append(perm)

    # Add Geo and Taxo filters to each permission
    if (request["geographic_filter"]):
        areas = split_value_filter(request["geographic_filter"])
        permissions = get_geographic_permissions(default_permissions)
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(areas)
            permissions_with_filters.append(perm)

    if (request["taxonomic_filter"]):
        taxa = split_value_filter(request["taxonomic_filter"])
        permissions = get_taxonomic_permissions(default_permissions)
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(taxa)
            permissions_with_filters.append(perm)

    # Precision filter
    permissions = get_precision_permissions(default_permissions)
    for perm in permissions:
        perm.id_role = request["id_role"]
        perm.end_date = request["end_date"]
        perm.value_filter = "exact"
        permissions_with_filters.append(perm)
    
    return permissions_with_filters



def get_geographic_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "GEOGRAPHIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_taxonomic_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "TAXONOMIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_precision_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "PRECISION"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions

def get_property_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "SCOPE" # TODO: rename to PROPERTY...
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_fresh_permission(filter_type_code, module_code, action_code, object_code, gathering=None, id_request=None):
    permission_module = DB.session.query(TModules).filter(TModules.module_code == module_code).one()
    permission_action = DB.session.query(TActions).filter(TActions.code_action == action_code).one()
    permission_object = DB.session.query(TObjects).filter(TObjects.code_object == object_code).one()
    permission_filter_type = (DB.session
        .query(BibFiltersType)
        .filter(BibFiltersType.code_filter_type == filter_type_code)
        .one()
    )
    
    # Prepare fresh permission
    permission = CorRoleActionFilterModuleObject(
        id_module=permission_module.id_module,
        id_action=permission_action.id_action,
        id_object=permission_object.id_object,
        id_filter_type=permission_filter_type.id_filter_type,
    )
    
    # Add gathering and id_request only if defined
    if gathering:
        permission.gathering = gathering
    if id_request:
        permission.id_request = id_request

    return permission



def send_email_after_managing_request(request):
    user = DB.session.query(User).get(request["id_role"]).as_dict()
    recipient = user["email"]
    app_name = current_app.config["appName"]
    if request["processed_state"] == RequestStates.accepted:
        subject = f"Acceptation de demande de permissions d'accès {app_name}"
        msg_html = render_accepted_request_tpl(user, request)
    elif request["processed_state"] == RequestStates.pending:
        subject = f"Mise en attente de la demande de permissions d'accès {app_name}"
        msg_html = render_pending_request_tpl(user, request)
    else:
        subject = f"Refus de demande de permissions d'accès {app_name}"
        msg_html = render_refused_request_tpl(user, request)
    if recipient:
        send_mail(recipient, subject, msg_html)
    else:
        log.debug(f"User {request['id_role']} with no email. Email not send.")


def render_accepted_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_accepted.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
        app_url=current_app.config["URL_APPLICATION"],
    )


def render_pending_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_pending.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
    )


def render_refused_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_refused.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
        refusal_reason=request["refusal_reason"],
    )


def get_validators():
    validators = current_app.config["PERMISSION_MANAGEMENT"]["VALIDATOR_EMAIL"]
    if isinstance(validators, list):
       validators = ", ".join(validators)
    return validators.strip()





@routes.route("/requests/<token>", methods=["GET"])
@permissions.check_cruved_scope(action="R", module_code="ADMIN", object_code="ACCESS_REQUESTS")
def get_permissions_requests_by_token(token):
    """
    Retourne le détail d'une demande.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos d'une demande de permission.
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    UserAsker = aliased(User)
    UserValidator = aliased(User)
    query = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
            .outerjoin(UserValidator, UserValidator.id_role == TRequests.processed_by)
            .filter(TRequests.token == token)
    )
    results = query.first()

    if not results:
        response = {
            "message": f"Token de demande introuvable : {token} .",
            "status": "error"
        }
        return response, 404
    
    response = formatAccessRequest(*results)
    response = prepare_output(response)
    return response, 200


@routes.route("/requests/<token>", methods=["PATCH"])
@permissions.check_cruved_scope(
    action="U", 
    get_role=True, 
    module_code="ADMIN", 
    object_code="ACCESS_REQUESTS",
)
@json_resp
def patch_permissions_request_by_token(info_role, token):
    """
    Modifier partiellement une demande d'accès.

    Utilisé pour accepter ou refuser une demande en modifiant son état.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la demande modifiée.
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Transform received data
    role = DB.session.query(User).get(info_role.id_role).as_dict()
    data = prepare_input(dict(request.get_json()))
    refusal_reason = data.get("refusal_reason", None)
    if RequestStates(data.get("processed_state")) != RequestStates.refused:
        refusal_reason = None

    # Load TRequest
    trequest = DB.session.query(TRequests).filter(TRequests.token == token).first()
    if not trequest:
        response = {
            "message": f"Token de demande introuvable : {token} .",
            "status": "error"
        }
        return response, 404

    # Prepare TRequests
    trequest.processed_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    trequest.processed_by = role.get("id_role")
    trequest.processed_state = RequestStates(data.get("processed_state"))
    trequest.refusal_reason = refusal_reason

    # Update TRequest
    DB.session.merge(trequest)

    # Update Permissions according to access request state
    if trequest.processed_state == RequestStates.accepted:
        add_permission(trequest.as_dict())
    else:
        remove_permission_by_request(trequest.as_dict())

    # Commit update in DB
    DB.session.commit()
    DB.session.flush()

    # Send email to user
    try:
        send_email_after_managing_request(trequest.as_dict())
    except Exception as exp:
        response = {
            "message": f"Erreur lors de l'envoie de l'email à l'utilisateur : {exp}.",
            "code": "UserSendEmailError",
            "status": "error"
        }
        return response, 500

    # Get updated TRequests
    UserAsker = aliased(User)
    UserValidator = aliased(User)
    results = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
            .outerjoin(UserValidator, UserValidator.id_role == TRequests.processed_by)
            .filter(TRequests.token == token)
            .first()
    )

    # Prepare response
    access_request = formatAccessRequest(*results)
    response = prepare_output(access_request)
    return response, 200


def remove_permission_by_request(request):
    # Remove permissions in database
    try:
        query = (
            DB.session
            .query(CorRoleActionFilterModuleObject)
            .filter(CorRoleActionFilterModuleObject.id_request == request['id_request'])
        )
        results = query.all()
        for result in results:
            DB.session.delete(result)
    except exc.NoResultFound:
        log.info("No permissions found. No permissions to remove.")
    except Exception as exp:
        log.error("Permissions deletion error: %s", exp)


def formatAccessRequest(request, asker, asker_organism, validator):
    taxa = split_value_filter(request.taxonomic_filter)
    areas = split_value_filter(request.geographic_filter)
    sensitive = request.sensitive_access
    access_request = {
        "token": request.token,
        "user_name": format_role_name(asker),
        "user_email": (asker.email if asker.email else "?"),
        "organism_name": (asker_organism.nom_organisme if asker_organism else "-"),
        "geographic_filters": areas,
        "geographic_filters_labels": format_geographic_filter_values(areas),
        "taxonomic_filters": taxa,
        "taxonomic_filters_labels": format_taxonomic_filter_values(taxa),
        "sensitive_access": sensitive,
        "end_access_date": format_end_access_date_from_string(request.end_date),
        "processed_state": request.processed_state,
        "processed_date": request.processed_date,
        "processed_by": request.processed_by,
        "refusal_reason": request.refusal_reason,
        "additional_data": format_additional_fields(request.additional_data),
        "meta_create_date": request.meta_create_date.strftime("%Y-%m-%d %H:%M:%S"),
        "meta_update_date": request.meta_update_date.strftime("%Y-%m-%d %H:%M:%S"),
    }
    if request.processed_date:
        access_request["processed_date"] = request.processed_date.strftime("%Y-%m-%d %H:%M:%S")
    if request.processed_by:
        access_request["processed_by"] = f"{validator.prenom_role} {validator.nom_role}"
    return access_request

def format_end_access_date_from_string(date):
    return None if not date else date.strftime("%Y-%m-%d")


# TODO: Delete this route if not used !
@routes.route("/requests/<token>", methods=["PUT"])
@permissions.check_cruved_scope(
    action="U", 
    get_role=True, 
    module_code="ADMIN", 
    object_code="ACCESS_REQUESTS",
)
@json_resp
def update_permissions_requests_by_token(token):
    """
    Modifier une demande d'accès.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la demande modifiée.
    """
    response = {
            "message": f"Update permission request is not implemented yet !",
            "status": "error"
        }
    return response, 501



def format_additional_fields(data):
    if data is None:
        return []

    attr_infos = build_dynamic_request_form_infos()
    attr_keys = attr_infos.keys()
    formated_fields = []
    for key, value in (data or {}).items():
        if key in attr_keys:
            cfg = {
                "key": key,
                "label": attr_infos.get(key)["label"],
                "value": value,
            }
            for attr_infos_key, attr_infos_value in attr_infos.get(key).items():
                cfg[attr_infos_key] = attr_infos_value
            formated_fields.append(cfg)
    return formated_fields


def build_dynamic_request_form_infos():
    attr_infos = {}
    form_cfg = current_app.config["PERMISSION_MANAGEMENT"]["REQUEST_FORM"]
    for cfg in form_cfg:
        if all(key in cfg for key in ("type_widget", "attribut_name", "attribut_label")):
            attr_infos[cfg["attribut_name"]] = {
                "type": cfg["type_widget"],
                "label": cfg["attribut_label"],
            }
        if "icon" in cfg:
            attr_infos[cfg["attribut_name"]]["icon"] = cfg["icon"]
        if "icon_set" in cfg:
            attr_infos[cfg["attribut_name"]]["icon_set"] = cfg["icon_set"]

    return attr_infos

