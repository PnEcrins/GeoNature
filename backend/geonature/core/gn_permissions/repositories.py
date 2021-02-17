import logging

import sqlalchemy as sa
from sqlalchemy.orm import exc


from pypnusershub.db.models import User
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    BibFiltersType,
    CorModuleActionObjectFilter,
    CorRoleActionFilterModuleObject,
    TActions,
    TObjects,
)
from geonature.core.gn_permissions.tools import (
    format_end_access_date, build_value_filter_from_list, unduplicate_values 
)
from geonature.utils.env import DB

log = logging.getLogger(__name__)


class PermissionRepository:
    def delete_permission_by_gathering(self, gathering):
        result = (
            DB.session
            .query(CorRoleActionFilterModuleObject)
            .filter(CorRoleActionFilterModuleObject.gathering == gathering)
            .delete()
        )
        return result

    def get_permission_available(self, module_code, action_code, object_code, filter_type_code):
        try:
            query = (
                DB.session.query(
                    CorModuleActionObjectFilter.label,
                    CorModuleActionObjectFilter.code,
                )
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
                .filter(TModules.module_code == module_code)
                .filter(TActions.code_action == action_code)
                .filter(TObjects.code_object == object_code)
                .filter(BibFiltersType.code_filter_type == filter_type_code)
            )
            result = query.one()
            data = {"label": result.label, "code": result.code}
        except exc.NoResultFound:
            log.warn(
                "Permission available not found for: "
                f"module={module_code}, "+
                f"action={action_code}, "+
                f"object={object_code}, "+
                f"filter_type={filter_type_code}. "
            )
            return False
        return data

    def get_all_personal_permissions(self, id_role, gatherings=None, limit_by_filter_code=None):
        query = (
            DB.session.query(
                CorRoleActionFilterModuleObject.id_role,
                CorModuleActionObjectFilter.label,
                CorModuleActionObjectFilter.code,
                TModules.module_code,
                TActions.code_action,
                TObjects.code_object,
                sa.cast(CorRoleActionFilterModuleObject.end_date, sa.Date),
                CorRoleActionFilterModuleObject.gathering,
                BibFiltersType.code_filter_type,
                CorRoleActionFilterModuleObject.value_filter
            )
            .select_from(CorRoleActionFilterModuleObject)
            .join(User, User.id_role == CorRoleActionFilterModuleObject.id_role)
            .join(CorModuleActionObjectFilter, sa.and_(
                CorModuleActionObjectFilter.id_module == CorRoleActionFilterModuleObject.id_module,
                CorModuleActionObjectFilter.id_action == CorRoleActionFilterModuleObject.id_action,
                CorModuleActionObjectFilter.id_object == CorRoleActionFilterModuleObject.id_object,
                CorModuleActionObjectFilter.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type,
            ))
            .join(
                TActions, 
                TActions.id_action == CorModuleActionObjectFilter.id_action
            )
            .join(
                TObjects, 
                TObjects.id_object == CorModuleActionObjectFilter.id_object
            )
            .join(TModules, TModules.id_module == CorRoleActionFilterModuleObject.id_module)
            .join(BibFiltersType, BibFiltersType.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type)
        )
        query = query.filter(User.id_role == id_role)
        if gatherings:
            query = query.filter(CorRoleActionFilterModuleObject.gathering.in_(gatherings))
        if limit_by_filter_code:
            query = query.filter(BibFiltersType.code_filter_type == limit_by_filter_code)
        return query.all()

    def create_permission(self, gathering, data):
        role_id = data["id_role"]
        module_id = self.get_module_id(data["module"])
        action_id = self.get_action_id(data["action"])
        object_id = self.get_object_id(data["object"])
        end_access_date = format_end_access_date(data["end_date"])
        
        # TODO: check if this permission with all this specific filters already exist

        # (Re)create permissions
        for key, val in data["filters"].items():
            if val != None:
                # Get filter type and value
                filter_type_id = self.get_filter_id(key)
                if key in ("geographic", "taxonomic"):
                    value_filter = build_value_filter_from_list(unduplicate_values(val))
                else: 
                    value_filter = val

                # (Re)create permission with same gathering
                permission = CorRoleActionFilterModuleObject(
                    gathering=gathering,
                    id_role=role_id,
                    id_module=module_id,
                    id_action=action_id,
                    id_object=object_id,
                    end_date=end_access_date,
                    id_filter_type=filter_type_id,
                    value_filter=value_filter
                )
                if not permission.is_already_exist():
                    DB.session.add(permission)

    def get_module_id(self, module_code):
        return (DB
            .session.query(TModules.id_module)
            .filter(TModules.module_code == module_code)
            .scalar()
        )

    def get_action_id(self, action_code):
        return (DB
            .session.query(TActions.id_action)
            .filter(TActions.code_action == action_code)
            .scalar()
        )

    def get_object_id(self, object_code):
        return (DB
            .session.query(TObjects.id_object)
            .filter(TObjects.code_object == object_code)
            .scalar()
        )

    def get_filter_id(self, filter_code):
        return (DB
            .session.query(BibFiltersType.id_filter_type)
            .filter(BibFiltersType.code_filter_type == filter_code.upper())
            .scalar()
        )
    def get_module_objects(self, id_module):
        query = (
            DB.session.query(TObjects)
            .join(
                CorModuleActionObjectFilter, 
                CorModuleActionObjectFilter.id_object == TObjects.id_object,
            )
            .filter_by(id_module = id_module)
            
        )
        return query.all()