import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { AppConfig } from '@geonature_config/app.config';
import { Subject, Observable, of, concat } from 'rxjs';
import { distinctUntilChanged, debounceTime, switchMap, tap, catchError, map } from 'rxjs/operators'

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent extends GenericFormComponent implements OnInit {
  public cachedAreas: any;
  @Input() idTypes: Array<number>; // Areas id_type

  areas_input$ = new Subject<string>();
  areas: Observable<any>;
  loading = false;

  constructor(
    private _dfs: DataFormService, 
    private _commonService: CommonService
  ) {
    super();
  }

  ngOnInit() {
    this.getAreas();
  }

  getAreas() { 
    this.areas = concat(
        this._dfs.getAreas(this.idTypes).pipe(map(data=>this.formatAreas(data))), // default items
        this.areas_input$.pipe(
            debounceTime(200),
            distinctUntilChanged(),
            tap(() => this.loading = true),
            switchMap(term => {
              return term.length >= 2 ?
                this._dfs.getAreas(this.idTypes, term).pipe(
                  map(data=>this.formatAreas(data)),
                  catchError(() => of([])), // empty list on error
                  tap(() => this.loading = false)
                ) : [];
            }) 
        )
    );
  }

  /**
   * Set the departement number if the id_type is municipalities
   * @param data
   */
  formatAreas(data) {
    if (data.length > 0 && data[0]['id_type'] === AppConfig.BDD.id_area_type_municipality) {
      return data.map(element => {
        element['area_name'] = `${element['area_name']} (${element.area_code.substr(0, 2)}) `;
        return element;
      });
    } 

    return data;
  }
}
