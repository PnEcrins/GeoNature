import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter
} from '@angular/core';
import { 
  BehaviorSubject, 
  combineLatest 
} from 'rxjs';
import { filter, map, tap, pairwise, startWith } from 'rxjs/operators';
import { FormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import _ from "lodash";

export enum KEY_CODE {
  ENTER = 'Enter',
  ARROW_DOWN = 'ArrowDown',
  ARROW_UP = 'ArrowUp',
}

/**
 * Ce composant permet d'afficher un input de type multiselect à partir
 * d'une liste de valeurs passé en Input.
 *
 * @example
 * <pnx-multiselect
 *   label="Organisme"
 *   [values]="organisms"
 *   [parentFormControl]="form.controls.organisms"
 *   keyLabel="nom_organisme"
 *   keyValue="id_organisme"
 * >
 * </pnx-multiselect>
 */
@Component({
  selector: 'pnx-multiselect',
  templateUrl: './multiselect.component.html',
  styleUrls: ['./multiselect.component.scss']
})
export class MultiSelectComponent implements OnInit {
  @Input() parentFormControl: FormControl;
  /** Valeurs à afficher dans la liste déroulante. Doit être un tableau
   * de dictionnaire.
   */
  private _values: BehaviorSubject<Array<any>> = new BehaviorSubject([]);
  get values() { return this._values.getValue(); }
  @Input() set values(values: Array<any>) {
    this._values.next(values);
  }
  /** Clé du dictionnaire de valeur que le composant doit prendre pour
   * l'affichage de la liste déroulante.
   */
  @Input() keyLabel: string;
  /** Clé du dictionnaire que le composant doit passer au formControl */
  @Input() keyValue: string;
  /** Est-ce que le composant doit afficher l'item "tous" dans les
   * options du select ?
   */
  @Input() displayAll: boolean;
  /** Affiche la barre de recherche (=true). */
  @Input() searchBar: boolean;
 /** Désactive le contrôle de formulaire. */
  @Input() disabled: boolean = false;
  /** Initutlé du contrôle de formulaire. */
  @Input() label: any;
  // palceholder displayed in the input
  @Input() placeholder: string;
  // class displayed in the input
  @Input() class: string = "auto";

  /**
   * Booléan qui permet de passer tout l'objet au formControl, et pas
   * seulement une propriété de l'objet renvoyé par l'API.
   *
   * Facultatif, par défaut à ``false``, c'est alors l'attribut passé en
   * Input ``keyValue`` qui est renvoyé au formControl.
   * Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue``
   * devient inutile.
   * L'API qui renvoit séléctionnées au formulaire doit être un tableau
   * d'entier et non un tableau d'items
   */
  @Input() bindAllItem: false;
  /** Temps en millisecondes avant lancement d'une recherche avec les
   * caractères saisis dans la zone de recherche.
   *
   * Par défaut, 100 millisecondes.
   */
  @Input() debounceTime: number;
  /** Indique (=true) que le contenu de la liste doit être conscidéré
   * comme du HTML sûr.
   */
  @Input() isHtml: boolean = false;
  /** Action à exécuter lors d'une recherche. */
  @Output() onSearch = new EventEmitter();
  /** Action à exécuter lors du changement du contenu. */
  @Output() onChange = new EventEmitter<any>();
  /** Action à exécuter lors de la suppression du contenu. */
  @Output() onDelete = new EventEmitter<any>();


  /** @ignore */
  constructor(private _translate: TranslateService) {}

  // you can pass whatever callback to the onSearch output, to trigger
  // database research or simple search on an array
  ngOnInit() {
    // transform objet to id key with this.keyValue
    this.parentFormControl.valueChanges
      .pipe(
        startWith([]),
        pairwise(),
        filter(([prev, next]: [any, any])=> !_.isEqual(_.sortBy(prev), _.sortBy(next))),
        map(([prev, next]: [any, any])=>next),
        map((values)=>values.map(value=>{
          if ( Number.isInteger(value) ) {
            return value;
          } else if (value[this.keyValue] !== undefined) {
            return value[this.keyValue];
          }
        }))
      ).subscribe(formValues=>this.parentFormControl.patchValue(formValues));
  }
}
