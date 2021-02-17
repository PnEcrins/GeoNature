import { Component, Inject } from '@angular/core';

import { MAT_DIALOG_DATA } from '@angular/material';

import { IPermissionRequest } from '../../permission.interface';

@Component({
  selector: 'gn-accept-request-dialog',
  templateUrl: 'accept-request-dialog.component.html',
})
export class AcceptRequestDialog {

  constructor(
    @Inject(MAT_DIALOG_DATA) public request: IPermissionRequest,
  ) {}
}
