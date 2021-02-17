import { Component, Inject } from '@angular/core';

import { MAT_DIALOG_DATA } from '@angular/material';

import { IPermissionRequest } from '../../permission.interface';

@Component({
  selector: 'gn-pending-request-dialog',
  templateUrl: 'pending-request-dialog.component.html',
})
export class PendingRequestDialog {

  constructor(
    @Inject(MAT_DIALOG_DATA) public request: IPermissionRequest,
  ) {}
}
