import { Component, Input, ViewEncapsulation } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';


/**
 * Ce composant permet d'afficher un input de type "autocomplete" sur un liste d'observateur définit dans le schéma ``utilisateur.t_menus`` et ``utilisateurs.cor_role_menu``.
 * Il permet de séléctionner plusieurs utilisateurs dans le même input.
 * Renvoie l'objet: ```{
    "nom_complet": "ADMINISTRATEUR test",
    "nom_role": "Administrateur",
    "id_role": 1,
    "prenom_role": "test",
    "id_menu": 9
  }
  ```
 */
@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent extends GenericFormComponent {
  /**
   *  Id de la liste d'utilisateur (table ``utilisateur.t_menus``) (obligatoire)
   */
  @Input() idMenu: number;
  @Input() codeList: string;
  @Input() bindAllItem = false;
  @Input() bindValue: string = null;
  public observers: Observable<Array<any>>;

  constructor(private _dfService: DataFormService) {
    super();
  }

  ngOnInit() {
    if (this.idMenu) {
      this.observers = this._dfService
                            .getObservers(this.idMenu);
    } else if (this.codeList) {
      this.observers = this._dfService
                            .getObserversFromCode(this.codeList)
                            .pipe(
                              map(data => {
                                if (this.parentFormControl.value) {
                                  this.parentFormControl.setValue(this.parentFormControl.value);
                                }
                                return data;
                              })
                            );
    }
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }
}
