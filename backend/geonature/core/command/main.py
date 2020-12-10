"""
    Entry point for the command line 'geonature'
"""

import logging

import click

from geonature.utils.env import (
    DEFAULT_CONFIG_FILE,
    GEONATURE_VERSION,
)
from geonature.utils.command import (
    get_app_for_cmd,
    start_gunicorn_cmd,
    supervisor_cmd,
    start_geonature_front,
    build_geonature_front,
    create_frontend_config,
    frontend_routes_templating,
    tsconfig_templating,
    tsconfig_app_templating,
    update_app_configuration,
)

# from rq import Queue, Connection, Worker
# import redis
from flask import Flask


log = logging.getLogger()


@click.group()
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    pass


# Unused
# @main.command()
# def launch_redis_worker():
#     """ launch redis worker
#     """
#     app = get_app_for_cmd(DEFAULT_CONFIG_FILE)
#     with app.app_context():
#         with Connection(redis.Redis(host='localhost', port='6379')):
#             q = Queue()
#             w = Worker(q)
#             w.work()


@main.command()
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
@click.option("--build", type=bool, required=False, default=True)
def generate_frontend_config(conf_file, build):
    """
        Génération des fichiers de configurations pour javascript
        Relance le build du front par defaut
    """
    try:
        create_frontend_config(conf_file)
        if build:
            build_geonature_front()
        log.info("Config successfully updated")
    except FileNotFoundError:
        log.warning("file {} doesn't exists".format(conf_file))


@main.command()
@click.option("--uri", default="0.0.0.0:8000")
@click.option("--worker", default=4)
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
def start_gunicorn(uri, worker, config_file=None):
    """
        Lance l'api du backend avec gunicorn
    """
    start_gunicorn_cmd(uri, worker)


@main.command()
@click.option("--host", default="0.0.0.0")
@click.option("--port", default=8000)
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
def dev_back(host, port, conf_file):
    """
        Lance l'api du backend avec flask

        Exemples

        - geonature dev_back

        - geonature dev_back --port=8080 --port=0.0.0.0
    """
    app = get_app_for_cmd(conf_file)
    app.run(host=host, port=int(port), debug=True)


@main.command()
@click.option("--action", default="restart", type=click.Choice(["start", "stop", "restart"]))
@click.option("--app_name", default="geonature2")
def supervisor(action, app_name):
    """
        Lance les actions du supervisor
    """
    supervisor_cmd(action, app_name)


@main.command()
def dev_front():
    """
        Démarre le frontend en mode develop
    """
    start_geonature_front()


@click.option("--build-sass", type=bool, default=False)
@main.command()
def frontend_build(build_sass):
    """
        Lance le build du frontend
    """
    build_geonature_front(build_sass)


@main.command()
def generate_frontend_modules_route():
    """
        Génere le fichier de routing du frontend
        à partir des modules GeoNature activé
    """
    frontend_routes_templating()


@main.command()
def generate_frontend_tsconfig():
    """
        Génere tsconfig du frontend
    """
    tsconfig_templating()


@main.command()
def generate_frontend_tsconfig_app():
    """
        Génere tsconfig.app du frontend/src
    """
    tsconfig_app_templating()


@main.command()
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
@click.option("--build", type=bool, required=False, default=True)
@click.option("--prod", type=bool, required=False, default=True)
def update_configuration(conf_file, build, prod):
    """
        Regénère la configuration de l'application

        Example:

        - geonature update_configuration

        - geonature update_configuration --build=false (met à jour la configuration sans recompiler le frontend)

    """
    # Recréation du fichier de routing car il dépend de la conf
    frontend_routes_templating()
    update_app_configuration(conf_file, build, prod)
