import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { NgbModal, NgbModalOptions } from '@ng-bootstrap/ng-bootstrap';

import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '@geonature_common/service/common.service';
import { DateStruc } from '@geonature_common/form/date/date.component';
import { PermissionService } from '../permission.service';
import { AuthService } from '../../../components/auth/auth.service';
import { ConventiondModalContent } from '../convention-modal/convention-modal.component';


@Component({
  selector: 'gn-access-request',
  templateUrl: './access-request.component.html',
  styleUrls: ['./access-request.component.scss']
})
export class AccessRequestComponent implements OnInit {

  public sendingRequest = false;
  public disableSubmit = false;
  public regularFormGrp: FormGroup;
  public dynamicFormGrp: FormGroup;
  // TODO: use config token with Dependency Injection !
  public config = AppConfig.PERMISSION_MANAGEMENT;
  public dynamicFormCfg;
  public rulesLink;
  public areaTypes: Array<Number>;
  public defaultAccessDuration;
  public maxAccessDuration;
  public defaultEndAccess: DateStruc;
  public datePickerMin;
  public datePickerMax;
  public userInfos;
  public accessRequestInfos;
  public customData;

  constructor(
    private authService: AuthService,
    private commonService: CommonService,
    private formBuilder: FormBuilder,
    private router: Router,
    private permissionService: PermissionService,
    private modalService: NgbModal,
  ) {
    this.redirectToHome();
    this.dynamicFormCfg = this.config.REQUEST_FORM;
    this.rulesLink = this.config.DATA_ACCESS_RULES_LINK || false;
    // TODO: use code instead of id
    this.areaTypes = this.config.AREA_TYPES;
    this.defaultAccessDuration = this.config.DEFAULT_ACCESS_DURATION;
    this.maxAccessDuration = this.config.MAX_ACCESS_DURATION;
  }

  private redirectToHome() {
    if (!(this.config.ENABLE_ACCESS_REQUEST || false)) {
      this.router.navigate(['/']);
    }
  }

  ngOnInit() {
    this.prepareAccessDates();
    this.createRegularForm();
    this.createDynamicForm();
  }

  private prepareAccessDates() {
    const today = new Date();
    const dayDuration = 864e5;

    this.datePickerMin = this.transformToDateObject(today);

    const maxAccessDuration = dayDuration * this.maxAccessDuration;
    const in2YearsDate = new Date(today.valueOf() + maxAccessDuration);
    this.datePickerMax = this.transformToDateObject(in2YearsDate);

    const defaultAccessDuration = dayDuration * this.defaultAccessDuration;
    const defaultEndAccessDate = new Date(today.valueOf() + defaultAccessDuration);
    this.defaultEndAccess = this.transformToDateObject(defaultEndAccessDate);
  }

  private transformToDateObject(date: Date) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
    };
  }

  private createRegularForm() {
    this.regularFormGrp = this.formBuilder.group({
      areas: ['', Validators.required],
      taxa: [''],
      sensitive_access: [],
      end_access_date: [this.defaultEndAccess],
    });
  }

  private createDynamicForm() {
    this.dynamicFormGrp = this.formBuilder.group({});
  }

  send() {
    if (this.regularFormGrp.valid && this.dynamicFormGrp.valid) {
      this.disableSubmit = true;

      if (this.config.ENABLE_CONVENTION) {
        this.showConvention();
      } else {
        this.sendAccessRequest();
      }
    }
  }

  private showConvention() {
    this.buildUserInfos();
    this.buildAccessRequestInfos();
    this.buildCustomData();
    const modalRef = this.openConventionModal();
    modalRef.componentInstance.userInfos = this.userInfos;
    modalRef.componentInstance.accessRequestInfos = this.accessRequestInfos;
    modalRef.componentInstance.customData = this.customData;
    modalRef.result.then((result) => {
      this.sendAccessRequest();
    }, (reason) => {
      this.commonService.translateToaster('warning', 'Permissions.accessRequest.conventionCanceled');
      this.disableSubmit = false;
    });
  }

  private buildUserInfos() {
    const currentUser = this.authService.getCurrentUser();
    this.userInfos = {
      firstname: currentUser.prenom_role,
      lastname: currentUser.nom_role
    };
  }

  private buildAccessRequestInfos() {
    const regularData = Object.assign({}, this.regularFormGrp.value);
    this.accessRequestInfos = {
      areas: '',
      taxa: '',
      sensitiveAccess: regularData.sensitive_access,
      endAccessDate: this.formatDate(regularData.end_access_date)
    }

    if (regularData.areas.length > 0) {
      let areasNames = [];
      regularData.areas.forEach(area => {
        areasNames.push(area.area_name);
      });
      this.accessRequestInfos.areas = areasNames.join(', ');
    }

    if (regularData.taxa.length > 0) {
      let taxaNames = [];
      regularData.taxa.forEach(taxon => {
        taxaNames.push(taxon.displayName);
      });
      this.accessRequestInfos.taxa = taxaNames.join(', ');
    }
  }

  private formatDate(date) {
    let formatedDate = '';
    if (date) {
      const day = this.padStartWithZero(date.day);
      const month = this.padStartWithZero(date.month);
      const year = date.year;
      formatedDate = `${day}/${month}/${year}`
    }
    return formatedDate;
  }

  // TODO: replace by string.padStart() when we 'll use ES2017.
  private padStartWithZero(number, size=2) {
    number = number.toString();
    while (number.length < size) {
      number = '0' + number;
    }
    return number;
  }

  private buildCustomData() {
    this.customData = this.dynamicFormGrp.value;
  }

  private openConventionModal() {
    const options: NgbModalOptions = {
      size: 'lg',
      backdrop: 'static',
      keyboard: false
    };
    return this.modalService.open(ConventiondModalContent, options);
  }

  private sendAccessRequest() {
    this.sendingRequest = true;
    const accessRequestData = this.getAccessRequestData();

    this.permissionService
    .sendAccessRequest(accessRequestData)
    .subscribe(
      () => {
        this.commonService.translateToaster('info', 'Permissions.accessRequest.responseOk');
        this.router.navigate(['/']);
      },
      error => {
        console.log('Error occurred when sending access request:', error);
        this.commonService.translateToaster('error', 'Permissions.accessRequest.responseError');
      })
    .add(() => {
      this.sendingRequest = false;
      this.disableSubmit = false;
    });
  }

  private getAccessRequestData() {
    const regularData = Object.assign({}, this.regularFormGrp.value);
    let accessRequestData = {
      areas: [],
      taxa: [],
      end_access_date: regularData.end_access_date,
      sensitive_access: regularData.sensitive_access,
    };

    if (regularData.areas.length > 0) {
      regularData.areas.forEach(area => {
        accessRequestData.areas.push(area.id_area);
      });
    }

    if (regularData.taxa.length > 0) {
      regularData.taxa.forEach(taxon => {
        accessRequestData.taxa.push(taxon.cd_nom);
      });
    }

    if (this.dynamicFormCfg.length > 0) {
      accessRequestData['additional_data'] = this.dynamicFormGrp.value;
    }

    return accessRequestData;
  }
}
