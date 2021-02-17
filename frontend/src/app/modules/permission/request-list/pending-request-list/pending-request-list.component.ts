import { AfterViewInit, Component, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { MatDialog } from '@angular/material';

import { DatatableComponent, ColumnMode } from '@swimlane/ngx-datatable';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { Subject } from 'rxjs';
import { ToastrService } from 'ngx-toastr';

import { AcceptRequestDialog } from '../../shared/accept-request-dialog/accept-request-dialog.component';
import { CommonService } from '@geonature_common/service/common.service';
import { IPermissionRequest, IPermissionRequestDatatableColumn, } from '../../permission.interface';
import { PermissionService } from '../../permission.service';
import { RefusalRequestDialog } from '../../shared/refusal-request-dialog/refusal-request-dialog.component';


@Component({
  selector: 'gn-pending-permission-request-list',
  templateUrl: './pending-request-list.component.html',
  styleUrls: ['./pending-request-list.component.scss'],
})
export class PendingRequestListComponent implements OnInit, OnDestroy, AfterViewInit {

  locale: string;
  destroy$: Subject<boolean> = new Subject<boolean>();

  loadingIndicator = true;
  reorderable = true;
  swapColumns = false;

  @ViewChild(DatatableComponent)
  datatable: DatatableComponent;
  @ViewChild('colHeaderTpl')
  colHeaderTpl: TemplateRef<any>;
  @ViewChild('tokenCellTpl')
  tokenCellTpl: TemplateRef<any>;
  @ViewChild('geographicCellTpl')
  geographicCellTpl: TemplateRef<any>;
  @ViewChild('taxonomicCellTpl')
  taxonomicCellTpl: TemplateRef<any>;
  @ViewChild('sensitiveCellTpl')
  sensitiveCellTpl: TemplateRef<any>;
  @ViewChild('endAccessDateCellTpl')
  endAccessDateCellTpl: TemplateRef<any>;
  @ViewChild('createDateCellTpl')
  createDateCellTpl: TemplateRef<any>;
  @ViewChild('actionsCellTpl')
  actionsCellTpl: TemplateRef<any>;

  columns: Array<IPermissionRequestDatatableColumn> = [
    {
      prop: 'token',
      name: '#',
      tooltip: 'Token de la demande de permission.',
      flexGrow: 1,
    },
    {
      prop: 'userName',
      name: 'Utilisateur',
      tooltip: "Prénom et nom de l'utilisateur ayant réalisé la demande.",
      flexGrow: 2,
      searchable: true,
    },
    {
      prop: 'organismName',
      name: 'Organisme',
      tooltip: "Nom de l'organisme de l'utilisateur.",
      flexGrow: 2,
      searchable: true,
    },
    {
      prop: 'endAccessDate',
      name: 'Date de fin',
      tooltip: "Date à laquelle les permissions demandées expires.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'geographicFiltersLabels',
      name: 'Zones géo.',
      tooltip: 'Nombre de zones géographiques concernées par la demande.',
      flexGrow: 1,
    },
    {
      prop: 'taxonomicFiltersLabels',
      name: 'Grp. taxo.',
      tooltip: 'Nombre de groupes taxonomiques concernés par la demande.',
      flexGrow: 1,
    },
    {
      prop: 'sensitiveAccess',
      name: 'Sensible',
      tooltip: "La demande concerne-t-elle l'accès aux données sensibles.",
      flexGrow: 1,
    },
    {
      prop: 'metaCreateDate',
      name: 'Date demande',
      tooltip: "Date d'enregistrement de la demande.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'actions',
      name: 'Actions',
      flexGrow: 2,
      sortable: false,
      headerClass: 'd-flex justify-content-end'
    },
  ];
  searchableColumnsNames: string;
  rows: IPermissionRequest[] = [];
  filteredData = [];

  constructor(
    private translateService: TranslateService,
    public permissionService: PermissionService,
    public dialog: MatDialog,
    private toasterService: ToastrService,
    private commonService: CommonService
  ) {
    this.locale = translateService.currentLang;
    this.loadRequests();
  }

  ngOnInit(): void {
    this.prepareColumns();
    this.formatSearchableColumn();
    this.getI18nLocale();
    this.defineDatatableMessages();
  }

  ngAfterViewInit(): void {
    // Workaround to resize column with columnMode="'flex'".
    // See : https://github.com/swimlane/ngx-datatable/issues/919
    this.datatable.columnMode = ColumnMode.force;

    // Define default messages for datatable
    this.translateService.get('Datatable')
      .subscribe((translatedTxts: string[]) => {
        this.datatable.messages = translatedTxts;
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  private loadRequests() {
    this.permissionService.getAllPendingRequests().subscribe(data => {
      this.loadingIndicator = false;
      this.rows = data;
      this.filteredData = [...data];
    });
  }

  private prepareColumns() {
    this.columns.forEach(col => {
      // Set common config
      col.headerTemplate = this.colHeaderTpl;
      col.headerClass += ' table-primary';

      // Set specific config
      if (col.prop === 'token') {
        col.cellTemplate = this.tokenCellTpl;
      } else if (col.prop === 'endAccessDate') {
        col.cellTemplate = this.endAccessDateCellTpl;
      } else if (col.prop === 'geographicFiltersLabels') {
        col.cellTemplate = this.geographicCellTpl;
      } else if (col.prop === 'taxonomicFiltersLabels') {
        col.cellTemplate = this.taxonomicCellTpl;
      } else if (col.prop === 'sensitiveAccess') {
        col.cellTemplate = this.sensitiveCellTpl;
      } else if (col.prop === 'metaCreateDate') {
        col.cellTemplate = this.createDateCellTpl;
      } else if (col.prop === 'actions') {
        col.cellTemplate = this.actionsCellTpl;
      }
    });
  }

  private formatSearchableColumn() {
    const searchable = [];
    this.columns.forEach(col => {
      if (col.searchable) {
        searchable.push(col.name);
      }
    });
    this.searchableColumnsNames = `« ${searchable.join(' », « ')} »`;
  }

  private getI18nLocale() {
    this.locale = this.translateService.currentLang;
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.locale = langChangeEvent.lang;
        this.defineDatatableMessages();
      });
  }

  private defineDatatableMessages() {
    // Define default messages for datatable
    this.translateService.get('Datatable')
      .subscribe((translatedTxts: string[]) => {
        this.datatable.messages = translatedTxts;
      });
  }

  updateFilter(event) {
    const val = event.target.value.toLowerCase();
    // Columns to search
    let searchColumns = this.getSearchableColumn();
    // Get the amount of columns to search
    let searchColsAmount = searchColumns.length;

    // Filter our data
    this.rows = this.filteredData.filter(function (item) {
      // Iterate through each row's column data
      for (let i = 0; i < searchColsAmount; i++) {
        // Handle item (defined or not)
        let item_value = ''
        if (item[searchColumns[i]]) {
          item_value = item[searchColumns[i]].toString().toLowerCase();
        }

        // Check for a match
        if (item_value.indexOf(val) !== -1 || !val){
          // Found match, return true to add to result set
          return true;
        }
      }
    });

    // Whenever the filter changes, always go back to the first page
    this.datatable.offset = 0;
  }

  private getSearchableColumn() {
    const searchable = [];
    this.columns.forEach(col => {
      if (col.searchable) {
        searchable.push(col.prop);
      }
    });
    return searchable;
  }

  openAcceptDialog(data: IPermissionRequest): void {
    const dialogRef = this.dialog.open(AcceptRequestDialog, {
      data: data
    });

    dialogRef.afterClosed().subscribe(request_token => {
      if (request_token) {
        this.permissionService.acceptRequest(request_token).subscribe(
          () => {
            this.loadRequests();
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

  openRefusalDialog(request: IPermissionRequest): void {
    const dialogRef = this.dialog.open(RefusalRequestDialog, {
      data: request
    });

    dialogRef.afterClosed().subscribe(request => {
      if (request) {
        console.log(request)
        this.permissionService.refuseRequest(request).subscribe(
          () => {
            this.loadRequests();
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
