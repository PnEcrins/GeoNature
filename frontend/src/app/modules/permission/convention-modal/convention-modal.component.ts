import { Component, Input, OnInit } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';

import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'gn-convention-modal',
  templateUrl: './convention-modal.component.html'
})
export class ConventiondModalContent implements OnInit {

  public title = AppConfig.PERMISSION_MANAGEMENT.CONVENTION_TITLE;
  public validate = AppConfig.PERMISSION_MANAGEMENT.CONVENTION_VALIDATE;

  @Input() userInfos;
  @Input() accessRequestInfos;
  @Input() customData;

  constructor(public activeModal: NgbActiveModal) {}

  ngOnInit(): void {
    //throw new Error('Method not implemented.');
  }
}
