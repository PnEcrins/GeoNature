import { Component, Inject } from '@angular/core';

import { MAT_DIALOG_DATA } from '@angular/material';

import { IPermissionRequest } from '../../permission.interface';

@Component({
  selector: 'gn-refusal-request-dialog',
  templateUrl: 'refusal-request-dialog.component.html',
  styleUrls: ['./refusal-request-dialog.component.scss'],
})
export class RefusalRequestDialog {

  constructor(
    @Inject(MAT_DIALOG_DATA) public request: IPermissionRequest,
  ) { }
}
