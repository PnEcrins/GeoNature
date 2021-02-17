import { Component, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';

import { DatatableComponent } from '@swimlane/ngx-datatable';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { Subject } from 'rxjs';

import { IPermissionRequestDatatableColumn, IPermissionRequest } from '../../permission.interface';
import { PermissionService } from '../../permission.service';


@Component({
  selector: 'gn-processed-permission-request-list',
  templateUrl: './processed-request-list.component.html',
  styleUrls: ['./processed-request-list.component.scss'],
})
export class ProcessedRequestListComponent implements OnInit, OnDestroy {

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
  @ViewChild('stateCellTpl')
  stateCellTpl: TemplateRef<any>;
  @ViewChild('processedDateCellTpl')
  processedDateCellTpl: TemplateRef<any>;
  @ViewChild('processedByCellTpl')
  processedByCellTpl: TemplateRef<any>;
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
      prop: 'endAccessDate',
      name: 'Date de fin',
      tooltip: "Date à laquelle les permissions demandées expires.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'processedState',
      name: 'État',
      tooltip: "État de la demande : acceptée ou refusée.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'processedDate',
      name: 'Date traitement',
      tooltip: "Date et heure à laquelle le traitement de la demande a eu lieu.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'processedBy',
      name: 'Traité par',
      tooltip: "Prénom et nom de l'administrateur ayant traité la demande. ANONYME si le traitement a eu lieu via l'email.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'actions',
      name: 'Actions',
      flexGrow: 1,
      sortable: false,
    },
  ];
  searchableColumnsNames: string;
  rows: IPermissionRequest[] = [];
  filteredData = [];

  constructor(
    private translateService: TranslateService,
    public permissionService: PermissionService,
  ) {
    this.locale = translateService.currentLang;

    this.permissionService.getAllProcessedRequests().subscribe(data => {
      console.log(data)
      this.loadingIndicator = false;
      this.rows = data;
      this.filteredData = [...data];
    });
  }

  ngOnInit(): void {
    this.prepareColumns();
    this.formatSearchableColumn();
    this.getI18nLocale();
    this.defineDatatableMessages();
  }

  ngOnDestroy() {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  private prepareColumns() {
    this.columns.forEach(col => {
      // Set common config
      col.headerTemplate = this.colHeaderTpl;
      col.headerClass = 'table-primary';

      // Set specific config
      if (col.prop === 'token') {
        col.cellTemplate = this.tokenCellTpl;
      } else if (col.prop === 'geographicFiltersLabels') {
        col.cellTemplate = this.geographicCellTpl;
      } else if (col.prop === 'taxonomicFiltersLabels') {
        col.cellTemplate = this.taxonomicCellTpl;
      } else if (col.prop === 'sensitiveAccess') {
        col.cellTemplate = this.sensitiveCellTpl;
      } else if (col.prop === 'endAccessDate') {
        col.cellTemplate = this.endAccessDateCellTpl;
      } else if (col.prop === 'processedState') {
        col.cellTemplate = this.stateCellTpl;
      } else if (col.prop === 'processedDate') {
        col.cellTemplate = this.processedDateCellTpl;
      } else if (col.prop === 'processedBy') {
        col.cellTemplate = this.processedByCellTpl;
      } else if (col.prop === 'actions') {
        col.cellTemplate = this.actionsCellTpl;
      }
    });
  }

  private formatSearchableColumn(): void {
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

  private getSearchableColumn() {
    const searchable = [];
    this.columns.forEach(col => {
      if (col.searchable) {
        searchable.push(col.prop);
      }
    });
    return searchable;
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

  getRowClass(row) {
    return {
      'row-refused': row.processedState === 'refused',
      'row-accepted': row.processedState === 'accepted',
    };
  }
}
