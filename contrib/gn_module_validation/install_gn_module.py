from pathlib import Path

from sqlalchemy.sql import text
import logging

ROOT_DIR = Path(__file__).absolute().parent
GEONATURE_DIR = ROOT_DIR.parent.parent

db_handler = logging.FileHandler(
    str(f"{GEONATURE_DIR}/var/log/install_validation.log"), mode="w"
)
db_handler.setLevel(logging.INFO)
db_logger = logging.getLogger("sqlalchemy")
db_logger.addHandler(db_handler)


def gnmodule_install_app(gn_db, gn_app):
    """
        Fonction principale permettant de réaliser les opérations d'installation du module.
    """
    with gn_app.app_context():
        script_install = str(f"{ROOT_DIR}/data/validation.sql")
        try:
            sql = open(script_install, "r").read()
            escaped_sql = text(sql)
            gn_db.engine.execute(
                escaped_sql.execution_options(autocommit=True),
                MYLOCALSRID=gn_app.config["LOCAL_SRID"]
            )
            gn_db.session.commit()
        except Exception as e:
            msg = f"Erreur à l'execution du script SQL d'installation du module Validation: {e}"
            db_logger.error(msg)
            raise RuntimeError(msg)
