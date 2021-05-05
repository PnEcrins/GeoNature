import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent
} from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { Taxon } from './taxonomy/taxonomy.component';
import { Observable } from 'rxjs';

/** Interface for queryString parameters*/
interface ParamsDict {
  [key: string]: any;
}

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip']
]);

@Injectable()
export class DataFormService {
  private _blob: Blob;
  constructor(private _http: HttpClient) { }

  getNomenclature(
    codeNomenclatureType: string,
    regne?: string,
    group2_inpn?: string,
    filters?: any
  ) {
    let params: HttpParams = new HttpParams();
    regne ? (params = params.set('regne', regne)) : (params = params.set('regne', ''));
    group2_inpn
      ? (params = params.set('group2_inpn', group2_inpn))
      : (params = params.set('group2_inpn', ''));
    if (filters['orderby']) {
      params = params.set('orderby', filters['orderby']);
    }
    if (filters['order']) {
      params = params.set('order', filters['order']);
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/nomenclatures/nomenclature/${codeNomenclatureType}`,
      { params: params }
    );
  }

  getNomenclatures(codesNomenclatureType: Array<string>) {
    let params: HttpParams = new HttpParams();
    params = params.set('orderby', 'label_default');
    codesNomenclatureType.forEach(code => {
      params = params.append('code_type', code);
    });

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/nomenclatures/nomenclatures`, {
      params: params
    });
  }

  getDefaultNomenclatureValue(path, mnemoniques: Array<string> = [], kwargs: ParamsDict = {}) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (const key in kwargs) {
      queryString = queryString.set(key, kwargs[key].toString());
    }
    mnemoniques.forEach(mnem => {
      queryString = queryString.append('mnemonique', mnem);
    });
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/${path}/defaultNomenclatures`, {
      params: queryString
    });
  }

  getDatasets(params?: ParamsDict, orderByName = true, recursif = false) {
    let queryString: HttpParams = new HttpParams();
    queryString = this.addOrderBy(queryString, 'dataset_name');
    queryString = queryString.set('recursif', recursif.toString())

    if (params) {
      for (const key in params) {
        if (key === 'idOrganism') {
          queryString = queryString.set('organisme', params[key]);
          // is its an array of id_af
        } else if (key === 'id_acquisition_frameworks') {
          params[key].forEach(id_af => {
            queryString = queryString.append('id_acquisition_framework', id_af);
          });
        } else {
          queryString = queryString.set(key, params[key].toString());
        }
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/datasets`, {
      params: queryString
    });
  }

  /**
   * Get dataset list for metadata modules
   */
  getAfAndDatasetListMetadata(searchTerms) {

    let queryString = new HttpParams();
    for (let key in searchTerms) {
      queryString = queryString.set(key, searchTerms[key])
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/meta/af_datasets_metadata`,
      { params: queryString }
    );
  }

  getImports(id_dataset) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/import/by_dataset/${id_dataset}`);
  }

  getObservers(idMenu) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/menu/${idMenu}`);
  }

  getObserversFromCode(codeList) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/menu_from_code/${codeList}`);
  }

  autocompleteTaxon(api_endpoint: string, searh_name: string, params?: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    queryString = queryString.set('search_name', searh_name);
    for (let key in params) {
      if (params[key]) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<Taxon[]>(`${api_endpoint}`, {
      params: queryString
    });
  }

  getTaxonInfo(cd_nom: number) {
    return this._http.get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`);
  }

  getTaxonAttributsAndMedia(cd_nom: number, id_attributs?: Array<number>) {
    let query_string = new HttpParams();
    if (id_attributs) {
      id_attributs.forEach(id => {
        query_string = query_string.append('id_attribut', id.toString());
      });
    }

    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibnoms/taxoninfo/${cd_nom}`, {
      params: query_string
    });
  }

  async getTaxonInfoSynchrone(cd_nom: number): Promise<any> {
    const response = await this._http
      .get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`)
      .toPromise();
    return response;
  }

  getHigherTaxa(rank: string, search?) {
    let params: HttpParams = new HttpParams();
    params = params.set('rank_limit', rank);
    params = params.set('fields', 'lb_auteur,nom_complet_html');

    let url = `${AppConfig.API_TAXHUB}/taxref/search/lb_nom`
    if (search) {
      url = `${url}/${search}`
    }

    return this._http.get<any>(url, { params: params })
      .map(data => {
        return data.map(item => {
          return this.formatSciname(item);
        })
      });
  }

  /**
   * Met en gras les noms scientifiques retenus.
   * @param item Objet correspondant au nom scientifique. Doit contenir
   * les attributs "cd_nom", "cd_ref", "lb_nom", "lb_auteur" et "nom_complet_html".
   */
  formatSciname(item) {
    if (item['nom_complet_html'] === undefined && item['lb_nom'] !== undefined) {
      item.displayName = item['lb_nom'];
      if (item['lb_auteur']) {
        item.displayName += ` ${item['lb_auteur']}`;
      }
      return item;
    }

    item.displayName = item['nom_complet_html'];
    item.displayName = item.displayName.replace(
      item['lb_auteur'],
      `<span class="text-muted">${item['lb_auteur']}</span>`
    );
    if (item['cd_nom'] === item['cd_ref']) {
      if (item.displayName.includes('<i>')) {
        item.displayName = item.displayName.replaceAll('<i>', '<b><i>');
        item.displayName = item.displayName.replaceAll('</i>', '</i></b>');
      } else {
        item.displayName = item.displayName.replace(
          item['lb_nom'],
          `<b>${item['lb_nom']}</b>`
        );
      }
    }
    return item;
  }

  getRegneAndGroup2Inpn() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/regnewithgroupe2`);
  }

  getTaxhubBibAttributes() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibattributs/`);
  }

  getTaxonomyLR() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/bib_lr`);
  }

  getTaxonomyHabitat() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/bib_habitats`);
  }

  getTypologyHabitat(id_list: number) {
    let params = new HttpParams();

    if (id_list) {
      params = params.set('id_list', id_list.toString());
    }
    return this._http
      .get<any>(`${AppConfig.API_ENDPOINT}/habref/typo`, { params: params })
      .map(data => {
        // replace '_' with space because habref is super clean !
        return data.map(d => {
          d['lb_nom_typo'] = d['lb_nom_typo'].replace(/_/g, ' ');
          return d;
        });
      });
  }

  getHabitatInfo(cd_hab) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/habref/habitat/${cd_hab}`);
  }

  getGeoInfo(geojson) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/geo/info`, geojson);
  }

  getGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}/geo/areas`, geojson);
  }

  getAltitudes(geojson) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/geo/altitude`, geojson);
  }

  getFormatedGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}/geo/areas`, geojson).map(res => {
      const areasIntersected = [];
      Object.keys(res).forEach(key => {
        const typeName = res[key]['type_name'];
        const areas = res[key]['areas'];
        const formatedAreas = areas.map(area => area.area_name).join(', ');
        const obj = {
          type_name: typeName,
          areas: formatedAreas
        };
        areasIntersected.push(obj);
      });
      return areasIntersected;
    });
  }

  getAreaSize(geojson) {
    return this._http.post<number>(`${AppConfig.API_ENDPOINT}/geo/area_size`, geojson);
  }

  getMunicipalities(nom_com?, limit?) {
    let params: HttpParams = new HttpParams();

    if (nom_com) {
      params = params.set('nom_com', nom_com);
    }
    if (limit) {
      params = params.set('limit', limit);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/municipalities`, { params: params });
  }

  getAreas(area_type_list: Array<number>, area_name?) {
    let params: HttpParams = new HttpParams();

    area_type_list.forEach(id_type => {
      params = params.append('id_type', id_type.toString());
    });

    if (area_name) {
      params = params.set('area_name', area_name);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, { params: params });
  }

  getValidationHistory(uuid_attached_row) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/gn_commons/history/${uuid_attached_row}`,
      {}
    );
  }

  /**
   *
   * @param params: dict of paramters
   * @param orderByName :default true
   */
  getAcquisitionFrameworks(params?: ParamsDict, orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'acquisition_framework_name');
    }
    if (params) {
      // tslint:disable-next-line:forin
      for (let key in params) {
        if (params[key] !== null) {
          queryString = queryString.set(key, params[key]);
        }
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks`, {
      params: queryString
    });
  }

  /**
   * Return all AF with cruved for map-list
   */
  getAcquisitionFrameworksMetadata(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'acquisition_framework_name');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks_metadata`, {
      params: queryString
    });
  }

  getAcquisitionFramework(id_af) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}`);
  }

  getAcquisitionFrameworkDetails(id_af) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/meta/acquisition_framework_details/${id_af}`
    );
  }

  getOrganisms(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms`, {
      params: queryString
    });
  }

  getOrganismsDatasets(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms_dataset_actor`, {
      params: queryString
    });
  }

  getRole(id: number) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/role/${id}`);
  }

  getRoles(params?: ParamsDict, orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_role');
    }
    // tslint:disable-next-line:forin
    for (let key in params) {
      if (params[key] !== null) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/roles`, { params: queryString });
  }

  getDataset(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id}`);
  }

  getDatasetDetails(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/dataset_details/${id}`);
  }

  // getTaxaDistribution(id_dataset) {
  //   return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/dataset_taxa_distribution/${id_dataset}`);
  // }
  getGeojsonData(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/geojson_data/${id}`);
  }

  getRepartitionTaxons(id_dataset) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/synthese/repartition_taxons_dataset/${id_dataset}`
    );
  }

  getTaxaDistribution(taxa_rank, params?: ParamsDict) {
    let queryString = new HttpParams();
    queryString = queryString.set('taxa_rank', taxa_rank);
    for (let key in params) {
      queryString = queryString.set(key, params[key]);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/taxa_distribution`, {
      params: queryString
    });
  }

  getModulesList(exclude: Array<string> = []): Observable<Array<any>> {
    let queryString: HttpParams = new HttpParams();
    exclude.forEach(mod_code => {
      queryString = queryString.append('exclude', mod_code);
    });
    return this._http.get<Array<any>>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`, {
      params: queryString
    });
  }

  getModuleByCodeName(module_code): Observable<any> {
    console.log("WARNING: use moduleService.getModule(module_code) instead?");
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules/${module_code}`);
  }

  getCruved(modules_code?: Array<string>) {
    let queryString: HttpParams = new HttpParams();
    if (modules_code) {
      modules_code.forEach(mod_code => {
        queryString = queryString.set('module_code', mod_code);
      });
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/permissions/cruved`, {
      params: queryString
    });
  }

  addOrderBy(httpParam: HttpParams, order_column): HttpParams {
    return httpParam.append('orderby', order_column);
  }

  getDataList(api: string, application: string, params = {}) {
    let queryString: HttpParams = new HttpParams();
    for (const key of Object.keys(params)) {
      const param = params[key];
      if (Array.isArray(param)) {
        for (const p of param) {
          queryString = queryString.append(key, p);
        }
      } else {
        queryString = queryString.append(key, param);
      }
    }

    const url =
      application === 'GeoNature'
        ? `${AppConfig.API_ENDPOINT}/${api}`
        : application === 'TaxHub'
          ? `${AppConfig.API_TAXHUB}/${api}`
          : api;

    return this._http.get<any>(url, { params: queryString });
  }

  subscribeAndDownload(
    source: Observable<HttpEvent<Blob>>,
    fileName: string,
    format: string
  ): void {
    const subscription = source.subscribe(
      event => {
        if (event.type === HttpEventType.Response) {
          this._blob = new Blob([event.body], { type: event.headers.get('Content-Type') });
        }
      },
      (e: HttpErrorResponse) => {
        //this._commonService.translateToaster('error', 'ErrorMessage');
        //this.isDownloading = false;
      },
      // response OK
      () => {
        //this.isDownloading = false;
        const date = new Date();
        const extension = format === 'shapefile' ? 'zip' : format;
        this.saveBlob(this._blob, `${fileName}_${date.toISOString()}.${extension}`);
        subscription.unsubscribe();
      }
    );
  }

  saveBlob(blob, filename) {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('visibility', 'hidden');
    link.download = filename;
    link.onload = () => {
      URL.revokeObjectURL(link.href);
    };
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }


  //liste des lieux
  getPlaces() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/places`);
  }
  //Ajouter lieu
  addPlace(place) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/gn_commons/place`, place);
  }

  // Supprimer lieu
  deletePlace(idPlace) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/gn_commons/place/${idPlace}`);
  }
  deleteAf(af_id) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${af_id}`);
  }

  publishAf(af_id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/publish/${af_id}`);
  }

  deleteDs(ds_id) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${ds_id}`);
  }

}

