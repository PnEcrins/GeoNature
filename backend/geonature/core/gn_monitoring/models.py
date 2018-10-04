'''
    Modèles du schéma gn_monitoring
    Correspond a la centralisation des données de base
        relatifs aux protocoles de suivis
'''

from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import select, func

from geoalchemy2 import Geometry

from geonature.utils.utilssqlalchemy import (
    serializable, geoserializable
)
from geonature.utils.env import DB
from geonature.core.users.models import TRoles, TApplications


corVisitObserver = DB.Table(
    'cor_visit_observer',
    DB.MetaData(schema='gn_monitoring'),
    DB.Column(
        'id_base_visit',
        DB.Integer,
        ForeignKey('gn_monitoring.cor_visit_observer.id_base_visit'),
        primary_key=True
    ),
    DB.Column(
        'id_role',
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=True
    )
)

corSiteApplication = DB.Table(
    'cor_site_application',
    DB.MetaData(schema='gn_monitoring'),
    DB.Column(
        'id_base_site',
        DB.Integer,
        ForeignKey('gn_monitoring.cor_site_application.id_base_site'),
        primary_key=True
    ),
    DB.Column(
        'id_application',
        DB.Integer,
        ForeignKey('utilisateurs.t_applications.id_application'),
        primary_key=True
    )
)

corSiteArea = DB.Table(
    'cor_site_area',
    DB.MetaData(schema='gn_monitoring'),
    DB.Column(
        'id_base_site',
        DB.Integer,
        ForeignKey('gn_monitoring.cor_site_application.id_base_site'),
        primary_key=True
    ),
    DB.Column(
        'id_area',
        DB.Integer,
        ForeignKey('ref_geo.l_areas.id_area'),
        primary_key=True
    )
)


@serializable
class TBaseVisits(DB.Model):
    '''
        Table de centralisation des visites liées à un site
    '''
    __tablename__ = 't_base_visits'
    __table_args__ = {'schema': 'gn_monitoring'}
    id_base_visit = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(
        DB.Integer,
        ForeignKey('gn_monitoring.t_base_sites.id_base_site')
    )
    id_digitiser = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role')
    )

    visit_date_min = DB.Column(DB.DateTime)
    visit_date_max = DB.Column(DB.DateTime)
    # geom = DB.Column(Geometry('GEOMETRY', 4326))
    comments = DB.Column(DB.DateTime)
    uuid_base_visit = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()])
    )

    digitiser = relationship("TRoles", foreign_keys=[id_digitiser])

    observers = DB.relationship(
        'TRoles',
        secondary=corVisitObserver,
        primaryjoin=(
            corVisitObserver.c.id_base_visit == id_base_visit
        ),
        secondaryjoin=(corVisitObserver.c.id_role == TRoles.id_role),
        foreign_keys=[
            corVisitObserver.c.id_base_visit,
            corVisitObserver.c.id_role
        ]
    )


@serializable
@geoserializable
class TBaseSites(DB.Model):
    '''
        Table centralisant les données élémentaire des sites
    '''
    __tablename__ = 't_base_sites'
    __table_args__ = {'schema': 'gn_monitoring'}
    id_base_site = DB.Column(DB.Integer, primary_key=True)
    id_inventor = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role')
    )
    id_digitiser = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role')
    )
    id_nomenclature_type_site = DB.Column(DB.Integer)
    base_site_name = DB.Column(DB.Unicode)
    base_site_description = DB.Column(DB.Unicode)
    base_site_code = DB.Column(DB.Unicode)
    first_use_date = DB.Column(DB.DateTime)
    geom = DB.Column(Geometry('GEOMETRY', 4326))
    uuid_base_site = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()])
    )

    digitiser = relationship("TRoles", foreign_keys=[id_digitiser])
    inventor = relationship("TRoles", foreign_keys=[id_digitiser])

    t_base_visits = relationship(
        "TBaseVisits",
        lazy='joined',
        cascade="all,delete-orphan"
    )

    applications = DB.relationship(
        'TApplications',
        secondary=corSiteApplication,
        primaryjoin=(
            corSiteApplication.c.id_base_site == id_base_site
        ),
        secondaryjoin=(
            corSiteApplication.c.id_application == TApplications.id_application
        ),
        foreign_keys=[
            corSiteApplication.c.id_base_site,
            corSiteApplication.c.id_application
        ]
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('geom_4326', 'id_base_site', recursif)
