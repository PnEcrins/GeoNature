"""
Modèles du schema gn_permissions
"""
import enum

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.dialects.postgresql import JSONB, UUID

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB


@serializable
class VUsersPermissions(DB.Model):
    __tablename__ = "v_roles_permissions"
    __table_args__ = {"schema": "gn_permissions"}
    id_role = DB.Column(DB.Integer, primary_key=True)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    id_organisme = DB.Column(DB.Integer)
    group_name = DB.Column(DB.Boolean)
    permission_label = DB.Column(DB.Unicode)
    permission_code = DB.Column(DB.Unicode)
    id_module = DB.Column(DB.Integer, primary_key=True)
    module_code = DB.Column(DB.Unicode)
    id_action = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    description_action = DB.Column(DB.Unicode)
    code_object = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer, primary_key=True)
    value_filter = DB.Column(DB.Unicode, primary_key=True)
    code_filter_type = DB.Column(DB.Unicode)
    gathering = DB.Column(UUID(as_uuid=True), primary_key=True)
    end_date = DB.Column(DB.DateTime)
    id_permission = DB.Column(DB.Integer)

    def __repr__(self):
        msg = (
            "VUsersPermissions " +
            f"role='{self.id_role}', " +
            f"module='{self.module_code}', " + 
            f"action='{self.code_action}', " +
            f"object='{self.code_object}', " +
            f"filter_type='{self.code_filter_type}', " +
            f"filter_value='{self.value_filter}', " +
            f"gathering='{self.gathering}', " +
            f"end_date='{self.end_date}', " +
            f"herited_from_group='{self.group_name}' "
        )
        return msg


@serializable
class BibFiltersType(DB.Model):
    __tablename__ = "bib_filters_type"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter_type = DB.Column(DB.Integer, primary_key=True)
    code_filter_type = DB.Column(DB.Unicode)
    label_filter_type = DB.Column(DB.Unicode)
    description_filter_type = DB.Column(DB.Unicode)


class FilterValueFormats(str, enum.Enum):
    string: str = "string"
    integer: str = "integer"
    boolean: str = "boolean"
    geometry: str = "geometry"
    csvint: str = "csvint"


@serializable
class BibFiltersValues(DB.Model):
    __tablename__ = "bib_filters_values"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter_value = DB.Column(DB.Integer, primary_key=True)
    id_filter_type = DB.Column(DB.Integer)
    value_format = DB.Column(DB.Enum(FilterValueFormats))
    predefined = DB.Column(DB.Boolean)
    value_or_field = DB.Column(DB.Unicode(length=50))
    label = DB.Column(DB.Unicode(length=255))
    description = DB.Column(DB.UnicodeText)


@serializable
class TActions(DB.Model):
    __tablename__ = "t_actions"
    __table_args__ = {"schema": "gn_permissions"}
    id_action = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    description_action = DB.Column(DB.Unicode)


@serializable
class TObjects(DB.Model):
    __tablename__ = "t_objects"
    __table_args__ = {"schema": "gn_permissions"}
    id_object = DB.Column(DB.Integer, primary_key=True)
    code_object = DB.Column(DB.Unicode)
    description_object = DB.Column(DB.Unicode)


@serializable
class CorRoleActionFilterModuleObject(DB.Model):
    __tablename__ = "cor_role_action_filter_module_object"
    __table_args__ = {"schema": "gn_permissions"}
    id_permission = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_module = DB.Column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"))
    id_action = DB.Column(DB.Integer, ForeignKey("gn_permissions.t_actions.id_action"))
    id_object = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
        default=select([TObjects.id_object]).where(TObjects.code_object == "ALL"),
    )
    gathering = DB.Column(UUID(as_uuid=True), server_default="uuid_generate_v4()")
    end_date = DB.Column(DB.DateTime)
    id_filter_type = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.bib_filters_type.id_filter_type"),
    )
    value_filter = DB.Column(DB.Unicode)
    id_request = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_requests.id_request"),
    )

    role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role],
    )
    action = DB.relationship(
        TActions,
        primaryjoin=(TActions.id_action == id_action),
        foreign_keys=[id_action],
    )
    module = DB.relationship(
        TModules,
        primaryjoin=(TModules.id_module == id_module),
        foreign_keys=[id_module],
    )
    object = DB.relationship(
        TObjects,
        primaryjoin=(TObjects.id_object == id_object),
        foreign_keys=[id_object],
    )
    cor_filter = DB.relationship(
        BibFiltersType,
        primaryjoin=(BibFiltersType.id_filter_type == id_filter_type),
        foreign_keys=[id_filter_type],
    )

    def is_already_exist(self):
        """ Retourne la première permission trouvée correspondant à l'objet courant.
            ATTENTION: cette méthode ne vérifie pas tous les filtres d'une permission. Elle
            vérifie seulement qu'il n'existe pas déjà un enregistrement similaire dans la table.
            Tous les champs sont vérifiés à l'exception de la clé "id_permission".

            Returns
            -------
            CorRoleActionFilterModuleObject or None
                Un objet CorRoleActionFilterModuleObject s'il existe ou sinon None.
        """
        privilege = {
            "id_role": self.id_role,
            "id_module": self.id_module,
            "id_action": self.id_action,
            "id_object": self.id_object,
            "gathering": self.gathering,
            "end_date": self.end_date,
            "id_filter_type": self.id_filter_type,
            "value_filter": self.value_filter,
            "id_request": self.id_request,
        }
        return (
            DB.session.query(CorRoleActionFilterModuleObject)
            .filter_by(**privilege)
            .first()
        )


class RequestStates(str, enum.Enum):
    pending: str = "pending"
    refused: str = "refused"
    accepted: str = "accepted"

@serializable
class TRequests(DB.Model):
    __tablename__ = "t_requests"
    __table_args__ = {"schema": "gn_permissions"}
    id_request = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    token = DB.Column(UUID(as_uuid=True), server_default="uuid_generate_v4()")
    end_date = DB.Column(DB.DateTime)
    processed_state = DB.Column(DB.Enum(RequestStates))
    processed_date = DB.Column(DB.DateTime)
    processed_by = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    refusal_reason = DB.Column(DB.Unicode(length=1000))
    geographic_filter = DB.Column(DB.Unicode)
    taxonomic_filter = DB.Column(DB.Unicode)
    sensitive_access = DB.Column(DB.Boolean, default=False)
    additional_data = DB.Column(JSONB)
    meta_create_date = DB.Column(DB.DateTime, default="now()")
    meta_update_date = DB.Column(DB.DateTime, default="now()")

    cor_role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role],
    )

@serializable
class CorModuleActionObjectFilter(DB.Model):
    __tablename__ = "cor_module_action_object_filter"
    __table_args__ = {"schema": "gn_permissions"}
    id_permission_available = DB.Column(DB.Integer, primary_key=True)
    id_module = DB.Column(
        DB.Integer, 
        ForeignKey("gn_commons.t_modules.id_module"),
    )
    id_action = DB.Column(
        DB.Integer, 
        ForeignKey("gn_permissions.t_actions.id_action"),
    )
    id_object = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
        default=select([TObjects.id_object]).where(TObjects.code_object == "ALL"),
    )
    id_filter_type = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.bib_filters_type.id_filter_type"),
    )
    code = DB.Column(DB.Unicode)
    label = DB.Column(DB.Unicode)
    description = DB.Column(DB.Unicode)

    cor_module = DB.relationship(
        TModules,
        primaryjoin=(TModules.id_module == id_module),
        foreign_keys=[id_module],
    )
    cor_action = DB.relationship(
        TActions,
        primaryjoin=(TActions.id_action == id_action),
        foreign_keys=[id_action],
    )
    cor_object = DB.relationship(
        TObjects,
        primaryjoin=(TObjects.id_object == id_object),
        foreign_keys=[id_object],
    )
    cor_filter = DB.relationship(
        BibFiltersType,
        primaryjoin=(BibFiltersType.id_filter_type == id_filter_type),
        foreign_keys=[id_filter_type],
    )
