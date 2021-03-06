import os
from collections import ChainMap

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import DEFAULT_CONFIG_FILE


config_path = os.environ.get("GEONATURE_CONFIG_FILE", DEFAULT_CONFIG_FILE)
config_backend = load_and_validate_toml(config_path, GnPySchemaConf)
config_frontend = load_and_validate_toml(config_path, GnGeneralSchemaConf)
config = ChainMap({}, config_frontend, config_backend)
