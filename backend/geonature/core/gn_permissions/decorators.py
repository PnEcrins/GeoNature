'''
Decorators to protects routes with permissions
'''
import json

from flask import redirect, request, Response, current_app, g, Response

from functools import wraps

from geonature.core.gn_permissions.tools import get_user_permissions, get_user_from_token_and_raise, get_user_from_JWToken_and_raise

def check_cruved_scope(
    action,
    get_role=False,
    module_code=None,
    object_code=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None,
):
    """
    Decorator to protect routes with SCOPE CRUVED
    The decorator first check if the user is conected and have a corect token (get_user_from_token_and_raise)
    and then return the max user SCOPE permission for the action in parameter
    The decorator manage herited CRUVED from user's group and parent module (GeoNature)
    Return a VUsersPermissions as kwargs of the decorated function as 'info_role' parameter

    Parameters:
        action(string): the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
        get_role(boolean): is the decorator should retour the VUsersPermissions object as kwargs
        module_code(string): the code of the module (gn_commons.t_modules) ('OCCTAX') for the requested permission
        object_code(string): the code of the object (gn_permissions.t_object) for the requested permission ('PERMISSIONS')
        redirect_on_expiration(string): url where we redirect on token expiration
        redirect_on_invalid_token(string): url where we redirect on token invalid token
    """
    def _check_cruved_scope(fn):
        @wraps(fn)
        def __check_cruved_scope(*args, **kwargs):
            user = get_user_from_token_and_raise(
                request,
                action,
                redirect_on_expiration,
                redirect_on_invalid_token,
            )
            # If user not a dict: its a token issue
            # return the appropriate Response from get_user_from_token_and_raise
            if not isinstance(user, dict):
                return user
            user_with_highter_perm = None
            if get_role:
                user_permissions = get_user_permissions(
                    user,
                    action,
                    'SCOPE',
                    module_code,
                    object_code
                )
                # if object_code no heritage
                if object_code:
                    user_with_highter_perm = get_max_perm(user_permissions)
                else:
                    # else
                    # loop on user permissions
                    # return the module permission if exist
                    # otherwise return GEONATURE permission
                    module_permissions = []
                    geonature_permission = []
                    # user_permissions is a array of at least 1 permission
                    # get the user from the first element of the array
                    for user_permission in user_permissions:
                        if user_permission.module_code == module_code:
                            module_permissions.append(user_permission)
                        else:
                            geonature_permission.append(user_permission)
                    # take the max of the different permissions
                    if len(module_permissions) == 0:
                        user_with_highter_perm = get_max_perm(geonature_permission)
                    else:
                        user_with_highter_perm = get_max_perm(module_permissions)
            
                kwargs['info_role'] = user_with_highter_perm

            g.user = user_with_highter_perm
            return fn(*args, **kwargs)
        return __check_cruved_scope
    return _check_cruved_scope



def get_max_perm(perm_list):
    '''
        Return the max filter_code from a list of VUsersPermissions instance
        get_user_permissions return a list of VUsersPermissions from its group or himself
    '''
    user_with_highter_perm = perm_list[0]
    max_code = user_with_highter_perm.value_filter
    i = 1
    while i < len(perm_list):
        if int(perm_list[i].value_filter) >= int(max_code):
            max_code = perm_list[i].value_filter
            user_with_highter_perm = perm_list[i]
        i = i + 1
    return user_with_highter_perm

#gestion JWT
#
#
#
#
#


def check_cruved_scope_JWT(
    action,
    get_role=False,
    module_code=None,
    object_code=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None,
):
    """
    Decorator to protect routes with SCOPE CRUVED
    The decorator first check if the user is conected and have a corect token (get_user_from_token_and_raise)
    and then return the max user SCOPE permission for the action in parameter
    The decorator manage herited CRUVED from user's group and parent module (GeoNature)
    Return a VUsersPermissions as kwargs of the decorated function as 'info_role' parameter

    Parameters:
        action(string): the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
        get_role(boolean): is the decorator should retour the VUsersPermissions object as kwargs
        module_code(string): the code of the module (gn_commons.t_modules) ('OCCTAX') for the requested permission
        object_code(string): the code of the object (gn_permissions.t_object) for the requested permission ('PERMISSIONS')
        redirect_on_expiration(string): url where we redirect on token expiration
        redirect_on_invalid_token(string): url where we redirect on token invalid token
    """
    def _check_cruved_scope_JWT(fn):
        @wraps(fn)
        def __check_cruved_scope_JWT(*args, **kwargs):
            user = get_user_from_JWToken_and_raise(
                request,
                action,
                redirect_on_expiration,
                redirect_on_invalid_token,
            )
            # If user not a dict: its a token issue
            # return the appropriate Response from get_user_from_JWToken_and_raise
            if not isinstance(user, dict):
                return user
            user_with_highter_perm = None
            if get_role:
                user_permissions = get_user_permissions(
                    user,
                    action,
                    'SCOPE',
                    module_code,
                    object_code
                )
                # if object_code no heritage
                if object_code:
                    user_with_highter_perm = get_max_perm(user_permissions)
                else:
                    # else
                    # loop on user permissions
                    # return the module permission if exist
                    # otherwise return GEONATURE permission
                    module_permissions = []
                    geonature_permission = []
                    # user_permissions is a array of at least 1 permission
                    # get the user from the first element of the array
                    for user_permission in user_permissions:
                        if user_permission.module_code == module_code:
                            module_permissions.append(user_permission)
                        else:
                            geonature_permission.append(user_permission)
                    # take the max of the different permissions
                    if len(module_permissions) == 0:
                        user_with_highter_perm = get_max_perm(geonature_permission)
                    else:
                        user_with_highter_perm = get_max_perm(module_permissions)
            
                kwargs['info_role'] = user_with_highter_perm

            g.user = user_with_highter_perm
            return fn(*args, **kwargs)
        return __check_cruved_scope_JWT
    return _check_cruved_scope_JWT

