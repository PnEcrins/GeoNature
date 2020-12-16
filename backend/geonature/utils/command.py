"""   
    Fichier de création des commandes geonature
    Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
    dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
    d'administration de l'application GeoNature (génération des fichiers de configuration, des 
    fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si 
    un paquet PIP du requirement GeoNature n'a pas été bien installé
"""
import sys
import logging
import subprocess
import json

from jinja2 import Template
from pathlib import Path

from geonature import create_app
from geonature.utils.env import (
    BACKEND_DIR,
    ROOT_DIR,
    GN_MODULE_FE_FILE,
    load_config,
    get_config_file_path,
    DB,
    GN_EXTERNAL_MODULE,
)
from geonature.utils.errors import ConfigError
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import GnGeneralSchemaConf

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"


def start_gunicorn_cmd(uri, worker):
    cmd = "gunicorn server:app -w {gun_worker} -b {gun_uri}"
    subprocess.call(cmd.format(gun_worker=worker, gun_uri=uri).split(" "), cwd=str(BACKEND_DIR))


def get_app_for_cmd(config_file=None, with_external_mods=True, with_flask_admin=True):
    """ Return the flask app object, logging error instead of raising them"""
    try:
        conf = load_config(config_file)
        conf.update({'DEBUG': True})
        return create_app(
            conf, with_external_mods=with_external_mods, with_flask_admin=with_flask_admin,
        )
    except ConfigError as e:
        log.critical("%s \n" % e)
        sys.exit(1)


def supervisor_cmd(action, app_name):
    cmd = "sudo supervisorctl {action} {app}"
    subprocess.call(cmd.format(action=action, app=app_name).split(" "))


def start_geonature_front():
    subprocess.call(["npm", "run", "start"], cwd=str(ROOT_DIR / "frontend"))


def build_geonature_front(rebuild_sass=False):
    if rebuild_sass:
        subprocess.call(["npm", "rebuild", "node-sass", "--force"], cwd=str(ROOT_DIR / "frontend"))
    subprocess.call(["npm", "run", "build"], cwd=str(ROOT_DIR / "frontend"))


def frontend_routes_templating(app=None):
    if not app:
        app = get_app_for_cmd(with_external_mods=False)

    log.info("Generating frontend routing")
    # recuperation de la configuration
    configs_gn = load_config(get_config_file_path())

    from geonature.utils.env import list_frontend_enabled_modules

    with open(
        str(ROOT_DIR / "frontend/src/app/routing/app-routing.module.ts.sample"), "r"
    ) as input_file:
        template = Template(input_file.read())
        routes = []
        for url_path, module_code in list_frontend_enabled_modules(app):
            location = Path(GN_EXTERNAL_MODULE / module_code.lower())

            # test if module have frontend
            if (location / "frontend").is_dir():
                path = url_path.lstrip("/")
                location = "{}/{}#GeonatureModule".format(location, GN_MODULE_FE_FILE)
                routes.append({"path": path, "location": location, "module_code": module_code})

            # TODO test if two modules with the same name is okay for Angular

        route_template = template.render(
            routes=routes,
            enable_user_management=configs_gn["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT"),
            enable_sign_up=configs_gn["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP"),
        )

        with open(
            str(ROOT_DIR / "frontend/src/app/routing/app-routing.module.ts"), "w"
        ) as output_file:
            output_file.write(route_template)

    log.info("...%s\n", MSG_OK)


def tsconfig_templating():
    log.info("Generating tsconfig.json")
    with open(str(ROOT_DIR / "frontend/tsconfig.json.sample"), "r") as input_file:
        template = Template(input_file.read())
        tsconfig_templated = template.render(geonature_path=ROOT_DIR)

    with open(str(ROOT_DIR / "frontend/tsconfig.json"), "w") as output_file:
        output_file.write(tsconfig_templated)
    log.info("...%s\n", MSG_OK)


def tsconfig_app_templating(app=None):
    if not app:
        app = get_app_for_cmd(with_external_mods=False)
    log.info("Generating tsconfig.app.json")
    from geonature.utils.env import list_frontend_enabled_modules

    with open(str(ROOT_DIR / "frontend/src/tsconfig.app.json.sample"), "r") as input_file:
        template = Template(input_file.read())
        routes = []
        for url_path, module_code in list_frontend_enabled_modules(app):
            location = Path(GN_EXTERNAL_MODULE / module_code.lower())

            # test if module have frontend
            if (location / "frontend").is_dir():
                location = "{}/frontend/app".format(location)
                routes.append({"location": location})

            # TODO test if two modules with the same name is okay for Angular

        route_template = template.render(routes=routes)

        with open(str(ROOT_DIR / "frontend/src/tsconfig.app.json"), "w") as output_file:
            output_file.write(route_template)

    log.info("...%s\n", MSG_OK)


def create_frontend_config(conf_file):
    log.info("Generating configuration")
    configs_gn = load_and_validate_toml(conf_file, GnGeneralSchemaConf)

    with open(str(ROOT_DIR / "frontend/src/conf/app.config.ts"), "w") as outputfile:
        outputfile.write("export const AppConfig = ")
        json.dump(configs_gn, outputfile, indent=True)
    log.info("...%s\n", MSG_OK)


def update_app_configuration(conf_file, build=True, prod=True):
    log.info("Update app configuration")
    if prod:
        subprocess.call(["sudo", "supervisorctl", "reload"])
    create_frontend_config(conf_file)
    if build:
        subprocess.call(["npm", "run", "build"], cwd=str(ROOT_DIR / "frontend"))
    log.info("...%s\n", MSG_OK)
