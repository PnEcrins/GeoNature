import { Injectable } from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { MatSidenavModule, MatSidenav } from '@angular/material/sidenav';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class SideNavService {
  sidenav: MatSidenav;
  opened: boolean;
  private _module = new Subject<any>();
  public currentModule: any;
  gettingCurrentModule = this._module.asObservable();
  // List of the apps
  public modules: Array<any>;
  public home_page;
  public exportModule;

  constructor(private _api: HttpClient) {
    this.opened = false;
    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'fa-home', id: '1' };

    this.exportModule = {
      module_url: '/exports',
      module_label: 'Export',
      module_picto: 'fa-download',
      id: '2'
    };
  }

  fetchModules() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`);
  }

  setModulesLocalStorage(modules) {
    localStorage.setItem('modules', JSON.stringify(modules));
  }

  /**
   * Get a module from the localstorage
   * @param module_name: name of the module
   */
  getModule(module_name: string) {
    const modules = localStorage.getItem('modules');
    let searchModule = null;
    if (modules) {
      JSON.parse(modules).forEach(mod => {
        if (mod.module_name.toLocaleLowerCase() === module_name.toLocaleLowerCase()) {
          searchModule = mod;
        }
      });
    }
    return searchModule;
  }

  setSideNav(sidenav) {
    this.sidenav = sidenav;
  }
  setModule(sidenav: MatSidenav) {
    sidenav.close();
  }
  setHome(sidenav: MatSidenav) {
    sidenav.open();
  }

  setCurrentApp(app): any {
    this.currentModule = app;
    this._module.next(app);
  }

  getCurrentApp() {
    return this.currentModule;
  }
  getAppList(): any {
    return this.modules;
  }
}
