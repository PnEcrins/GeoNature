// Angular's modules
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  MatAutocompleteModule,
  MatBadgeModule,
  MatButtonModule,
  MatCardModule,
  MatChipsModule,
  MatDialogModule,
  MatExpansionModule,
  MatFormFieldModule,
  MatIconModule,
  MatIconRegistry,
  MatInputModule,
  MatListModule,
  MatMenuModule,
  MatPaginatorModule,
  MatProgressBarModule,
  MatProgressSpinnerModule,
  MatSelectModule,
  MatSidenavModule,
  MatSlideToggleModule,
  MatStepperModule,
  MatTabsModule,
  MatToolbarModule,
  MatTooltipModule,
} from '@angular/material';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

// Third party's modules
import 'rxjs/Rx';
import { NgxMatSelectSearchModule } from 'ngx-mat-select-search';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { AutoCompleteModule } from 'primeng/primeng';
import { NgSelectModule } from '@ng-select/ng-select';
import { TreeModule } from 'angular-tree-component';

// Components
import { AcquisitionFrameworksComponent } from '@geonature_common/form/acquisition-frameworks/acquisition-frameworks.component';
import { AreasComponent } from '@geonature_common/form/areas/areas.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { AutoCompleteComponent } from '@geonature_common/form/autocomplete/autocomplete.component';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { DatalistComponent } from '@geonature_common/form/datalist/datalist.component';
import { BreadcrumbsComponent } from '@geonature_common/others/breadcrumbs/breadcrumbs.component'
import { DatasetsComponent } from './form/datasets/datasets.component';
import { DateComponent } from './form/date/date.component';
import { DisplayMediasComponent } from '@geonature_common/form/media/display-medias.component';
import { DumbSelectComponent } from '@geonature_common/form/dumb-select/dumb-select.component';
import { DynamicFormComponent } from './form/dynamic-form/dynamic-form.component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { GenericFormGeneratorComponent } from '@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { GeometryFormComponent } from '@geonature_common/form/geometry-form/geometry-form.component';
import { GPSComponent } from './map/gps/gps.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';
import { LeafletFileLayerComponent } from './map/filelayer/filelayer.component';
import { MapComponent } from './map/map.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapListGenericFiltersComponent } from './map-list/generic-filters/generic-filters.component';
import { MapOverLaysComponent } from './map/overlays/overlays.component';
import { MarkerComponent } from './map/marker/marker.component';
import { MediaComponent } from '@geonature_common/form/media/media.component';
import { MediaDialog } from '@geonature_common/form/media/media-dialog.component';
import { MediasComponent } from '@geonature_common/form/media/medias.component';
import { MediasTestComponent } from '@geonature_common/form/media/medias-test.component';
import { ModalDownloadComponent } from '@geonature_common/others/modal-download/modal-download.component';
import { MultiSelectComponent } from './form/multiselect/multiselect.component';
import { MunicipalitiesComponent } from '@geonature_common/form/municipalities/municipalities.component';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
import { PeriodComponent } from '@geonature_common/form/date/period.component';
import { PlacesComponent } from './map/places/places.component';
import { PlacesListComponent } from './map/placesList/placesList.component';
import { SyntheseSearchComponent } from '@geonature_common/form/synthese-form/synthese-form.component';
import { TaxaComponent } from '@geonature_common/form/taxa/taxa.component';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

// Directives
import { DisableControlDirective } from './form/disable-control.directive';
import { DisplayMouseOverDirective } from './directive/display-mouse-over.directive';

// Pipes
import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';
import { SafeHtmlPipe } from './pipe/sanitizer.pipe';
import { SafeStripHtmlPipe } from './pipe/strip-html.pipe';
import { StripHtmlPipe } from './pipe/strip-html.pipe';

// Services
import { CommonService } from './service/common.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { DataFormService } from './form/data-form.service';
import { FormService } from './form/form.service';
import { MapListService } from './map-list/map-list.service';
import { MapService } from './map/map.service';
import { MediaService } from '@geonature_common/service/media.service';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';


@NgModule({
  imports: [
    AutoCompleteModule,
    CommonModule,
    FormsModule,
    MatAutocompleteModule,
    MatBadgeModule,
    MatButtonModule,
    MatCardModule,
    MatChipsModule,
    MatDialogModule,
    MatExpansionModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatListModule,
    MatMenuModule,
    MatPaginatorModule,
    MatProgressBarModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatSidenavModule,
    MatSlideToggleModule,
    MatStepperModule,
    MatTabsModule,
    MatToolbarModule,
    MatTooltipModule,
    NgbModule.forRoot(),
    NgxDatatableModule,
    NgxMatSelectSearchModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    NgSelectModule,
    RouterModule,
    TranslateModule.forChild(),
    TreeModule,
  ],
  declarations: [
    AcquisitionFrameworksComponent,
    AreasComponent,
    NomenclatureComponent,
    ObserversComponent,
    BreadcrumbsComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    AutoCompleteComponent,
    ConfirmationDialog,
    DatalistComponent,
    DatasetsComponent,
    DateComponent,
    DisableControlDirective,
    DisplayMediasComponent,
    DisplayMouseOverDirective,
    DumbSelectComponent,
    DynamicFormComponent,
    GenericFormComponent,
    GenericFormGeneratorComponent,
    GeojsonComponent,
    GeometryFormComponent,
    GPSComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    MapComponent,
    MapDataComponent,
    MapListComponent,
    MapListGenericFiltersComponent,
    MapOverLaysComponent,
    MarkerComponent,
    MediaComponent,
    MediaDialog,
    MediasComponent,
    MediasTestComponent,
    ModalDownloadComponent,
    MultiSelectComponent,
    MunicipalitiesComponent,
    NomenclatureComponent,
    ObserversComponent,
    ObserversTextComponent,
    PeriodComponent,
    PlacesComponent,
    PlacesListComponent,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    SyntheseSearchComponent,
    SafeStripHtmlPipe,
    StripHtmlPipe,
    TaxaComponent,
    TaxonAdvancedModalComponent,
    TaxonomyComponent,
  ],
  providers: [
    CommonService,
    DataFormService,
    DynamicFormService,
    FormService,
    MapListService,
    MapService,
    MatIconRegistry,
    MediaService,
    NgbDatePeriodParserFormatter,
    SyntheseDataService,
    TranslateService,
  ],
  entryComponents: [
    ConfirmationDialog,
    MediaDialog,
    TaxonAdvancedModalComponent,
  ],
  exports: [
    AcquisitionFrameworksComponent,
    AreasComponent,
    MunicipalitiesComponent,
    BreadcrumbsComponent,
    DynamicFormComponent,
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    AutoCompleteComponent,
    ConfirmationDialog,
    DatalistComponent,
    DatasetsComponent,
    DateComponent,
    DisableControlDirective,
    DisplayMediasComponent,
    DisplayMouseOverDirective,
    DumbSelectComponent,
    DynamicFormComponent,
    FormsModule,
    GenericFormComponent,
    GenericFormGeneratorComponent,
    GeojsonComponent,
    GeometryFormComponent,
    GPSComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    MapComponent,
    MapDataComponent,
    MapListComponent,
    MapListGenericFiltersComponent,
    MapOverLaysComponent,
    MarkerComponent,
    MatAutocompleteModule,
    MatBadgeModule,
    MatButtonModule,
    MatCardModule,
    MatChipsModule,
    MatDialogModule,
    MatExpansionModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatListModule,
    MatMenuModule,
    MatPaginatorModule,
    NgSelectModule,
    MatProgressBarModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatSidenavModule,
    MatSlideToggleModule,
    MatStepperModule,
    MatTabsModule,
    MatToolbarModule,
    MatTooltipModule,
    MediaDialog,
    MediasComponent,
    ModalDownloadComponent,
    MultiSelectComponent,
    MunicipalitiesComponent,
    NgbModule,
    NgxDatatableModule,
    NgxMatSelectSearchModule,
    NomenclatureComponent,
    ObserversComponent,
    ObserversTextComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SafeStripHtmlPipe,
    StripHtmlPipe,
    SyntheseSearchComponent,
    TaxonAdvancedModalComponent,
    DumbSelectComponent,
    GeometryFormComponent,
    ConfirmationDialog,
    MediasComponent,
    MediaDialog,
    DisplayMediasComponent,
    DatalistComponent,
    PlacesComponent,
    PlacesListComponent,
    ReactiveFormsModule,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    SyntheseSearchComponent,
    TaxaComponent,
    TaxonAdvancedModalComponent,
    TaxonomyComponent,
    TranslateModule,
  ]
})
export class GN2CommonModule {
  constructor(
    public matIconRegistry: MatIconRegistry
  ) {
    matIconRegistry.registerFontClassAlias('fontawesome', 'fa');
  }
}
