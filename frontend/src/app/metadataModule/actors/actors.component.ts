import { Component, OnInit, Input } from '@angular/core';
import { FormArray } from '@angular/forms';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-metadata-actor',
  templateUrl: 'actors.component.html'
})
export class ActorComponent implements OnInit {
  @Input() parentFormArray: FormArray;
  public organisms: Observable<Array<any>>;
  public roles: Observable<Array<any>>;
  constructor(private _dfs: DataFormService) {}

  ngOnInit() {
    this.organisms = this._dfs.getOrganisms()
      .pipe(
        map(data => data)
      );
    this.roles = this._dfs.getRoles({'group': false})
      .pipe(
        map(data => data)
      );
  }
  deleteFormArray(i) {
    this.parentFormArray.removeAt(i);
  }
}
