import { Component, Input, Output, EventEmitter } from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { NgbModal} from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../../module.config";
import {  FormGroup, FormBuilder, Validators } from '@angular/forms';
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
//import { FILTERSLIST } from "./filters-list";
import { Router } from "@angular/router";
import { ValidationDataService } from "../../services/data.service";
import { CommonService } from "@geonature_common/service/common.service";
 
 
@Component({
  selector: "pnx-validation-popup",
  templateUrl: "validation-popup.component.html",
  styleUrls: ["./validation-popup.component.scss"],
  providers: [MapListService]
})
export class ValidationPopupComponent {
 
  error: any;
  public modalRef:any;
  string_observations: string;
  public statusForm: FormGroup;
  public VALIDATION_CONFIG = ModuleConfig;
  public status;
  public plurielObservations;
  public plurielNbOffPage;
  public nbOffPage;
  public validationDate;
  public currentCdNomenclature: string;
 
  @Input() observations : Array<number>;
  @Input() selectedPages : Array<number>;
  @Input() nbTotalObservation : number;
  @Input() validationStatus: Array<any>;
  @Input() currentPage : any;
  @Input() validation : any;
  @Output() valStatus = new EventEmitter();
  @Output() valDate = new EventEmitter();
 
  constructor(
    private modalService: NgbModal,
    private _dateParser: NgbDateParserFormatter,
    private _router: Router,
    private _fb: FormBuilder,
    public dataService: ValidationDataService,
    private _commonService: CommonService,
    private mapListService: MapListService
    ) {
      // form used for changing validation status
      this.statusForm = this._fb.group({
        statut : ['', Validators.required],
        comment : ['']
      });
    }
   
 
  onSubmit(value) {
    // post validation status form ('statusForm') for one or several observation(s) to backend/routes
     
    return this.dataService.postStatus(value, this.observations).toPromise()
    .then(
      data => {
        return new Promise((resolve, reject) => {
            // show success message indicating the number of observation(s) with modified validation status
            this._commonService.translateToaster("success", "Vous avez modifié le statut de validation de " + this.observations.length + " observation(s)");
            // bind statut value with validation-synthese-list component
            this.update_status();
            // emit the date of today in output to update the validation date on maplist
            this.valDate.emit(new Date());
            //this.getValidationDate(this.observations[0]);
            resolve('data updated');
        })
      })
    .catch(
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this._commonService.translateToaster("error", "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)");
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", err.error);
        }
        Promise.reject()
      }
    )
    .then(
      data => {
        return new Promise((resolve, reject) => {
          // close validation status popup
          this.closeModal();
          resolve('process finished');
      })
    })
    .then(
      data => {
        //console.log(data);
      }
    );
  }
 
  setCurrentCdNomenclature(item) {
    this.currentCdNomenclature = item.cd_nomenclature;
 
  }
 
  update_status() {
    // send cd_nomenclature value to validation-synthese-list component
    this.valStatus.emit(this.currentCdNomenclature);
  }
 
 
  definePlurielObservations() {
    if (this.observations.length == 1) {
      return '';
    } else {
      return 's';
    }
  }
 
  definePlurielNbOffPage() {
    if (this.nbOffPage <= 1) {
      return '';
    } else {
      return 's';
    }
  }
 
  isAccess() {
    // disable access validation button if no row is checked
    if (this.observations.length === 0) {
      return false;
    } else {
      return true;
    }
  }
 
  openVerticallyCentered(content) {
      // if no error : open popup for changing validation status
      this.modalRef = this.modalService.open(content, {
        centered: true, size: "lg", backdrop: 'static', windowClass: 'dark-modal'
      });
      this.getObsNboffPage();
      this.plurielObservations = this.definePlurielObservations();
      this.plurielNbOffPage = this.definePlurielNbOffPage();
  }
 
  getObsNboffPage() {
    this.nbOffPage = 0;
    for (let page of this.selectedPages) {
      if (page != this.currentPage) {
        this.nbOffPage = this.nbOffPage +1;
      } 
    }
  }
 
  closeModal() {
    // close validation status popup
    this.statusForm.reset();
    this.modalRef.close();
  }
 
  getValidationDate(uuid) {
    this.dataService.getValidationDate(uuid).subscribe(
      result => {
        // get status names
        this.validationDate = result;
      },
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this._commonService.translateToaster("error", "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)");
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", err.error);
        }
      },
      () => {
        // emit date of today 
        this.valDate.emit(this.validationDate);
      }
    );
  }

}