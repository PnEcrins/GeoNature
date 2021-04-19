import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { AppConfig } from '@geonature_config/app.config';
import { FormArray } from '@angular/forms/src/model';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataFormService } from '../services/metadata-form.service';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-form.component.html',
  styleUrls: ['./dataset-form.scss'],
  providers: [MetadataFormService]
})
export class DatasetFormComponent implements OnInit {
  public datasetForm: FormGroup;
  public acquisitionFrameworks: any;
  public organisms: Array<any>;
  public roles: Array<any>;
  public cor_dataset_actor: FormGroup;
  public cor_dataset_actor_array: FormArray;
  public id_dataset: number;
  public dataset: any;

  constructor(
    private _fb: FormBuilder,
    private _api: HttpClient,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _dfs: DataFormService,
    private _formService: MetadataFormService,
    public moduleService: ModuleService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getDataset(this.id_dataset);
      }
    });
    this.datasetForm = this._fb.group({
      id_acquisition_framework: [null, Validators.required],
      id_dataset: null,
      dataset_name: [null, Validators.compose([Validators.required, Validators.maxLength(150)])],
      dataset_shortname: [
        null,
        Validators.compose([Validators.required, Validators.maxLength(30)])
      ],
      dataset_desc: [null, Validators.required],
      id_nomenclature_data_type: [null, Validators.required],
      keywords: null,
      terrestrial_domain: true,
      marine_domain: false,
      id_nomenclature_dataset_objectif: [null, Validators.required],
      //TODO bouding-box
      id_nomenclature_collecting_method: [null, Validators.required],
      id_nomenclature_data_origin: [null, Validators.required],
      id_nomenclature_source_status: [null, Validators.required],
      id_nomenclature_resource_type: [null, Validators.required],
      validable: true,
      active: [true, Validators.required],
      modules: [new Array()]
    });

    this.cor_dataset_actor_array = this._fb.array([]);

    this.getAF();

    this.cor_dataset_actor_array.push(this._formService.generateCorDatasetActorForm());
  }

  addFormArray(): void {
    this.cor_dataset_actor_array.push(this._formService.generateCorDatasetActorForm());
  }

  getAF() {
    this.acquisitionFrameworks = this._dfs.getAcquisitionFrameworks()
                                          .pipe(
                                            map(data => data.filter(af => af.opened === true))
                                          );
  }

  getDataset(id) {
    // on edition mode
    this._dfs.getDataset(id).subscribe(data => {
      this.dataset = data;
      this.datasetForm.patchValue(data);

      data.cor_dataset_actor.forEach((cor, index) => {
        if (index === 0) {
          this.cor_dataset_actor_array.controls[index].patchValue(cor);
        } else {
          const formCor = this._formService.generateCorDatasetActorForm();
          this.cor_dataset_actor_array.push(formCor);
          //hack pour attendre que le template soit rendu avant de mettre les valeurs au formulaire
          setTimeout(() => {
            this.cor_dataset_actor_array.controls[index].patchValue(cor);
          }, 2000);
        }
      });
    });
  }

  postDataset() {
    const cor_dataset_actor_array = JSON.parse(JSON.stringify(this.cor_dataset_actor_array.value));
    const update_cor_dataset_actor = [];
    this._formService.formValid = true;

    cor_dataset_actor_array.forEach(element => {
      update_cor_dataset_actor.push(element);
      this._formService.checkFormValidity(element);
    });

    if (this._formService.formValid) {
      const dataset = Object.assign(this.datasetForm.value, {});

      dataset['cor_dataset_actor'] = update_cor_dataset_actor;
      this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/dataset`, dataset).subscribe(
        data => {
          this._router.navigate(['/metadata']);
          this._commonService.translateToaster('success', 'MetaData.Datasetadded');
        },
        error => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'NotAllowed');
          } else {
            this._commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
    }
  }
}
