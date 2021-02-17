import { Component, OnInit, ViewChild } from '@angular/core';

import { DatatableComponent } from '@swimlane/ngx-datatable';
import { PermissionService } from '../permission.service';

@Component({
  selector: 'gn-permission-request-list',
  templateUrl: './request-list.component.html',
  styleUrls: ['./request-list.component.scss'],
})
export class RequestListComponent implements OnInit {

  loadingIndicator = true;
  reorderable = true;
  swapColumns = false;

  links = [
    {label: 'En attentes', path: '/permissions/requests/pending', icon: 'pending'},
    {label: 'Traitées', path: '/permissions/requests/processed', icon: 'check_circle'},
  ];

  @ViewChild(DatatableComponent)
  pendingDatatable: DatatableComponent;

  constructor(
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    //throw new Error('Method not implemented.');
  }
}
