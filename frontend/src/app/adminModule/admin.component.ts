import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';

@Component({
  selector: 'pnx-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  providers: []
})
export class AdminComponent implements OnInit {
  URL_NOMENCLATURE_ADMIN = AppConfig.API_ENDPOINT + '/admin/';
  ENABLED_ACCESS_REQUEST = AppConfig.PERMISSION_MANAGEMENT.ENABLE_ACCESS_REQUEST;

  URL_BACKOFFICE_PERM = AppConfig.API_ENDPOINT + '/permissions_backoffice/users';
  constructor(public _cruvedStore: CruvedStoreService) {}

  ngOnInit() {}
}
