"""
Démarrage de l'application
"""

import logging
from importlib import import_module

from flask import Flask
from flask_mail import Mail, Message
from flask_cors import CORS
from sqlalchemy import exc as sa_exc
from flask_sqlalchemy import before_models_committed

from geonature.utils.env import DB, MA, list_and_import_gn_modules


MAIL = Mail()


def get_enabled_blueprints(app, with_external_mods):
    '''
        Génère une liste de tuple (blueprint, /url_prefix)
        Le premier élément est soit directement un blueprint, soit
        une chaine de texte indiquant où trouver le blueprint à importer.
    '''
    yield from [
        ("pypnusershub.routes.routes", "/auth"),
        ("pypn_habref_api.routes.routes", "/habref"),
        ("pypnusershub.routes_register.bp", "/pypn/register"),
        ("pypnnomenclature.routes.routes", "/nomenclatures"),
        ("geonature.core.gn_permissions.routes.routes", "/permissions"),
        ("geonature.core.gn_permissions.backoffice.views.routes", "/permissions_backoffice"),
        ("geonature.core.users.routes.routes", "/users"),
        ("geonature.core.gn_synthese.routes.routes", "/synthese"),
        ("geonature.core.gn_meta.routes.routes", "/meta"),
        ("geonature.core.ref_geo.routes.routes", "/geo"),
        ("geonature.core.gn_exports.routes.routes", "/exports"),
        ("geonature.core.auth.routes.routes", "/gn_auth"),
        ("geonature.core.gn_monitoring.routes.routes", "/gn_monitoring"),
        ("geonature.core.gn_commons.routes.routes", "/gn_commons"),
    ]
    if app.config['DEBUG'] or True:
        yield ("geonature.core.routes.routes", "")
    # Loading third-party modules
    if with_external_mods:
        for conf, manifest, module in list_and_import_gn_modules(app):
            yield (module.backend.blueprint.blueprint, conf["MODULE_URL"])


def create_app(config, with_external_mods=True, with_flask_admin=True):
    app = Flask(__name__)
    app.config.update(config)

    # Bind app to DB
    DB.init_app(app)

    # For deleting files on "delete" media
    @before_models_committed.connect_via(app)
    def on_before_models_committed(sender, changes):
        for obj, change in changes:
            if change == "delete" and hasattr(obj, "__before_commit_delete__"):
                obj.__before_commit_delete__()

    # Bind app to MA
    MA.init_app(app)

    # Bind app to MAIL
    if app.config["MAIL_CONFIG"]:
        app.config.update(app.config["MAIL_CONFIG"])
        MAIL.init_app(app)

    # Enable CORS protection
    CORS(app, supports_credentials=True)

    # Pass parameters to the usershub authenfication sub-module, DONT CHANGE THIS
    app.config["DB"] = DB
    # Pass parameters to the submodules
    app.config["MA"] = MA
    # Pass the ID_APP to the submodule to avoid token conflict between app on the same server
    app.config["ID_APP"] = app.config["ID_APPLICATION_GEONATURE"]

    with app.app_context():
        if app.config["MAIL_ON_ERROR"] and app.config["MAIL_CONFIG"]:
            from geonature.utils.logs import mail_handler
            logging.getLogger().addHandler(mail_handler)
        # DB.create_all()

        if with_flask_admin:
            import geonature.core.admin

        for blueprint, url_prefix in get_enabled_blueprints(app, with_external_mods):
            if type(blueprint) == str:
                module_name, blueprint_name = blueprint.rsplit('.', 1)
                module = import_module(module_name)
                blueprint = getattr(module, blueprint_name)
            app.register_blueprint(blueprint, url_prefix=url_prefix)

    return app
