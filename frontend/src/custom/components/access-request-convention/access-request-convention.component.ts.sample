import { Component, OnInit, Input, } from '@angular/core';


export interface User {
  firstname: string;
  lastname: string;
}

export interface AccessRequest {
  areas: string;
  taxa: string;
  sensitiveAccess: boolean;
  endAccessDate: string;
}

@Component({
  selector: 'gn-access-request-convention',
  templateUrl: 'access-request-convention.component.html',
  styleUrls: ['./access-request-convention.component.scss']
})
export class AccessRequestConventionComponent implements OnInit {

  @Input() user: User;
  @Input() accessRequest: AccessRequest;
  @Input() customData: any;

  constructor() { }

  ngOnInit() { }
}
