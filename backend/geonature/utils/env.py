""" Helpers to manipulate the execution environment """

import os
import subprocess
import sys

from pathlib import Path
from collections import ChainMap, namedtuple

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm.exc import NoResultFound
from flask_marshmallow import Marshmallow

# Define GEONATURE_VERSION before import config_shema module
# because GEONATURE_VERSION is imported in this module
ROOT_DIR = Path(__file__).absolute().parent.parent.parent.parent
with open(str((ROOT_DIR / "VERSION"))) as v:
    GEONATURE_VERSION = v.read()
from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
    ManifestSchemaProdConf,
)
from geonature.utils.utilstoml import load_and_validate_toml

BACKEND_DIR = ROOT_DIR / "backend"
DEFAULT_CONFIG_FILE = ROOT_DIR / "config/geonature_config.toml"

DB = SQLAlchemy()

MA = Marshmallow()


GN_MODULE_FILES = (
    "manifest.toml",
    "__init__.py",
    "backend/__init__.py",
    "backend/blueprint.py",
)

GN_EXTERNAL_MODULE = ROOT_DIR / "external_modules"
GN_MODULE_FE_FILE = "frontend/app/gnModule.module"


def get_config_file_path(config_file=None):
    """ Return the config file path by checking several sources

        1 - Parameter passed
        2 - GEONATURE_CONFIG_FILE env var
        3 - Default config file value
    """
    config_file = config_file or os.environ.get("GEONATURE_CONFIG_FILE")
    return Path(config_file or DEFAULT_CONFIG_FILE)


def load_config(config_file=None):
    """ Load the geonature configuration from a given file """
    # load and validate configuration
    configs_py = load_and_validate_toml(str(get_config_file_path(config_file)), GnPySchemaConf)

    # Settings also exported to backend
    configs_gn = load_and_validate_toml(
        str(get_config_file_path(config_file)), GnGeneralSchemaConf
    )

    return ChainMap({}, configs_py, configs_gn)


def import_requirements(req_file):
    from geonature.utils.errors import GeoNatureError

    cmd_return = subprocess.call(["pip", "install", "-r", req_file])
    if cmd_return != 0:
        raise GeoNatureError("Error while installing module backend dependencies")


def list_and_import_gn_modules(app, mod_path=GN_EXTERNAL_MODULE):
    """
        Get all the module enabled from gn_commons.t_modules
        register the configuration and import the module programaticly
    """
    with app.app_context():
        from geonature.core.gn_commons.models import TModules

        modules = DB.session.query(TModules).filter(TModules.active_backend == True)
        module_info = {}
        enabled_modules_name = []
        for mod in modules:
            enabled_modules_name.append(mod.module_code)
            module_info[mod.module_code] = {
                "ID_MODULE": mod.id_module,
                "MODULE_URL": "/" + mod.module_path.replace(" ", ""),
                "MODULE_CODE": mod.module_code,
            }
    # iter over external_modules dir
    # and import only modules which are enabled
    for f in mod_path.iterdir():
        if f.is_dir():
            module_code = None
            try:
                conf_manifest = load_and_validate_toml(
                    str(f / "manifest.toml"), ManifestSchemaProdConf
                )
                # set module code upper because module call is always upper in gn_commons.t_modules
                module_code = conf_manifest["module_code"].upper()
            except Exception as e:
                print("Cant find the module, it will not be enable, {}".format(e))
            if module_code in enabled_modules_name:
                # import du module dans le sys.path
                module_path = Path(GN_EXTERNAL_MODULE / module_code.lower())
                module_parent_dir = str(module_path.parent)
                module_import_name = "{}.config.conf_schema_toml".format(module_path.name)
                sys.path.insert(0, module_parent_dir)
                module = __import__(module_import_name)
                # get and validate the module config

                class GnModuleSchemaProdConf(module.config.conf_schema_toml.GnModuleSchemaConf):
                    pass

                conf_module = load_and_validate_toml(
                    str(f / "config/conf_gn_module.toml"), GnModuleSchemaProdConf
                )

                # add id_module and url_path to the module config
                update_module_config = dict(conf_module, **module_info.get(module_code))
                # register the module conf in the app config
                app.config[module_code] = update_module_config

                # import the blueprint
                python_module_name = "{}.backend.blueprint".format(module_path.name)
                module_blueprint = __import__(python_module_name, globals=globals())
                # register the confif in bluprint.config
                module.backend.blueprint.blueprint.config = update_module_config
                sys.path.pop(0)

                yield update_module_config, conf_manifest, module_blueprint


def list_frontend_enabled_modules(app, mod_path=GN_EXTERNAL_MODULE):
    """
        Get all the module frontend enabled from gn_commons.t_modules
        and return the conf and the manifest
    """
    from geonature.core.gn_commons.models import TModules

    with app.app_context():
        enabled_modules = DB.session.query(TModules).filter(TModules.active_frontend == True).all()
        for mod in enabled_modules:
            yield mod.module_path.replace(" ", ""), mod.module_code
