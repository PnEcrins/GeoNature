import { STEPPER_GLOBAL_OPTIONS } from '@angular/cdk/stepper';
import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';

import { BehaviorSubject, Observable } from 'rxjs';
import { CommonService } from '@geonature_common/service/common.service';

import { IActionObject, IFilter, IFilterValue, IModule, IPermission, IRolePermission } from '../../permission.interface';
import { PermissionService } from '../../permission.service';
import { TranslateService } from '@ngx-translate/core';
import { ToastrService } from 'ngx-toastr';
import { atLeastOne } from '../../shared/permission.directive';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'gn-edit-permission-modal',
  templateUrl: './edit-permission-modal.component.html',
  styleUrls: ['./edit-permission-modal.component.scss'],
  providers: [
    { provide: STEPPER_GLOBAL_OPTIONS, useValue: {showError: true} },
  ]
})
export class EditPermissionModal implements OnInit {

  permission: IPermission;
  role: IRolePermission;
  // Boolean to check if its updateMode
  updateMode: BehaviorSubject<boolean> = new BehaviorSubject(false);
  formGroup;
  modules;
  actionsOjects;
  filters: Observable<IFilter[]>;
  availableFilters: string[] = [];
  filtersValues: Record<string, IFilterValue[]>;
  geographicFilterTypes: Array<Number>;
  taxonomicFilterRank: string;
  datePickerMin;
  datePickerMax;

  constructor(
    @Inject(MAT_DIALOG_DATA) public data: any,
    public modalRef: MatDialogRef<EditPermissionModal>,
    private dateParser: NgbDateParserFormatter,
    private permissionService: PermissionService,
    private formBuilder: FormBuilder,
    private commonService: CommonService,
    private translateService: TranslateService,
    private toasterService: ToastrService,
  ) {
    this.role = data.role;
    this.permission = data.permission;

    // TODO: use code instead of id ! Use config parameter with token Dependency Injection !
    this.geographicFilterTypes = [25,26];
    // TODO: use config parameter with token Dependency Injection !
    this.taxonomicFilterRank = 'GN';

    this.checkMode();
    this.loadModules();
    this.loadFiltersValues();
    this.prepareFilters();
    this.buildFormGroups();
  }

  private checkMode() {
    if (this.permission.gathering) {
      this.updateMode.next(true);
      console.log('In UPDATE Mode:', this.permission)
    } else {
      this.updateMode.next(false);
      console.log('In CREATE Mode:', this.permission)
    }
  }

  private loadModules() {
    this.permissionService.getModules().subscribe( modules => {
      this.modules = modules;

      console.log("In load modules, mode:", this.updateMode.getValue())
      if (this.updateMode.getValue()) {
        let module = this.getModule(this.permission.module);
        console.log("In load modules:", module)
        this.formGroup.patchValue({modules: {module: module} });

        this.loadActionsObjects(module);
      }
    });
  }

  private getModule(code: string) {
    return this.modules.find(module => module.code == code);
  }

  private loadFiltersValues() {
    this.permissionService.getFiltersValues().subscribe( fValues => {
      // Extract filter type codes and dispatch filter values by filter type code
      this.filtersValues = {};
      for (let prop in fValues) {
        // Get all value of a sepcific filter type
        let values = fValues[prop];
        // All values inside the object property have the same filter type code.
        let filterCode = values[0].filterTypeCode;
        // Dispatch values by filter type code
        this.filtersValues[filterCode] = values;
      }
    });
  }

  private prepareFilters() {
    const today = new Date();
    const dayDuration = 864e5;

    this.datePickerMin = this.transformToDateObject(today);

    // TODO: improve pnx-date to not set maxDate for unlimited future date
    const maxAccessDuration = dayDuration * 3650;// 10 years
    const in2YearsDate = new Date(today.valueOf() + maxAccessDuration);
    this.datePickerMax = this.transformToDateObject(in2YearsDate);
  }

  // TODO: move this function in PermissionService. Refactor with access-request.component.
  private transformToDateObject(date: Date) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
    };
  }

  private buildFormGroups() {
    this.formGroup = this.formBuilder.group({
      modules: this.formBuilder.group({
        module: ['', Validators.required],
      }),
      actionsObjects: this.formBuilder.group({
        actionObject: ['', Validators.required],
      }),
      filters: this.formBuilder.group({
        geographic: [''],
        taxonomic: [''],
        precision: [''],
        scope: ['', Validators.required],
      }, {
        validator: atLeastOne('geographic','taxonomic', 'precision', 'scope')
      }),
      validating: this.formBuilder.group({
        endDate: [''],
      }),
    });
  }

  loadActionsObjects(module: IModule) {
    console.log(`In loadActionsObjects, value: ${module.code}`, module)
    this.permissionService.getActionsObjects(module.code).subscribe( actionsOjects => {
      this.actionsOjects = actionsOjects;

      if (this.updateMode.getValue()) {
        let actionObj = this.getActionsObjects(this.permission.action, this.permission.object);
        this.formGroup.patchValue({actionsObjects: {actionObject: actionObj} });

        this.loadFilters(actionObj);
      }
    });
  }

  private getActionsObjects(action: string, object: string) {
    return this.actionsOjects.find(ao => ao.actionCode == action && ao.objectCode == object);
  }

  loadFilters(actionObj: IActionObject) {
    console.log(`In loadFilters, value: ${actionObj.moduleCode}-${actionObj.actionCode}-${actionObj.objectCode}`, actionObj)
    this.permissionService.getActionsObjectsFilters(actionObj)
      .subscribe( filters => {
        console.log("Filters received:", filters)
        this.availableFilters = [];
        filters.forEach(filter => {
          this.availableFilters.push(filter.filterTypeCode);
        });

        if (this.updateMode.getValue()) {
          console.log("Permission:", this.permission)
          this.permission.filters.forEach(filter => {
            let filterFormOjbect = {filters: {}};
            filterFormOjbect['filters'][filter.type.toLowerCase()] = this.buildFilterValue(filter);
            console.log("Filter form object: ", filterFormOjbect)
            this.formGroup.patchValue(filterFormOjbect);
          });
          console.log("Form group: ", this.formGroup)
        }
      });
  }

  private buildFilterValue(filter) {
    let filterValue = filter.value;
    if (filter.type == 'TAXONOMIC') {
      filterValue = [];
      filter.value.forEach((nameCode, idx) => {
        filterValue.push({
          cd_nom: parseInt(nameCode),
          displayName: filter.label[idx],
        })
      });
    } else if (filter.type == 'GEOGRAPHIC') {
      filterValue = [];
      filter.value.forEach((areaId, idx) => {
        filterValue.push({
          id_area: parseInt(areaId),
          area_name: filter.label[idx],
        })
      });
    }
    return filterValue;
  }

  ngOnInit(): void {
    this.checkMode();

    if (this.updateMode.getValue()) {
      this.patchValidatingEndDate();
    }
  }

  private patchValidatingEndDate() {
    let endDateObject = this.dateParser.parse(this.permission.endDate);
    this.formGroup.patchValue({
      validating: {
        endDate: endDateObject,
      }
    })
    console.log("Patch end date:", this.formGroup)
  }

  public addPermission() {
    const permissionData = this.getPermissionData();
    console.log("permissionData:", permissionData);

    this.permissionService
      .addPermission(permissionData)
      .subscribe(
        () => {
          this.commonService.translateToaster('info', 'Permissions.addingOk');
          this.modalRef.close('OK');
        },
        error => {
          const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
          console.log(msg);
          this.translateService
            .get('Permissions.addingKo', {errorMsg: msg})
            .subscribe((translatedTxt: string) => {
              this.toasterService.error(translatedTxt);
            });
        }
      );
  }

  public updatePermission() {
    const permissionData = this.getPermissionData();
    console.log("permissionData:", permissionData);

    this.permissionService
      .updatePermission(permissionData)
      .subscribe(
        () => {
          this.commonService.translateToaster('info', 'Permissions.updatingOk');
          this.modalRef.close('OK');
        },
        error => {
          const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
          console.log(msg);
          this.translateService
            .get('Permissions.updatingKo', {errorMsg: msg})
            .subscribe((translatedTxt: string) => {
              this.toasterService.error(translatedTxt);
            });
        }
      );
  }

  private getPermissionData() {
    const formData = Object.assign({}, this.formGroup.value);
    // Need to do this to get geographic and taxonomic arrays of objects
    //formData.filters.geographic = this.formGroup.get('filters.geographic').value;
    //formData.filters.taxonomic = this.formGroup.get('filters.taxonomic').value;
    console.log("FormData:", formData)

    let permissionData = {
      idRole: this.role.id,
      module: formData.modules.module.code,
      action: formData.actionsObjects.actionObject.actionCode,
      object: formData.actionsObjects.actionObject.objectCode,
      filters: {
        geographic: null,
        taxonomic: null,
        scope: null,
        precision: null,
      },
      endDate: formData.validating.endDate,
    };

    if (this.updateMode.getValue() && ! this.permission.isInherited) {
      permissionData['gathering'] = this.permission.gathering;
    }

    // this.formGroup.controls.filters.controls.geographic
    if (formData.filters.geographic.length > 0) {
      permissionData.filters.geographic = [];
      formData.filters.geographic.forEach(area => {
        permissionData.filters.geographic.push(area.id_area);
      });
    }

    if (formData.filters.taxonomic.length > 0) {
      permissionData.filters.taxonomic = [];
      formData.filters.taxonomic.forEach(taxa => {
        permissionData.filters.taxonomic.push(taxa.cd_nom);
      });
    }

    if (formData.filters.scope) {
      permissionData.filters.scope = formData.filters.scope;
    }

    if (formData.filters.precision) {
      permissionData.filters.precision = formData.filters.precision;
    }

    return permissionData;
  }
}
