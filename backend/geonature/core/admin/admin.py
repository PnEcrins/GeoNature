from flask import current_app
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.menu import MenuLink
from geonature.utils.env import DB

from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdminConfig,
    BibNomenclaturesTypesAdmin,
    TNomenclaturesAdminConfig,
    TNomenclaturesAdmin,
)


class MyHomeView(AdminIndexView):
    @expose("/")
    def index(self):
        admin_modules = []
        already_added_categie = []
        # get all different categories to generate friendly home page
        for v in self.admin._views:
            category = {"module_name": None, "module_views": []}
            if v.category:
                if v.category not in already_added_categie:
                    category["module_name"] = v.category
                    category["module_views"].append(
                        {"url": current_app.config["API_ENDPOINT"] + v.url, "name": v.name,}
                    )
                    already_added_categie.append(v.category)
                else:
                    for m in admin_modules:
                        if m["module_name"] == v.category:
                            m["module_views"].append(
                                {
                                    "url": current_app.config["API_ENDPOINT"] + v.url,
                                    "name": v.name,
                                }
                            )
                admin_modules.append(category)
        return self.render("admin_home.html", admin_modules=admin_modules)


admin = Admin(
    current_app,
    template_mode="bootstrap3",
    url="/admin",
    index_view=MyHomeView(
        name="Backoffice d'administration de GeoNature",
        url="/admin",
        menu_icon_type="glyph",
        menu_icon_value="glyphicon-home",
    ),
    base_template="my_master.html",
)

admin.add_view(
    BibNomenclaturesTypesAdminConfig(
        BibNomenclaturesTypesAdmin,
        DB.session,
        name="Type de nomenclatures",
        category="Nomenclatures",
    )
)

admin.add_view(
    TNomenclaturesAdminConfig(
        TNomenclaturesAdmin, DB.session, name="Items de nomenclatures", category="Nomenclatures",
    )
)
