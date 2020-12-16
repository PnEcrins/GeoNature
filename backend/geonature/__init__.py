"""
    Configuration du logger racine
"""
import logging
from geonature.utils.env import load_config, DEFAULT_CONFIG_FILE

conf = load_config(DEFAULT_CONFIG_FILE)
root_logger = logging.getLogger()
root_logger.addHandler(logging.StreamHandler())
root_logger.setLevel(conf["SERVER"]["LOG_LEVEL"])


from .server import create_app
