import {
  Component,
  OnInit,
  Input,
  IterableDiffers,
  IterableDiffer
} from '@angular/core';
import { Observable } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { DataFormService } from '../data-form.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

/**
 *  Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des jeux de données sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_datasets`` et ``gn_meta.cor_dataset_actor``)
 *
 * @example
 * <pnx-datasets
 * [idAcquisitionFrameworks]="formService.searchForm.controls.id_acquisition_frameworks.value"
 * [multiSelect]='true'
 *  [displayAll]="true"
 * [parentFormControl]="formService.searchForm.controls.id_dataset"
 * label="{{ 'MetaData.Datasets' | translate}}"
 * </pnx-datasets>
 */
@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})
export class DatasetsComponent extends GenericFormComponent implements OnInit {
  public dataSets: Observable<any>;
  @Input() idAcquisitionFrameworks: Array<number> = [];
  /**
   *  Permet de filtrer les JDD en fonction de l'ID cadre d'acqusition. A connecter avec le formControl du composant ``pnx-acquisition-framework``.
   *  Utiliser cet Input lorsque le composant ``pnx-acquisition-framework`` est en mode select simple.
   */
  @Input() idAcquisitionFramework: number;
  /**
   * Est-ce que le composant doit afficher l'item "tous" dans les options du select ? (facultatif)
   */
  @Input() bindAllItem: boolean = false;
  /**
   * Booléan qui controle si on affiche seulement les JDD actifs ou également ceux qui sont inatif
   */
  @Input() displayOnlyActive: boolean = true;
  /**
   * code du module pour n'afficher que les JDD associés au module
   */
  @Input() moduleCode: string;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
    private _iterableDiffers: IterableDiffers
  ) {
    super();
  }

  ngOnInit() {
    this.getDatasets();
  }

  getDatasets(params?) {
    params = {};

    if (this.displayOnlyActive) {
      params['active'] = true;
    }

    if (this.moduleCode) {
      params['module_code'] = this.moduleCode;
    }

    this.dataSets = this._dfs.getDatasets(params)
      .pipe(
        map(
          res => {
            if (res['with_mtd_errors']) {
              this._commonService.translateToaster('error', 'MetaData.JddErrorMTD');
            }
            const c = new Intl.Collator();
            return res.data.sort((a,b)=> c.compare(a.dataset_name, b.dataset_name));
          },
          error => {
            if (error.status === 500) {
              this._commonService.translateToaster('error', 'MetaData.JddError');
            } else if (error.status === 404) {
              if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
                this._commonService.translateToaster('warning', 'MetaData.NoJDDMTD');
              } else {
                this._commonService.translateToaster('warning', 'MetaData.NoJDD');
              }
            }
          }
        ),
        tap(datasets=>this.valueLoaded.emit({ value: datasets }))
      );
  }
}
