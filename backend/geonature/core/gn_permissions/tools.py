import logging
import datetime

from flask import current_app
from werkzeug.exceptions import Unauthorized
from werkzeug.routing import RequestRedirect


from itsdangerous import (
    TimedJSONWebSignatureSerializer as Serializer,
    SignatureExpired,
    BadSignature,
)

import sqlalchemy as sa
from sqlalchemy.sql.expression import func


from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError,
    UnreadableAccessRightsError,
)
from pypnusershub.db.models import (User, AppRole)

from geonature.core.gn_commons.models import TModules
from geonature.core.taxonomie.models import Taxref
from geonature.core.users.models import (BibOrganismes, CorRole)
from geonature.core.ref_geo.models import LAreas, BibAreasTypes

from geonature.core.gn_permissions.models import VUsersPermissions
  
from geonature.utils.env import DB

log = logging.getLogger(__name__)


def user_from_token(token, secret_key=None):
    secret_key = secret_key or current_app.config["SECRET_KEY"]

    try:
        s = Serializer(current_app.config["SECRET_KEY"])
        user = s.loads(token)
        return user

    except SignatureExpired:
        raise AccessRightsExpiredError("Token expired")

    except BadSignature:
        raise UnreadableAccessRightsError("Token BadSignature", 403)

def log_expiration_warning():
    log.warning("""
        The parameter redirect_on_expiration will be soon removed.
        The redirection will be default to GeoNature login page
        """
    )

def get_user_from_token_and_raise(
    request,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Déserialisation du token utilisateur.
    Attrape les exceptions et en retourne de nouvelles qui seront gérées
    par "l'attrapeur" global d'exception (voir backend/geonature/core/errors/routes.py).
    """
    try:
        token = request.cookies["token"]
        return user_from_token(token, secret_key)

    except KeyError:
        if redirect_on_expiration:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_expiration)
        raise Unauthorized(description='No token.')
    except AccessRightsExpiredError:
        if redirect_on_expiration:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_expiration)
        raise Unauthorized(description='Token expired.')
    except UnreadableAccessRightsError:
        if redirect_on_invalid_token:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_invalid_token)
        raise Unauthorized(description='Token corrupted.')
    except Exception as e:
        trap_all_exceptions = current_app.config.get("TRAP_ALL_EXCEPTIONS", True)
        if not trap_all_exceptions:
            raise
        log.critical(e)
        raise Unauthorized(description=repr(e))


class UserCruved:
    """
    Classe permettant de récupérer le CRUVED d'un utilisateur pour un 
    module et un objet données.
    """

    _main_module_code = "GEONATURE"
    _main_object_code = "ALL"
    _cruved_actions = ["C", "R", "U", "V", "E", "D"]

    def __init__(
        self, id_role, code_filter_type, module_code=None, object_code=None, append_to_select=None
    ):
        self._id_role = id_role
        self._code_filter_type = code_filter_type
        self._module_code = module_code
        self._object_code = object_code
        self._permission_select = self._build_permission_select_list(append_to_select)

    def _build_permission_select_list(self, append_to_select):
        """
        Construction de la liste des couples "module_code, object_code"
        a récupérer pour générer le CRUVED.
        append_to_select => Ajout de sélection pour complexifié l'héritage.
        """
        permissions_select = {
            0: [self._module_code, self._object_code],
            10: [self._module_code, self._main_object_code],
            20: [self._main_module_code, self._object_code],
            30: [self._main_module_code, self._main_object_code],
        }

        # Append extra permissions order
        if append_to_select:
            permissions_select = {**permissions_select, **append_to_select}

        # Filter null value
        active_permissions_select = {k: v for k, v in permissions_select.items() if v[0] and v[1]}

        return active_permissions_select

    def _build_query_permission(self, code_action=None):
        """
        Construction de la requête de récupération des permissions.
        Ordre de récupération
            - code_objet et module_code
            - ALL et module_code
            - code_objet et GEONATURE
            - ALL et GEONATURE
        """
        q = (
            VUsersPermissions.query
            .filter(VUsersPermissions.id_role == self._id_role)
            .filter(VUsersPermissions.code_filter_type == self._code_filter_type)
        )
        if code_action:
            q = q.filter(VUsersPermissions.code_action == code_action)

        # List of module_code, object_code couples to select
        ors = []
        for k, (module_code, object_code) in self._permission_select.items():
            ors.append(
                sa.and_(
                    VUsersPermissions.module_code.ilike(module_code),
                    VUsersPermissions.code_object == object_code,
                )
            )
        q = q.filter(sa.or_(*ors))
        return q.all()

    def _build_other_filters_for_max_perm_query(self, gathering):
        """
        Construction de la requête de récupération des "permissions" contenant
        les éventuels autres filtres (différent de self._code_filter_type).
        Ordre de récupération
            - code_objet et module_code
            - ALL et module_code
            - code_objet et GEONATURE
            - ALL et GEONATURE
        """
        q = (
            VUsersPermissions.query
            .filter(VUsersPermissions.code_filter_type != self._code_filter_type)
            .filter(VUsersPermissions.gathering == gathering)
        )
        return q.all()
        
    @staticmethod
    def get_actions_codes():
        return UserCruved._cruved_actions

    def get_user_perm_list(self, code_action=None):
        return self._build_query_permission(code_action=code_action)

    def get_max_perm(self, perm_list):
        """
        Retourne la permission possédant la valeur de filtre la plus grande
        parmis une liste d'instances de VUsersPermissions.
        Ce fonctionnement est prévu pour des filtres dont la valeur est numérique.
        Utilisé principalement pour le CRUVED avec le filtre de propriété (=SCOPE).
        """
        user_with_highter_perm = perm_list[0]
        max_code = user_with_highter_perm.value_filter
        i = 1
        while i < len(perm_list):
            if int(perm_list[i].value_filter) >= int(max_code):
                max_code = perm_list[i].value_filter
                user_with_highter_perm = perm_list[i]
            i = i + 1
        return user_with_highter_perm

    def build_herited_user_cruved(self, user_permissions):
        """
        Retourne la permission avec la valeur la plus haute pour une liste 
        de permission données appartenant à un utilisateur.

        Parameters:
            - user_permissions(list<VUsersPermissions>)
        Return:
            VUsersPermissions
            herited
            herited_object
        """
        # Loop on user permissions.
        # Return the module permission if exist.
        # Otherwise return GEONATURE permission.
        type_of_perm = {}

        # Sort by key the permissions inheritances tests
        permission_keys = sorted(self._permission_select)

        # Filter the GeoNature perm and the module perm in two arrays to make heritage
        for user_permission in user_permissions:
            for k, (module_code, object_code) in self._permission_select.items():
                if (
                    user_permission.code_object == object_code
                    and user_permission.module_code == module_code
                ):
                    type_of_perm.setdefault(k, []).append(user_permission)

        # Take the max of the different permissions
        herited = False
        herited_object = None
        for k in permission_keys:
            if k in type_of_perm and len(type_of_perm[k]) > 0:
                max_perm = self.get_max_perm(type_of_perm[k])

                # If key is not first in list, then inheritance
                if k > permission_keys[0]:
                    herited = True
                    herited_object = self._permission_select[k]
                return max_perm, herited, herited_object

    def get_perm_for_all_actions(self):
        """
        Construction des permissions pour chaque action d'un module/objet données

        Return:
            - herited_cruved : valeur max de la permission pour chaque action du cruved.
            - herited(boolean) : True si hérité, False sinon.
            - herited_object((module_code, object_code)) : si herited
                nom du module/objet pour lequel la valeur du cruved est retourné.

        """
        # Get all user permissions
        user_permissions = self.get_user_perm_list()

        # For each permission, we sort by action
        perm_by_actions = {}
        for perm in user_permissions:
            perm_by_actions.setdefault(perm.code_action, []).append(perm)

        # For each action, we build the permissions
        herited_perm = {}  # List of CRUVED permissions
        is_herited = False
        g_herited_object = None
        for action, perm in perm_by_actions.items():
            herited_perm[action], herited, herited_object = self.build_herited_user_cruved(perm)
            if herited:
                is_herited = True
                g_herited_object = herited_object

        # Set default value to return
        default_value = "0"

        # Prepare output
        herited_cruved = {}
        for action in self._cruved_actions:
            if action in herited_perm:
                herited_cruved[action] = getattr(herited_perm[action], "value_filter")
            else:
                herited_cruved[action] = default_value

        return herited_cruved, is_herited, g_herited_object

    def get_perm_for_one_action(self, action):
        """
        Récupération de la permission héritée avec la valeur la plus grande 
        pour une action donnée.
        """
        permissions = self.get_user_perm_list(action)

        permissions = self.build_herited_user_cruved(permissions)
        if permissions is not None:
            (max_perm, is_inherited_by_module, herited_by) = permissions
            other_filters_permissions = self._build_other_filters_for_max_perm_query(max_perm.gathering)
            return max_perm, is_inherited_by_module, herited_by, other_filters_permissions


def cruved_scope_for_user_in_module(
    id_role=None,
    module_code=None,
    object_code=None,
    get_herited_obj=False,
    append_to_select=None,
):
    """
    Récupère le CRUVED de l'utilisateur pour un module ou un objet.
    Si le CRUVED n'existe pas pour un module, il est récupéré de son module
    parent.
    Le CRUVED d'un module enfant écrase toujours celui de ses parents.

    Params:
        - id_role(int)
        - module_code(str)
        - object_code(str)
        - append_to_select (dict) : dictionnaire contenant des règles 
            d'héritage supplémentaires.

    Return a tuple
    - index 0: le CRUVED sous forme de dictionnaire : {'C': 0, 'R': 2 ...}
    - index 1: un bouleén indiquant si le CRUVED est hérité ou pas.
    """
    herited_cruved, is_herited, herited_object = UserCruved(
        id_role=id_role,
        code_filter_type="SCOPE",
        module_code=module_code,
        object_code=object_code,
        append_to_select=append_to_select,
    ).get_perm_for_all_actions()
    if get_herited_obj:
        is_herited = (is_herited, herited_object)
    return herited_cruved, is_herited


def get_or_fetch_user_cruved(session=None, id_role=None, module_code=None, object_code=None):
    """
    Vérifie la présence du CRUVED en session sinon le récupère depuis la base de données.
    """
    if module_code in session and "user_cruved" in session[module_code]:
        return session[module_code]["user_cruved"]
    else:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=id_role, module_code=module_code, object_code=object_code
        )[0]
        session[module_code] = {}
        session[module_code]["user_cruved"] = user_cruved
    return user_cruved


class PermissionsManager:
    """Classe de gestion des permissions.
    Elle permet de vérifier l'accès d'un utilisateur et de récupérer
    ses permissions.
    """
    _main_module_code = "GEONATURE"
    _main_object_code = "ALL"
    _property_filter_type = "SCOPE"
    _actions = ["C", "R", "U", "V", "E", "D"]
    _current_access_permission_infos = None

    def __init__(
        self, 
        id_role, 
        module_code=None, 
        action_code=None, 
        object_code=None, 
        append_inheritance_rules=None,
        without_outdated=True,
    ):
        """[summary]

        Parameters
        ----------
        id_role : int
            Identifiant d'un rôle.
        module_code : str
            Code d'un module.
        action_code : str, optional
            Code d'une action. Par défaut : None.
        object_code : str, optional
            Code d'un objet. Par défaut : None.
        permissions: dict
            Permissions d'un utilisateur sur l'ensemble des modules
        append_inheritance_rules : dict<list>, optional
            Permet l'ajout de nouvelles règle d'héritage. Par défaut : None.
            Ajout de règles pour étendre l'héritage. Ces règles sont fusionnées
            aux règle par défaut.
            Format du dictionnaire :
            la clé est un entier permettant de définir la priorité de la régle,
            la valeur correspondante un tableau avec l'entrée 0 correspondant
            au code d'un module et l'entrée 1 au code d'un objet.
        without_outdated : bool, optional
            Indique si la requête d'extraction des permissions doit (=False)
            ou pas (=True) retourner les permissions dont la date de fin est dépassée.
            Par défaut : True, les permissions dont la date de fin est dépassée 
            ne sont pas retournées.
        """
        self._id_role = id_role
        self._module_code = module_code
        self._action_code = action_code
        self._object_code = object_code
        self._inheritance_rules = self._build_inheritance_rules(append_inheritance_rules)
        self._without_outdated = without_outdated
        self.permissions = {}


    def _build_inheritance_rules(self, append_extra_rules=None):
        """
        Construction de la liste des règles permettant d'applatir les
        permissions. Basé sur des couples "module_code, object_code".
        Ordre de l'héritage par défaut entre modules et objets (=~ sous-modules) :
            - objet et module spécififés
            - objet par défaut (=ALL) et module spécififé
            - objet spécififé et module par défaut (=GEONATURE)
            - objet par défaut (=ALL) et module par défaut (=GEONATURE)

        Parameters
        ----------
        append_extra_rules : dict
            Ajout de règles pour étendre l'héritage. Ces règles sont fusionnées
            aux règle par défaut.
            Format du dictionnaire :
            la clé est un entier permettant de définir la priorité de la régle,
            la valeur correspondante un tableau avec l'entrée 0 correspondant
            au code d'un module et l'entrée 1 au code d'un objet.
        
        Returns
        -------
        dict
            Dictionnaire des règles fusionné avec les éventuelles règles
            supplémentaires.
        """
        default_rules = {
            0: [self._module_code, self._object_code],
            10: [self._module_code, self._main_object_code],
            20: [self._main_module_code, self._object_code],
            30: [self._main_module_code, self._main_object_code],
        }

        # Append extra permissions rules if necessary
        rules = {**default_rules, **append_extra_rules} if append_extra_rules else default_rules

        # Filter null value
        active_rules = {k: v for k, v in rules.items() if v[0] and v[1]}
        return active_rules

    def _get_access_permissions(self):
        """ Fournie toutes les permissions d'accès d'un utilisateur.

        Construit la requête de récupération de toutes les permissions d'accès
        de l'utilisateur défini en se basant sur le filtre d'appartenance 
        (=SCOPE) et les règles d'héritage entre modules et objets.
        L'héritage entre groupe et utilisateur est pris en compte via 
        la vue "v_users_permissions" sur laquelle elle s'appuie.
        Les résultats contiennent toutes les permissions nécessaires à l'
        application de l'héritage entre modules et objets (voir _flatten_permissions()).

        Returns
        -------
        array<VUsersPermissions>
            Un tableau d'objet VUsersPermissions résultant de la requête.
        """
        query = self._build_base_query()
        query = query.filter(VUsersPermissions.code_filter_type == PermissionsManager._property_filter_type)
        
        # List of module_code, object_code couples to select
        ors = []
        for k, (module_code, object_code) in self._inheritance_rules.items():
            ors.append(
                sa.and_(
                    VUsersPermissions.module_code.ilike(module_code),
                    VUsersPermissions.code_object == object_code,
                )
            )
        query = query.filter(sa.or_(*ors))
        
        return query.all()

    def _get_all_permissions(self, property_value=None):
        """ Fournie toutes les permissions (avec tous les filtres) d'un utilisateur.

        Construit la requête de récupération de toutes les permissions de 
        l'utilisateur défini en se basant sur les règles d'héritage entre 
        modules et objets.
        L'héritage entre groupe et utilisateur est pris en compte via 
        la vue "v_users_permissions" sur laquelle elle s'appuie.
        Les résultats contiennent toutes les permissions nécessaires à l'
        application de l'héritage entre modules et objets (voir _fatten_permissions()).

        Parameters
        ----------
        property_value : int, optional
            Les permissions retournée doivent posséder une valeur pour le
            filtre d'appartenance (=SCOPE) supérieur ou égale à la valeur
            fournie.

        Returns
        -------
        array<VUsersPermissions>
            Un tableau d'objet VUsersPermissions résultant de la requête.
        """
        filter_by_modules = VUsersPermissions.module_code.in_((
            self._main_module_code, 
            self._module_code,
        ))

        # Default query send all permissions link to main and current initialized modules
        query = self._build_base_query().filter(filter_by_modules)

        # Get all gathering with a property level bigger or equal to the property value parameter
        if property_value:
            subquery = (
                self._build_base_query(VUsersPermissions.gathering.distinct())
                .filter(filter_by_modules)
                .filter(
                    sa.and_(
                        VUsersPermissions.value_filter >= property_value,
                        VUsersPermissions.code_filter_type == self._property_filter_type,
                    )
                )
                .subquery()
            )
            query = query.filter(VUsersPermissions.gathering.in_(subquery))

        return query.all()

    def _build_base_query(self, fields=VUsersPermissions):
        """Construit la requête de base permettant d'extraire les permissions.

        Parameters
        ----------
        fields : any, optional
            Le contenu est passé à méthode query() de SqlAlchemy. 
            Par defaut VUsersPermissions.

        Returns
        -------
        sqlalchemy.orm.Query
            Retourne la requete de base.
        """

        query = (
            DB.session
            .query(fields)
            .filter(VUsersPermissions.id_role == self._id_role)
        )

        if self._without_outdated:
            # TODO: check if filter on end_date work as expected !
            query = query.filter(
                sa.or_(
                    VUsersPermissions.end_date == None,
                    VUsersPermissions.end_date >= func.now(),
                )
            )

        if self._action_code:
            query = query.filter(VUsersPermissions.code_action == self._action_code)
        
        return query

    def _get_other_filters(self, gathering):
        """Récupération des "permissions" contenant les éventuels autres filtres 
        (différent de self._property_filter_type).
        """
        query = (
            DB.session
            .query(VUsersPermissions)
            .filter(VUsersPermissions.code_filter_type != PermissionsManager._property_filter_type)
            .filter(VUsersPermissions.gathering == gathering)
        )
        return query.all()

    def _flatten_permissions(self, permissions):
        """
        Retourne la permission avec la valeur la plus haute pour une liste 
        de permissions données appartenant à un utilisateur.

        Parameters
        ----------
        permissions : list<VUsersPermissions>

        Returns
        ------
        dict
            Dictionnaire contenant les clés suivantes :
            - higher_perm : objet VUsersPermissions possédant
            la valeur value_filter la plus haute.
            - is_inherited : booléen indiquant si la permission la plus 
            haute est issue d'un héritage.
             - inherited_by :
            herited_object : objet VUsersPermissions parent de l'entrée
            higher_perm.
        """
        # Dispatch permissions by inheritance rules keys
        sorted_perms = {}
        for permission in permissions:
            for k, (module_code, object_code) in self._inheritance_rules.items():
                if (
                    permission.code_object == object_code
                    and permission.module_code == module_code
                ):
                    sorted_perms.setdefault(k, []).append(permission)

        # Return the sorted list of keys from inheritance rules dictionary
        sorted_rules_keys = sorted(self._inheritance_rules)
        is_inherited = False
        inherited_by = None
        # Take the permission with the higher value of the different permissions 
        # given for the property filter (=SCOPE).
        for k in sorted_rules_keys:
            if k in sorted_perms and len(sorted_perms[k]) > 0:
                higher_perm = self._extract_higher_permission(sorted_perms[k])

                # If current key is superior to the first key in sorted rules key list that indicate
                # an inherited permission !
                if k > sorted_rules_keys[0]:
                    is_inherited = True
                    inherited_by = self._inheritance_rules[k]
                return {
                    "higher_perm": higher_perm, 
                    "is_inherited": is_inherited, 
                    "inherited_by": inherited_by,
                }

    def _extract_higher_permission(self, permissions):
        """Extrait la permission possédant la valeur de filtre la plus grande
        parmis une liste.

        Ce fonctionnement est prévu pour des filtres dont la valeur est numérique.
        Utilisé principalement pour le CRUVED avec le filtre de propriété (=SCOPE).
        Il est nécessaire de s'assurer au préalable que la list de permissions
        fournies appartiennent toutes au même type de filtre.

        Parameters
        ----------
        permissions : list<VUsersPermissions>
            Liste d'instances de VUsersPermissions avec le même type de filtre.

        Returns
        -------
        VUsersPermissions
            La permission possédant la valeur de filtre la plus haute.
        """
        higher_perm = permissions[0]
        max_value = higher_perm.value_filter
        i = 1
        while i < len(permissions):
            if int(permissions[i].value_filter) >= int(max_value):
                max_value = permissions[i].value_filter
                higher_perm = permissions[i]
            i = i + 1
        return higher_perm
    
    @staticmethod
    def get_actions_codes():
        """Accès aux codes des actions.

        Les codes des actions sont issus d'un paramètre privé de cett classe.
        Bien que les actions évolue rarement dans la base, il peut exister
        une différence.

        Returns
        -------
        list<string>
            Retourne la liste des codes d'action possible.
        """
        return PermissionsManager._actions

    def get_access_permission(self):
        """Extrait la permission d'accès correspondant au module, à l'action et 
        éventuellement à l'objet définient lors de l'initialisation de la classe.

        Cela correspond à la permission héritée ou pas possédant la valeur
        la plus grande pour le filtre d'appartenance (=SCOPE).
        La permission d'accès est seulement évaluée pour le filtre d'appartenance.
        Elle est retournée quelque soit la valeur du filtre trouvée.
        
        See Also
        --------
        check_access
        
        Returns
        -------
        VUsersPermissions | None
            Retourne la permission permettant à l'utilisateur d'accès 
        """
        return self._get_current_access_permission_infos()["higher_perm"]

    def get_full_access_permission(self):
        """Retourne la permission d'accès, les infos d'héritage et les 
        autres filtres (différent du filtre d'appartenance).

        Returns
        -------
        dict
            Dictionnaire contenant:
            - higher_perm : la permission (VUsersPermissions) d'accès
            - is_inherited : booléen indiquant si la permission est héritée
            par un module.
            - inherited_by : les informations concernant l'héritage.
            - other_filters : les "permissions" (VUsersPermissions) des 
                autres filtres.

        """
        infos = self._get_current_access_permission_infos()
        if infos:
            gathering = str(infos["higher_perm"].gathering)
            infos["other_filters"] = self._get_other_filters(gathering)
        return infos

    def _get_current_access_permission_infos(self):
        # Use memory cache to avoid to flatten and query several times the database.
        if self._current_access_permission_infos == None:
            access_permissions = self._get_access_permissions()
            self._current_access_permission_infos = self._flatten_permissions(access_permissions)
        return self._current_access_permission_infos

    def get_auth(self):
        """Fourni les informations sur l'authorisation d'accès : utilisateur et permission d'accès.

        See Also
        --------
        check_access
        
        Returns
        -------
        dict<dict>
            Format :
            {
                "user": {
                    "id": 1,
                    "fisrtname": "Paul",
                    "lastname": "DUPONT",
                    "fullname": "Paul DUPONT",
                    "organisme_id": 1,
                },
                "permission": {
                    "id": 1,
                    "module" : "SYNTHESE",
                    "action": "R",
                    "object": "PRIVATE_OBSERVATION",
                    "filter": "SCOPE",
                    "value": "3",
                    "gathering": "00e21d2d-6e7e-4002-808c-c205798e36e6",
                    "end_date" : "2021-05-06 00:00:00"
                }
            }
        """
        perm = self.get_access_permission()
        # TODO : Voir si nous devrions pas utiliser des classes pour user et permission ?

        auth = {
            "user": {
                "id": int(perm.id_role),
                "fisrtname": perm.prenom_role,
                "lastname": perm.nom_role,
                "fullname": " ".join((perm.prenom_role, perm.nom_role)),
                "organisme_id": int(perm.id_organisme),
            },
            "permission": {
                "id": int(perm.id_permission),
                "module" : perm.module_code,
                "action": perm.code_action,
                "object": perm.code_object,
                "filter": perm.code_filter_type,
                "value": perm.value_filter,
                "gathering": str(perm.gathering),
                "end_date" : perm.end_date
            }
        }
        return auth

    def check_access(self):
        """Vérifie les permissions d'accès d'un utilisateur.
        
        Cette vérification se base sur le filtre d'appartenance (=SCOPE).
        Il est nécessaire d'avoir définie à minima un module et une action 
        au niveau de la classe. Si présent, l'objet sera pris en compte.

        Si l'utilisateur possède une permission correspondant à l'action définie
        sur le module ou l'objet défini au niveau de la classe, l'accès est autorisé.
        Ceci peut importe la valeur du filtre du moment qu'elle est supérieur à 0 donc 
        différente de "Appartenant à personne".

        Raises
        ------
        InsufficientRightsError
            Exception levée si l'utilisateur n'a pas les permissions d'accès
            nécessaires.

        Returns
        -------
        bool
            Retourne True si l'utilisateur a les bons droits d'accès.
        """
        access_permission = self.get_access_permission()

        if access_permission is None or (
            access_permission is not None 
            and access_permission.value_filter == "0"
        ):
            if self._object_code:
                message = f"User {self._id_role} cannot {self._action_code} {self._object_code}"
            else:
                message = f"User {self._id_role} cannot {self._action_code} in {self._module_code}"
            raise InsufficientRightsError(message, 403)
        else:
            return True
    
    def get_all_permissions_with_all_filters(self):
        """Retourne toutes les permissions correspondant au module, à l'objet (si
        défini) et à l'action définient au niveau de la classe et possédant un 
        filtre de type SCOPE avec une valeur équivalante à la valeur de la 
        permission d'accès.

        Les filtres sont rassemblée par le champ de rassemblement (gathering) 
        des permissions.

        Returns
        -------
        list<dict>
            Retourne une liste de dictionnaires  contenant les atributs :
            - "gathering" : UUID corespondant à la valeur de rassemblement 
            des différents filtres d'une permission,
            - "module" : code du module de la permission.
            - "action" : code l'action de la permission.
            - "object" : code de l'objet de la permission.
            - "filters" : dictionnaire des filtres avec en clé le 
            code du type de filtre et en valeur la valeur du filtre.
            Ex. : [ 
                {
                    "gathering: "65da3705-45cc-4f95-8d88-d217ed6fcc25",
                    "object": "PRIVATE_OBSERVATION",
                    "filters": {
                        "SCOPE" : "3",
                        "PRECISION": "exact",
                        "GEOGRAPHIC: ["3896"],
                        "TAXONOMIC": ["188731"]
                    }
                }
            ]       
        """
        access_permission = self.get_access_permission()
        min_property_value = access_permission.value_filter
        permissions = self._get_all_permissions(min_property_value)

        # Gather all filters of each permission
        gathered_filters = {}
        for perm in permissions:
            gathering = str(perm.gathering)
            if gathering not in gathered_filters.keys():
                gathered_filters[gathering] = {
                    "gathering": gathering,
                    "module": perm.module_code,
                    "action": perm.code_action,
                    "object": perm.code_object,
                    "filters": {
                        perm.code_filter_type: perm.value_filter,
                    }
                }
            else:
                gathered_filters[gathering]["filters"][perm.code_filter_type] = perm.value_filter

        # Prepare output: remove gathering key
        output = gathered_filters.values()
        return output
        




class UserPermissions:
    def __init__(self, id_role):
        self.id_role = id_role
        self.permissions = {}

    def append_permission(
        self, module_code, action_code, object_code,  
        label, code, filter_type, filter_value, gathering, end_date,
        is_inherited, inherited_by=None,
    ):
        """Les permissions non héritées doivent être ajouté en premier.

        Parameters
        ----------
        is_inherited : bool
            Booléen indiquant si oui ou non la permission est héritée d'un module parent ou d'un groupe.
        """
        # Initialize new module entry
        if module_code not in self.permissions.keys():
            self.permissions[module_code] = {}

        # Build filter labels if necessary
        labels = None
        if filter_type == 'GEOGRAPHIC':
            filter_value = split_value_filter(filter_value)
            labels = format_geographic_filter_values(filter_value)
        if filter_type == 'TAXONOMIC':
            filter_value = split_value_filter(filter_value)
            labels = format_taxonomic_filter_values(filter_value)

        # Create new permission or only add an additionnal filter
        gathering = str(gathering)
        permission_hash = f"{module_code}-{action_code}-{object_code}-{gathering}"
        if permission_hash not in self.permissions[module_code].keys():
            self.permissions[module_code][permission_hash] = {
                "name": label,
                "code": code,
                "gathering": gathering,
                "module": module_code,
                "action": action_code,
                "object": object_code,
                "end_date": end_date,
                "filters": [{
                    "type": filter_type,
                    "value": filter_value,
                    "label": labels,
                }],
                "is_inherited": is_inherited,
                "inherited_by": (inherited_by if is_inherited else None),
            }
        else:
            recorded_gathering = self.permissions[module_code][permission_hash]["gathering"]
            recorded_filters = self.permissions[module_code][permission_hash]["filters"]
            if (
                not any(f['type'] == filter_type for f in recorded_filters) 
                and gathering == recorded_gathering
            ):
                new_filter = {
                    "type": filter_type,
                    "value": filter_value,
                    "label": labels,
                }
                self.permissions[module_code][permission_hash]["filters"].append(new_filter)




def split_value_filter(data: str):
    if data == None or data == '':
        return []
    values = data.split(',')
    unduplicated_data = unduplicate_values(values)
    return unduplicated_data

def unduplicate_values(data: list) -> list:
    unduplicated_data = []
    [unduplicated_data.append(x) for x in data if x not in unduplicated_data]
    return unduplicated_data

def format_geographic_filter_values(areas: [int]):
    formated_geo = []
    if len(areas) > 0:
        for area in get_areas_infos(areas):
            name = area["area_name"]
            code = area["area_code"]
            if area["type_code"] == "DEP":
                name = f"{name} [{code}]"
            elif area["type_code"] == "COM":
                name = f"{name} [{code[:2]}]"
            formated_geo.append(name)
    return formated_geo

def get_areas_infos(area_ids: [int]):
    data = (DB
        .session.query(
            LAreas.area_name,
            LAreas.area_code,
            BibAreasTypes.type_code
        )
        .join(LAreas, LAreas.id_type == BibAreasTypes.id_type)
        .filter(LAreas.id_area.in_(tuple(area_ids)))
        .all()
    )
    return [row._asdict() for row in data]


def format_taxonomic_filter_values(taxa: [int]):
    formated_taxonomic = []
    if len(taxa) > 0:
        for taxon in get_taxons_infos(taxa):
            name = taxon["nom_complet_html"]
            code = taxon["cd_nom"]
            formated_taxonomic.append(f"{name} [{code}]")
    return formated_taxonomic


def get_taxons_infos(taxon_ids: [int]):
    data = (DB
        .session.query(Taxref)
        .filter(Taxref.cd_nom.in_(tuple(taxon_ids)))
        .all()
    )
    return [row.as_dict() for row in data]

def build_value_filter_from_list(data: list):
    unduplicated_data = unduplicate_values(data)
    return ",".join(map(str, unduplicated_data))





# -----------------------------------------------------------------------
# UTILS functions
# TODO: move this functions in other file (?)
def prepare_output(d, remove_in_key=None):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(prepare_output(item, remove_in_key))
        return output
    elif isinstance(d, dict) :
        new = {}
        for k, v in d.items():
            # Remove None and empty values
            if v != None and v != "":
                # Remove substring in key
                if remove_in_key:
                    k = k.replace(remove_in_key, '').strip('_')
                # Value processing recursively
                new[format_to_camel_case(k)] = prepare_output(v, remove_in_key)
        return new
    else:
        return d


def format_to_camel_case(snake_str):
    components = snake_str.split('_')
    return components[0].lower() + ''.join(x.title() for x in components[1:])


def prepare_input(d):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(prepare_input(item))
        return output
    elif isinstance(d, dict) :
        return dict((format_to_snake_case(k), v) for k, v in d.items())
    else:
        return d


def format_to_snake_case(camel_str): 
    return ''.join(['_'+char.lower() if char.isupper()  
        else char for char in camel_str]).lstrip('_') 


def format_role_name(role):
    name_parts = []
    if role.prenom_role:
        name_parts.append(role.prenom_role)
    if role.nom_role:
        name_parts.append(role.nom_role)
    return " ".join(name_parts)

def format_end_access_date(end_date, date_format="%Y-%m-%d"):
    formated_end_date = None
    if (end_date):
        date = datetime.date(end_date["year"], end_date["month"], end_date["day"])
        formated_end_date = date.strftime(date_format)
    return formated_end_date