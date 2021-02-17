import { Component, Inject } from '@angular/core';

import { MAT_DIALOG_DATA } from '@angular/material';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { Subject } from 'rxjs';

import { IPermission } from '../../permission.interface';

@Component({
  selector: 'gn-permission-delete-dialog',
  templateUrl: 'delete-permission-dialog.component.html',
})
export class DeletePermissionDialog {

  locale: string;
  destroy$: Subject<boolean> = new Subject<boolean>();

  constructor(
    @Inject(MAT_DIALOG_DATA) public permission: IPermission,
    private translateService: TranslateService,
  ) {
    this.getI18nLocale();
  }

  private getI18nLocale() {
    this.locale = this.translateService.currentLang;
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.locale = langChangeEvent.lang;
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }
}
