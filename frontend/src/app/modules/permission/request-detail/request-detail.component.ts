import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material';
import { ActivatedRoute, Router } from '@angular/router';

import { TranslateService } from '@ngx-translate/core';
import { ToastrService } from 'ngx-toastr';

import { AcceptRequestDialog } from '../shared/accept-request-dialog/accept-request-dialog.component';
import { CommonService } from '@geonature_common/service/common.service';
import { IPermissionRequest } from '../permission.interface';
import { PendingRequestDialog } from '../shared/pending-request-dialog/pending-request-dialog.component';
import { PermissionService } from '../permission.service';
import { RefusalRequestDialog } from '../shared/refusal-request-dialog/refusal-request-dialog.component';

@Component({
  selector: 'gn-permission-request-detail',
  templateUrl: './request-detail.component.html',
  styleUrls: ['./request-detail.component.scss']
})
export class RequestDetailComponent implements OnInit {
  [x: string]: any;

  token: string;
  request: IPermissionRequest;
  errorMsg: string;

  constructor(
    public activatedRoute: ActivatedRoute,
    private commonService: CommonService,
    public dialog: MatDialog,
    public permissionService: PermissionService,
    private toasterService: ToastrService,
    private translateService: TranslateService,
    private router: Router,
  ) {
    this.router.routeReuseStrategy.shouldReuseRoute = () => false;
  }

  ngOnInit(): void {
    this.extractRouteParams();
    this.loadRequest();
  }

  private extractRouteParams() {
    const urlParams = this.activatedRoute.snapshot.paramMap;
    this.token = urlParams.get('requestToken');
    if (urlParams.has('user') && urlParams.has('organism')) {
      this.request = {
        'token': this.token,
        'userName': urlParams.get('user'),
        'organismName': urlParams.get('organism'),
      };
    }
  }

  private loadRequest() {
    this.permissionService.getRequestByToken(this.token)
      .subscribe(
        data => {
          this.request = data;
          this.errorMsg = undefined;
        },
        error => {
          this.errorMsg = (error.error && error.error.msg) ? error.error.msg : error.message;
          this.request = undefined;

          if (error.status === 404) {
            this.errorMsg = `Token « ${this.token} » de la demande d'accès introuvable.`
          }
          this.translateService
            .get('Permissions.errors.stdMsg', {errorMsg: this.errorMsg})
            .subscribe((translatedTxt: string) => {
              this.toasterService.error(translatedTxt);
            });
        }
      );
  }

  openAcceptDialog(request: IPermissionRequest): void {
    const dialogRef = this.dialog.open(AcceptRequestDialog, {
      data: request
    });

    dialogRef.afterClosed().subscribe(request_token => {
      if (request_token) {
        this.permissionService.acceptRequest(request_token).subscribe(
          () => {
            this.router.navigate(['permissions/requests/processed']);
            this.commonService.translateToaster('info', 'Permissions.accessRequest.acceptOk');
          },
          error => {
            const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
            this.translateService
              .get('Permissions.accessRequest.acceptKo', {errorMsg: msg})
              .subscribe((translatedTxt: string) => {
                this.toasterService.error(translatedTxt);
              });
          }
        );
      }
    });
  }

  openPendingDialog(request: IPermissionRequest): void {
    const dialogRef = this.dialog.open(PendingRequestDialog, {
      data: request
    });

    dialogRef.afterClosed().subscribe(request_token => {
      if (request_token) {
        this.permissionService.pendingRequest(request_token).subscribe(
          () => {
            this.router.navigate(['permissions/requests/pending']);
            this.commonService.translateToaster('info', 'Permissions.accessRequest.pendingOk');
          },
          error => {
            const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
            this.translateService
              .get('Permissions.accessRequest.pendingKo', {errorMsg: msg})
              .subscribe((translatedTxt: string) => {
                this.toasterService.error(translatedTxt);
              });
          }
        );
      }
    });
  }

  openRefusalDialog(request: IPermissionRequest): void {
    const dialogRef = this.dialog.open(RefusalRequestDialog, {
      data: request
    });

    dialogRef.afterClosed().subscribe(request => {
      if (request) {
        this.permissionService.refuseRequest(request).subscribe(
          () => {
            this.router.navigate(['permissions/requests/processed']);
            this.commonService.translateToaster('info', 'Permissions.accessRequest.refusalOk');
          },
          error => {
            const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
            this.translateService
              .get('Permissions.accessRequest.refusalKo', {errorMsg: msg})
              .subscribe((translatedTxt: string) => {
                this.toasterService.error(translatedTxt);
              });
          }
        );
      }
    });
  }
}
