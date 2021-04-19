import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataFormService } from '../services/metadata-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import { HttpClient } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { Router, ActivatedRoute } from '@angular/router';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FormService } from '@geonature_common/form/form.service';

@Component({
  selector: 'pnx-af-form',
  templateUrl: './af-form.component.html',
  providers: [MetadataFormService]
})
export class AfFormComponent implements OnInit {
  public afForm: FormGroup;
  public acquisitionFrameworks;
  public cor_af_actor: FormArray;
  public id_af: number;
  public af: any;

  constructor(
    private _fb: FormBuilder,
    private _dfs: DataFormService,
    private _formService: MetadataFormService,
    private _gnFormService: FormService,
    private _commonService: CommonService,
    private _route: ActivatedRoute,
    private _api: HttpClient,
    private _router: Router,
    private _toaster: ToastrService,
    private _dateParser: NgbDateParserFormatter
  ) {}

  ngOnInit() {
    this._route.params.subscribe(params => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf(this.id_af);
      }
    });
    // get acquisistion frameworks parent
    this._dfs.getAcquisitionFrameworks({ is_parent: 'true' }).subscribe(data => {
      this.acquisitionFrameworks = data;
    });
    this.afForm = this._fb.group({
      id_acquisition_framework: null,
      acquisition_framework_name: [null, Validators.required],
      acquisition_framework_desc: [null, Validators.required],
      id_nomenclature_territorial_level: [null, Validators.required],
      territory_desc: null,
      keywords: null,
      id_nomenclature_financing_type: [null, Validators.required],
      target_description: null,
      ecologic_or_geologic_target: null,
      acquisition_framework_parent_id: null,
      is_parent: false,
      acquisition_framework_start_date: [null, Validators.required],
      acquisition_framework_end_date: null,
      cor_objectifs: [new Array()],
      cor_volets_sinp: [new Array()]
    });

    this.cor_af_actor = this._fb.array([]);
    this.cor_af_actor.push(this._formService.generateCorAfActorForm());

    this.afForm.setValidators([
      this._gnFormService.dateValidator(
        this.afForm.get('acquisition_framework_start_date'),
        this.afForm.get('acquisition_framework_end_date')
      )
    ]);
  }

  getAf(id_af) {
    this._dfs.getAcquisitionFramework(id_af).subscribe(data => {
      this.af = data;
      data.acquisition_framework_start_date = this._dateParser.parse(
        data.acquisition_framework_start_date
      );
      data.acquisition_framework_end_date = this._dateParser.parse(
        data.acquisition_framework_end_date
      );
      this.afForm.patchValue(data);
      data.cor_af_actor.forEach((cor, index) => {
        if (index === 0) {
          this.cor_af_actor.controls[index].patchValue(cor);
        } else {
          const formCor = this._formService.generateCorAfActorForm();
          this.cor_af_actor.push(formCor);
          //hack pour attendre que le template soit rendu avant de mettre les valeurs au formulaire
          setTimeout(() => {
            this.cor_af_actor.controls[index].patchValue(cor);
          }, 2000);
        }
      });
    });
  }

  addFormArray(): void {
    this.cor_af_actor.push(this._formService.generateCorAfActorForm());
  }

  postAf() {
    const cor_af_actor = JSON.parse(JSON.stringify(this.cor_af_actor.value));
    const af = Object.assign({}, this.afForm.value);

    const update_cor_af_actor = [];
    this._formService.formValid = true;
    cor_af_actor.forEach(element => {
      update_cor_af_actor.push(element);
      this._formService.checkFormValidity(element);
    });

    if (this._formService.formValid) {
      af.acquisition_framework_start_date = this._dateParser.format(
        af.acquisition_framework_start_date
      );

      if (af.acquisition_framework_end_date) {
        af.acquisition_framework_end_date = this._dateParser.format(
          af.acquisition_framework_end_date
        );
      }

      af['cor_af_actor'] = update_cor_af_actor;
      this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework`, af).subscribe(
        data => {
          this._router.navigate(['/metadata']);
          this._commonService.translateToaster('success', 'MetaData.AFadded');
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

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${
      this.af.id_acquisition_framework
    }`;
    window.open(url);
  }
}
