import { Component, OnInit, TemplateRef, ViewChild } from '@angular/core';

import { Subject } from 'rxjs';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { DatatableComponent } from '@swimlane/ngx-datatable';
import { IRolePermission } from '../permission.interface'
import { PermissionService } from '../permission.service';

interface DatatableColumn {
  prop: string;
  name: string;
  flexGrow: number;
  sortable?: boolean;
  tooltip?: string;
  headerClass?: string;
  cellTemplate?: TemplateRef<any>;
  headerTemplate?: TemplateRef<any>;
  searchable?: boolean;
}

@Component({
  selector: 'gn-permission-list',
  templateUrl: './permission-list.component.html',
  styleUrls: ['./permission-list.component.scss'],
})
export class PermissionListComponent implements OnInit {

  loadingIndicator = true;
  reorderable = true;
  swapColumns = false;
  destroy$: Subject<boolean> = new Subject<boolean>();

  @ViewChild(DatatableComponent)
  datatable: DatatableComponent;
  @ViewChild('colHeaderTpl')
  colHeaderTpl: TemplateRef<any>;
  @ViewChild('typeCellTpl')
  typeCellTpl: TemplateRef<any>;
  @ViewChild('organismCellTpl')
  organismCellTpl: TemplateRef<any>;
  @ViewChild('actionsCellTpl')
  actionsCellTpl: TemplateRef<any>;

  columns: Array<DatatableColumn> = [
    {
      prop: 'id',
      name: '#',
      flexGrow: 1,
      tooltip: 'Identifiant du rôle.',
    },
    {
      prop: 'userName',
      name: 'Nom',
      flexGrow: 2,
      tooltip: "Prénom et nom de l'utilisateur ou intitulé du groupe.",
      searchable: true,
    },
    {
      prop: 'organismName',
      name: 'Organisme',
      flexGrow: 2,
      tooltip: "Nom de l'organisme auquel l'utilisateur appartient.",
      searchable: true,
    },
    {
      prop: 'type',
      name: 'Type',
      flexGrow: 2,
      tooltip: 'Type de rôle : groupe ou utilisateur.',
      searchable: true,
    },
    {
      prop: 'permissionsNbr',
      name: 'Nbre permissions',
      flexGrow: 1,
      tooltip: 'Nombre de permissions réellement attribuées (ne tient pas compte des permissions héritées).',
    },
    {
      prop: 'actions',
      name: 'Actions',
      flexGrow: 1,
      sortable: false,
      headerClass: 'd-flex justify-content-end'
    },
  ];
  searchableColumnsNames: string;
  rows: IRolePermission[] = [];
  filteredData = [];

  constructor(
    private translateService: TranslateService,
    public permissionService: PermissionService,
  ) {
    this.permissionService.getAllRoles().subscribe(data => {
      this.loadingIndicator = false;

      this.rows = data;
      this.filteredData = [...data];
    });
  }

  ngOnInit(): void {
    this.prepareColumns();
    this.formatSearchableColumn();
    this.onLanguageChange();
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
      col.headerClass += ' table-primary';

      // Set specific config
      if (col.prop === 'type') {
        col.cellTemplate = this.typeCellTpl;
      } else if (col.prop === 'organismName') {
        col.cellTemplate = this.organismCellTpl;
      }else if (col.prop === 'actions') {
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

  private onLanguageChange() {
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
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
    this.rows = this.filteredData.filter( (item) => {
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

  getRowClass(row) {
    return {
      'row-group': row.type === 'GROUP',
      'row-user': row.type === 'USER',
    };
  }
}
