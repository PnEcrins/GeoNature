import { Inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HttpClient, HttpParams } from '@angular/common/http';

import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
import { IRolePermission, IPermissionRequest, IModule, IActionObject, IFilter, IFilterValue, IObject } from './permission.interface'


@Injectable()
export class PermissionService {

  constructor(
    @Inject(APP_CONFIG_TOKEN) private cfg,
    private http: HttpClient,
  ) {}

  getBreadcrumbsRoot() {
    return [
      {
        label: 'Accueil',
        iconClass: 'home',
        title: "Accueil de GeoNature.",
        url: '/'
      },
      {
        label: 'Admin',
        iconClass: 'settings',
        title: "Accueil de l'administration de GeoNature.",
        url: '/admin'
      },
    ];
  }

  sendAccessRequest(data: any): Observable<any> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/access_requests`;
    return this.http.post<any>(url, data);
  }

  getAllRoles(): Observable<IRolePermission[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/roles`;
    return this.http.get<IRolePermission[]>(url);
  }

  getRoleById(id: number, params: HttpParams = null): Observable<IRolePermission> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/roles/${id}`;
    let options = {
      'params': (params ? params : null),
    }
    console.log("Options: ", options)
    return this.http.get<IRolePermission>(url, options);
  }

  deletePermission(gathering: string): Observable<boolean> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/${gathering}`;
    return this.http.delete<boolean>(url);
  }

  getObjects(): Observable<IObject[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/objects`;
    return this.http.get<IObject[]>(url);
  }

  getModules(codes: string[] = []): Observable<IModule[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/modules`;
    console.log('Codes:', codes)
    let params = null;
    if (codes.length > 0) {
      params = new HttpParams().set('codes', codes.join(','));
    }
    return this.http.get<IModule[]>(url, {params: params});
  }

  getActionsObjects(module: string = ''): Observable<IActionObject[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/availables/actions-objects`;
    let params = null;
    if (module) {
      params = new HttpParams().set('module', module);
    }
    return this.http.get<IActionObject[]>(url, {params: params});
  }

  getActionsObjectsFilters(actionObj: IActionObject): Observable<IFilter[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/availables/actions-objects-filters`;
    let params = null;
    if (actionObj) {
      params = new HttpParams()
        .set('module', actionObj.moduleCode)
        .set('action', actionObj.actionCode)
        .set('object', actionObj.objectCode);
    }
    return this.http.get<IFilter[]>(url, {params: params});
  }

  getFiltersValues(): Observable<Record<string, IFilterValue[]>> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/filters-values`;
    return this.http.get<Record<string, IFilterValue[]>>(url);
  }

  addPermission(data: any): Observable<any> {
    const url = `${this.cfg.API_ENDPOINT}/permissions`;
    return this.http.post<any>(url, data);
  }

  updatePermission(data: any): Observable<any> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/${data.gathering}`;
    return this.http.put<any>(url, data);
  }

  getAllProcessedRequests(): Observable<IPermissionRequest[]> {
    const params = new HttpParams().set('state', 'processed');
    return this.getAllRequests(params)
  }

  getAllPendingRequests(): Observable<IPermissionRequest[]> {
    const params = new HttpParams().set('state', 'pending');
    return this.getAllRequests(params)
  }

  private getAllRequests(params: HttpParams): Observable<IPermissionRequest[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests`;
    return this.http.get<IPermissionRequest[]>(url, {params: params});
  }

  getRequestByToken(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.get<IPermissionRequest>(url);
  }

  acceptRequest(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.patch<IPermissionRequest>(url, {'processedState': 'accepted'});
  }

  pendingRequest(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.patch<IPermissionRequest>(url, {'processedState': 'pending'});
  }

  refuseRequest(request: IPermissionRequest): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${request.token}`;
    request.processedState = 'refused';
    return this.http.patch<IPermissionRequest>(url, request);
  }
}
