import logging, json

from flask import current_app, redirect, Response

from itsdangerous import (TimedJSONWebSignatureSerializer as Serializer,
                          SignatureExpired, BadSignature)

import sqlalchemy as sa
from sqlalchemy.sql.expression import func


from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError, 
    UnreadableAccessRightsError
) 

from geonature.core.gn_permissions.models import VUsersPermissions, TFilters
from geonature.utils.env import DB

import jwt

log = logging.getLogger(__name__)

def user_from_token(token, secret_key=None):
    secret_key = secret_key or current_app.config['SECRET_KEY']

    try:
        s = Serializer(current_app.config['SECRET_KEY'])
        user = s.loads(token)
        return user
        
    except SignatureExpired:
        raise AccessRightsExpiredError("Token expired")

    except BadSignature:
        raise UnreadableAccessRightsError('Token BadSignature', 403)

def get_user_from_token_and_raise(
    request,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        token = request.cookies['token']
        return user_from_token(token, secret_key)

    except AccessRightsExpiredError:
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Token Expired', 403)
        res.set_cookie('token', expires=0)
        return res
    except InsufficientRightsError as e:
        log.info(e)
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Forbidden', 403)
        return res
    except KeyError as e:
        if redirect_on_expiration:
            return redirect(redirect_on_expiration, code=302)
        return Response('No token', 403)

    except UnreadableAccessRightsError:
        log.info('Invalid Token : BadSignature')
        # invalid token
        if redirect_on_invalid_token:
            res = redirect(redirect_on_invalid_token, code=302)
        else:
            res = Response('Token BadSignature', 403)
        res.set_cookie('token',  expires=0)
        return res

    except Exception as e:
        trap_all_exceptions = current_app.config.get(
            'TRAP_ALL_EXCEPTIONS',
            True
        )
        if not trap_all_exceptions:
            raise
        log.critical(e)
        msg = json.dumps({'type': 'Exception', 'msg': repr(e)})
        return Response(msg, 403)



def get_user_permissions(user, code_action, code_filter_type, module_code=None, code_object=None):
    """
        Get all the permissions of a user for an action, a module (or an object) and a filter_type
        Users permissions could be multiples because of user's group. The view mapped by VUsersPermissions does not take the
        max because some filter type could be not quantitative
        
        Parameters:
            user(dict)
            code_action(str): <C,R,U,V,E,D>
            code_filter_type(str): <SCOPE, GEOGRAPHIC ...>
            module_code(str): 'GEONATURE', 'OCCTAX'
            code_object(str): 'PERMISSIONS', 'DATASET' (table gn_permissions.t_oject)
        Return:
            Array<VUsersPermissions>
    """
    id_role = user['id_role']

    ors = [VUsersPermissions.module_code.ilike('GEONATURE')]

    q = (
        VUsersPermissions
        .query
        .filter(VUsersPermissions.id_role == id_role)
        .filter(VUsersPermissions.code_action == code_action)
        .filter(VUsersPermissions.code_filter_type == code_filter_type)
    )
    # if code_object we take only autorization of this object
    # no heritage from GeoNature
    if code_object:
        user_cruved = q.filter(VUsersPermissions.code_object == code_object).all()
        object_for_error = code_object
    # else: heritage cruved of the module or from GeoNature
    else:
        object_for_error = 'GEONATURE'
        if module_code:
            ors.append(VUsersPermissions.module_code.ilike(module_code))
            object_for_error = module_code
        
        user_cruved = q.filter(sa.or_(*ors)).all()

    try:
        assert len(user_cruved) > 0
        return user_cruved
    except AssertionError:
        raise InsufficientRightsError(
            'User "{}" cannot "{}" in module/app/object "{}"'.format(
                id_role, code_action, object_for_error
            )
        )


def build_cruved_dict(cruved, get_id):
    '''
        function utils to build a dict like {'C':'3', 'R':'2'}...
        from Array<VUsersPermissions>
    '''
    cruved_dict = {}
    for action_scope in cruved:
        if get_id:
            cruved_dict[action_scope[0]] = action_scope[2]
        else:
            cruved_dict[action_scope[0]] = action_scope[1]
    return cruved_dict

def beautifulize_cruved(actions, cruved):
    """
    Build more readable the cruved dict with the actions label
    Params:
        actions: dict action {'C': 'Action de créer'}
        cruved: dict of cruved
    Return:
        Array<dict> [{'label': 'Action de Lire', 'value': '3'}]
    """
    cruved_beautiful = []
    for key, value in cruved.items():
        temp = {}
        temp['label'] = actions.get(key)
        temp['value'] = value
        cruved_beautiful.append(temp)
    return cruved_beautiful


def cruved_scope_for_user_in_module(
    id_role=None,
    module_code=None,
    object_code='ALL',
    get_id=False
):
    """
    get the user cruved for a module
    if no cruved for a module, the cruved parent module is taken
    Child app cruved alway overright parent module cruved 
    Params:
        - id_role(int)
        - module_code(str)
        - get_id(bool): if true return the id_scope for each action
            if false return the filter_value for each action
    Return a tuple 
    - index 0: the cruved as a dict : {'C': 0, 'R': 2 ...}
    - index 1: a boolean which say if its an herited cruved
    """
    q = DB.session.query(
        VUsersPermissions.code_action,
        func.max(VUsersPermissions.value_filter),
        func.max(VUsersPermissions.id_filter)
    ).distinct(VUsersPermissions.code_action).filter(
        VUsersPermissions.id_role == id_role
    ).filter(
        VUsersPermissions.code_filter_type == 'SCOPE'
    ).filter(
        VUsersPermissions.code_object == object_code
    ).group_by(VUsersPermissions.code_action)

    cruved_actions = ['C', 'R', 'U', 'V', 'E', 'D']
    # if object not ALL, no heritage
    if object_code != 'ALL':
        object_cruved = q.all()

        cruved_dict = build_cruved_dict(object_cruved, get_id)
        update_cruved = {}
        for action in cruved_actions:
            if action in cruved_dict:
                update_cruved[action] = cruved_dict[action]
            else:
                update_cruved[action] = '0'
        return update_cruved, False

    # get max scope cruved for module GEONATURE
    parent_cruved_data = q.filter(VUsersPermissions.module_code.ilike('GEONATURE')).all()
    parent_cruved = {}
    # build a dict like {'C':'0', 'R':'2' ...} if get_id = False or
    # {'C': 1, 'R':3 ...} if get_id = True
    parent_cruved = build_cruved_dict(parent_cruved_data, get_id)

    # get max scope cruved for module passed in parameter
    module_cruved = {}
    if module_code:
        module_cruved_data = q.filter(VUsersPermissions.module_code.ilike(module_code)).all()
        module_cruved = build_cruved_dict(module_cruved_data, get_id)
        # for the module 
        for action_scope in module_cruved_data:
            if get_id:
                module_cruved[action_scope[0]] = action_scope[2]
            else:
                module_cruved[action_scope[0]] = action_scope[1]
        
    # get the id for code 0
    if get_id:
        id_scope_no_data = DB.session.query(TFilters.id_filter).filter(TFilters.value_filter == '0').one()[0]
    # update cruved with child module if action exist, otherwise take geonature cruved
    update_cruved = {}
    herited = False
    for action in cruved_actions:
        if action in module_cruved:
            update_cruved[action] = module_cruved[action]
        elif action in parent_cruved:
            update_cruved[action] = parent_cruved[action]
            herited = True
        else:
            if get_id:
                update_cruved[action] = id_scope_no_data
            else:
                update_cruved[action] = '0'
    return update_cruved, herited



def get_or_fetch_user_cruved(
    session=None,
    id_role=None,
    module_code=None,
    object_code= 'ALL'
):
    """
        Check if the cruved is in the session
        if not, get the cruved from the DB with 
        cruved_for_user_in_app()
    """
    if module_code in session and 'user_cruved' in session[module_code]:
        return session[module_code]['user_cruved']
    else:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=id_role,
            module_code=module_code,
            object_code=object_code
        )[0]
        session[module_code] = {}
        session[module_code]['user_cruved'] = user_cruved
    return user_cruved


#gestion du JWT
#
#
#
#
#
#

def user_from_JWToken(token, secret_key=None): 
    try:
        print("NOUGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT")
        user = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms='HS256')
        print(user['user'])
        return user['user']
        
    except InvalidTokenError:
        print("Invalid token")
        #raise AccessRightsExpiredError("")

    except DecodeError:
        print('Token failed verification')
        #raise UnreadableAccessRightsError('', 403)
    except InvalidSignatureError:
        print('Invalid signature')
    except ExpiredSignatureError:
        print('Expired token')
    except InvalidAudienceError:
        print('Unexpected audience value')
    except InvalidIssuerError:
        print('iss unexpected issue')
    except InvalidIssuedAtError:
        print('iat claim is in the future')
    except ImmatureSignatureError:
        print('nbf claim is in the future')
    except InvalidKeyError:
        print('Key is not in the proper format')
    except InvalidAlgorithmError:
        print('Not recognized algorithm')
    except MissingRequiredClaimError:
        print('No claim contaided in the claimset')

def get_user_from_JWToken_and_raise(
    request,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        
        token = request.headers.get('jwt')
        print(token)
        return user_from_JWToken(token, secret_key)

    except AccessRightsExpiredError:
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Token Expired', 403)
        res.set_cookie('token', expires=0)
        return res
    except InsufficientRightsError as e:
        log.info(e)
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Forbidden', 403)
        return res
    except KeyError as e:
        if redirect_on_expiration:
            return redirect(redirect_on_expiration, code=302)
        return Response('No token', 403)

    except UnreadableAccessRightsError:
        print("je suis méchant")
        log.info('Invalid Token : BadSignature')
        # invalid token
        if redirect_on_invalid_token:
            res = redirect(redirect_on_invalid_token, code=302)
        else:
            res = Response('Token BadSignature', 403)
        res.set_cookie('token',  expires=0)
        return res

    except Exception as e:
        trap_all_exceptions = current_app.config.get(
            'TRAP_ALL_EXCEPTIONS',
            True
        )
        if not trap_all_exceptions:
            raise
        log.critical(e)
        msg = json.dumps({'type': 'Exception', 'msg': repr(e)})
        return Response(msg, 403)
