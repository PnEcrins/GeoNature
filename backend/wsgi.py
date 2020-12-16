"""
    Give a unique entry point for gunicorn
"""

import warnings
from sqlalchemy import exc as sa_exc

from geonature.utils.env import load_config, get_config_file_path
from geonature.utils.proxy import ReverseProxied
from geonature import create_app


# get the app config file
config_path = get_config_file_path()
config = load_config(config_path)


with warnings.catch_warnings():
    # filter sqlalchemy warning
    warnings.simplefilter("ignore", category=sa_exc.SAWarning)
    app = create_app(config)
    app.wsgi_app = ReverseProxied(app.wsgi_app, script_name=app.config["API_ENDPOINT"])
