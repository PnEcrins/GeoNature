// Angular modules
import { Component, Input } from '@angular/core';

// Third party's modules
import { TranslateService } from '@ngx-translate/core';

// This module
import { IPermissionRequest } from '../permission.interface';


@Component({
  selector: 'gn-permission-request-display',
  templateUrl: 'request-display.component.html',
  styleUrls: ['./request-display.component.scss'],
})
export class RequestDisplayComponent {

  /**
   * Permet de fournir un objet PermissionRequest qui servira à l'affichage.
   * Le format de l'objet correspond à l'interface IPermissionRequest.
   */
  @Input() request: IPermissionRequest;
  /** Active/Désactive l'affichage des données issues du formulaire dynamique. */
  @Input() withDynamicFormData: boolean = false;
  /** Active/Désactive l'affichage dense des informations.
   * Si l'affichage dense est désactivé :
   *  - les textes ne sont plus abrégés et ont des polices plus grandes
   *  - les panneaux repliables sont directement ouverts
   *  - les cartes et panneaux ont plus de marges
   */
  @Input() dense: boolean = false;
  /** Contient le code ISO-639-1 de la langue actuellement sélectionée. */
  locale: string;
  /** Format de date à afficher en fonction de la densité demandée. */
  dateFormat: string = 'longDate'

  constructor(
    private translateService: TranslateService,
  ) {
    this.locale = translateService.currentLang;
  }

  ngOnInit(): void {
    if (this.dense) {
      this.dateFormat = 'mediumDate';
    }
  }
}
