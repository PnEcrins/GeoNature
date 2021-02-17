"""
Démarrage de l'application
"""

import logging

from flask import Flask
from flask_mail import Message
from flask_cors import CORS
from sqlalchemy import exc as sa_exc
from flask_sqlalchemy import before_models_committed

from geonature.utils.config import config
from geonature.utils.env import MAIL, DB, MA
from geonature.utils.module import import_backend_enabled_modules


def create_app(with_external_mods=True, with_flask_admin=True):
    app = Flask(__name__)
    app.config.update(config)

    # Bind app to DB
    DB.init_app(app)

    MAIL.init_app(app)

    # For deleting files on "delete" media
    @before_models_committed.connect_via(app)
    def on_before_models_committed(sender, changes):
        for obj, change in changes:
            if change == "delete" and hasattr(obj, "__before_commit_delete__"):
                obj.__before_commit_delete__()

    # Bind app to MA
    MA.init_app(app)

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
            # from geonature.core.admin import flask_admin
            from geonature.core.admin.admin import flask_admin

        from pypnusershub.routes import routes

        app.register_blueprint(routes, url_prefix="/auth")

        from pypn_habref_api.routes import routes

        app.register_blueprint(routes, url_prefix="/habref")

        from pypnusershub import routes_register

        app.register_blueprint(routes_register.bp, url_prefix="/pypn/register")

        from pypnnomenclature.routes import routes

        app.register_blueprint(routes, url_prefix="/nomenclatures")

        from geonature.core.gn_permissions.routes import routes

        app.register_blueprint(routes, url_prefix="/permissions")

        from geonature.core.routes import routes

        app.register_blueprint(routes, url_prefix="")

        from geonature.core.users.routes import routes

        app.register_blueprint(routes, url_prefix="/users")

        from geonature.core.gn_synthese.routes import routes

        app.register_blueprint(routes, url_prefix="/synthese")

        from geonature.core.gn_meta.routes import routes

        app.register_blueprint(routes, url_prefix="/meta")

        from geonature.core.ref_geo.routes import routes

        app.register_blueprint(routes, url_prefix="/geo")

        from geonature.core.gn_exports.routes import routes

        app.register_blueprint(routes, url_prefix="/exports")

        from geonature.core.auth.routes import routes

        app.register_blueprint(routes, url_prefix="/gn_auth")

        from geonature.core.gn_monitoring.routes import routes

        app.register_blueprint(routes, url_prefix="/gn_monitoring")

        from geonature.core.gn_commons.routes import routes

        app.register_blueprint(routes, url_prefix="/gn_commons")

        # Errors
        from geonature.core.errors import routes

        CORS(app, supports_credentials=True)

        # Emails configuration
        if app.config["MAIL_CONFIG"]:
            conf = app.config.copy()
            conf.update(app.config["MAIL_CONFIG"])
            app.config = conf
            MAIL.init_app(app)

        app.config['TEMPLATES_AUTO_RELOAD'] = True
        # disable cache for downloaded files (PDF file stat for ex)
        app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

        # Loading third-party modules
        if with_external_mods:
            for module, blueprint in import_backend_enabled_modules():
                app.config[blueprint.config['MODULE_CODE']] = blueprint.config
                app.register_blueprint(blueprint, url_prefix=blueprint.config['MODULE_URL'])
        _app = app
    return app
