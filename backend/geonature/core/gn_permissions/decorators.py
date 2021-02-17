"""
Decorators to protects routes with permissions
"""
import json

from flask import redirect, request, Response, current_app, g

from functools import wraps

from pypnusershub.db.tools import InsufficientRightsError

from geonature.core.gn_permissions.tools import (
    get_user_from_token_and_raise,
    UserCruved,
    PermissionsManager,
)


def check_cruved_scope(
    action,
    get_role=False,
    module_code=None,
    object_code=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Decorator to protect routes with SCOPE CRUVED
    The decorator first check if the user is conected and have a corect token (get_user_from_token_and_raise)
    and then return the max user SCOPE permission for the action in parameter
    The decorator manage herited CRUVED from user's group and parent module (GeoNature)
    

    Parameters
    ----------
        action(string): the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
        get_role(boolean): is the decorator should retour the VUsersPermissions object as kwargs
        module_code(string): the code of the module (gn_commons.t_modules) ('OCCTAX') for the requested permission
        object_code(string): the code of the object (gn_permissions.t_object) for the requested permission ('PERMISSIONS')
    
    Returns
    -------
    VUsersPermissions
        Return a VUsersPermissions as kwargs of the decorated function as 'info_role' parameter.
    """

    def _check_cruved_scope(fn):
        @wraps(fn)
        def __check_cruved_scope(*args, **kwargs):
            user = get_user_from_token_and_raise(
                request,
                action,
                redirect_on_expiration,
                redirect_on_invalid_token
            )
            user_with_highter_perm = None

            user_with_highter_perm = UserCruved(
                id_role=user["id_role"],
                code_filter_type="SCOPE",
                module_code=module_code,
                object_code=object_code,
            ).get_perm_for_one_action(action)
            if user_with_highter_perm:
                user_with_highter_perm = user_with_highter_perm[0]

            # if get_role = True : set info_role as kwargs
            if get_role:
                kwargs["info_role"] = user_with_highter_perm
            # if no perm or perm = 0 -> raise 403
            if user_with_highter_perm is None or (
                user_with_highter_perm is not None and user_with_highter_perm.value_filter == "0"
            ):
                if object_code:
                    message = f"""User {user["id_role"]} cannot "{action}" {object_code}"""
                else:
                    message = f"""User {user["id_role"]}" cannot "{action}" in {module_code}"""
                raise InsufficientRightsError(message, 403)
            g.user = user_with_highter_perm
            return fn(*args, **kwargs)

        return __check_cruved_scope

    return _check_cruved_scope


def check_permissions(
    module_code,
    action_code,
    object_code=None
):
    """Décorateur permettant de protéger les routes des web services.

    Ce décorateur vérifie les permissions de l'utilisateur connecté vis à vis 
    du filtre d'appartenance (=SCOPE) sur un module donnée, pour une action 
    donnée et éventuellement un objet du module.

    L'utilisateur doit posséder un token correct (transmis via un cookie)
    dans le cas contraire des exceptions sont levées. Le mécanisme de gestion
    des exceptions globales de Flask se charge de les transformer en réponse 
    au format JSON.

    Ce décorateur fournit les informations sur l'utilisateur et ses 
    permisisons via le paramètre 'permissions' transmis à la fonction décorée.

    L'héritage par les groupes et les modules est appliqué afin d'obtnir
    les permissisons "applaties" correspondantes.
    
    Parameters
    ----------
    module_code : str
        Le code du module (Ex. 'OCCTAX'). Voir la table gn_commons.t_modules
        pour les valeurs possibles.
    action_code : {'C', 'R', 'U', 'V', 'E', 'D'}
        Le code de l'action correspondant au type de web service 
        Voir la table gn_commons.t_actions pour les valeurs possibles.
    object_code : str, optional
        Le code de l'objet (~= sous-module) si nécessaire. Dans le cas
        d'un web service ne traitant que de ce type d'objet. Voir la table 
        gn_permissions.t_objects pour les valeurs possibles.
    
    Raises
    ------
    InsufficientRightsError
        Exception levée si l'utilisateur n'a pas les permissions d'accès
        nécessaires.

    Returns
    -------
    auth: VUsersPermissions
        Retourne les infos liées à la permission d'accès de l'utilisateur.

    permissions : list<dict>
        Liste de dictionnaires contenant les différents filtres rassemblés
        et des infos sur chaque permission (module, action, objet...).

    """

    def _check_permissions(fn):
        @wraps(fn)
        def __check_permissions(*args, **kwargs):
            user = get_user_from_token_and_raise(request)

            perms_manager = PermissionsManager(
                id_role=user["id_role"],
                module_code=module_code,
                action_code=action_code,
                object_code=object_code
            )

            if perms_manager.check_access():
                old_access_permission = perms_manager.get_access_permission()
                permissions = perms_manager.get_all_permissions_with_all_filters()

                # Set infos into kwargs
                kwargs["auth"] = old_access_permission
                kwargs["permissions"] = permissions
                
                # Store data globally within the current context
                g.user = old_access_permission # Retro-compatibility
                g.auth = old_access_permission
                g.permissions = permissions

            return fn(*args, **kwargs)
        return __check_permissions
    return _check_permissions
