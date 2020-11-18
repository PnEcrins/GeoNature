import { AppConfig } from "@geonature_config/app.config";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import {
  Component,
  OnInit,
  Input,
  Output,
  ViewChild,
  HostListener,
  AfterContentChecked,
  OnChanges,
  ChangeDetectorRef,
  EventEmitter
} from "@angular/core";
import { MapService } from "@geonature_common/map/map.service";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleConfig } from "../../module.config";
import { DomSanitizer } from "@angular/platform-browser";
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { ValidationModalInfoObsComponent } from "../validation-modal-info-obs/validation-modal-info-obs.component";
import { SyntheseFormService } from "@geonature_common/form/synthese-form/synthese-form.service";
import { SyntheseDataService } from "@geonature_common/form/synthese-form/synthese-data.service";
@Component({
  selector: "pnx-validation-synthese-list",
  templateUrl: "validation-synthese-list.component.html",
  styleUrls: ["validation-synthese-list.component.scss"]
})
export class ValidationSyntheseListComponent
  implements OnInit, OnChanges, AfterContentChecked {
  public VALIDATION_CONFIG = ModuleConfig;
  public oneSyntheseObs: any;
  public appConfig: any;
  selectedObs: Array<number> = []; // list of id_synthese values for selected rows
  selectedIndex: Array<number> = [];
  selectedPages = [];
  coordinates_list = []; // list of coordinates for selected rows
  marker: MediaTrackSupportedConstraints;
  public rowNumber: number;
  private _latestWidth: number;
  public id_same_coordinates = []; // list of observation ids having same geographic coordinates
  public modif_text =
    "Attention données modifiées depuis la dernière validation";
  public npage;

  @Input() inputSyntheseData: Array<any>;
  @Input() validationStatus: Array<any>;
  @ViewChild("table") table: DatatableComponent;
  @Output() pageChange: EventEmitter<number>;
  public validationStatusAsDict: any;

  constructor(
    public mapListService: MapListService,
    private _ds: SyntheseDataService,
    public ngbModal: NgbModal,
    private _commonService: CommonService,
    public sanitizer: DomSanitizer,
    public ref: ChangeDetectorRef,
    private _ms: MapService,
    public formService: SyntheseFormService,
  ) {
  }

  ngOnInit() {
    // get app config
    this.appConfig = AppConfig;

    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 37);

    // this.group = new FeatureGroup();
    this.onMapClick();
    this.onTableClick();
    this.npage = 1;

  }

  onMapClick() {
    this.mapListService.onMapClik$.subscribe(id => {
      // create list of observation ids having coordinates = to id value


      const selected_id_coordinates = this.mapListService.layerDict[id].feature
        .geometry.coordinates;
      this.id_same_coordinates = [];

      // for (let obs in this.mapListService.geojsonData.features) {
      //   console.log(obs);

      //   if (
      //     JSON.stringify(selected_id_coordinates) ==
      //     JSON.stringify(
      //       this.mapListService.geojsonData.features[obs].geometry.coordinates
      //     )
      //   ) {
      //     this.id_same_coordinates.push(
      //       parseInt(this.mapListService.geojsonData.features[obs].id)
      //     );
      //   }
      // }

      // select rows having id_synthese = to one of the id_same_coordinates values
      this.mapListService.selectedRow = [];
      for (let i = 0; i < this.mapListService.tableData.length; i++) {
        if (this.mapListService.tableData[i]["id_synthese"] === id) {
          this.mapListService.selectedRow.push(
            this.mapListService.tableData[i]
          );
          break;
        }
        const page = Math.trunc(i / this.rowNumber);

        this.table.offset = page;
      }

      //this.setSelectedObs();
    });
  }

  onTableClick() {
    this.setSelectedObs();
    this.mapListService.onTableClick$.subscribe(id => {
      this.setSelectedObs();
      this.setOriginStyleToAll();
      this.setSelectedSyleToSelectedRows();
    });
  }

  ngAfterContentChecked() {
    if (this.table && this.table.element.clientWidth !== this._latestWidth) {
      this._latestWidth = this.table.element.clientWidth;
      this.table.recalculate();
    }
  }

  handlePageChange(event): void {
    this.npage = event.page;
  }

  setOriginStyleToAll() {
    for (let obs in this.mapListService.layerDict) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.originStyle
      );
    }
  }

  setSelectedSyleToSelectedRows() {
    for (let obs of this.selectedObs) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.selectedStyle
      );
    }
  }

  selectAll() {
    this.mapListService.selectedRow = [...this.mapListService.tableData];
    this.setSelectedObs();
    this.viewFitList(this.selectedObs);
    this.setSelectedSyleToSelectedRows();
  }

  deselectAll() {
    this.mapListService.selectedRow = [];
    this.setSelectedObs();
    if (this.mapListService.selectedRow.length === 0) {
      this.setOriginStyleToAll();
    }
  }
  toggleSelection(element) {
    if (element.target.checked) {
      this.selectAll();
    } else {
      this.deselectAll();
    }
  }
  onActivate(event) {
    if (event.type == "checkbox" || event.type == "click") {
      this.setSelectedObs();
      this.viewFitList(this.selectedObs);
      if (this.mapListService.selectedRow.length === 0) {
        this.setOriginStyleToAll();
      }
    }
  }

  viewFitList(id_observations) {
    if (id_observations.length) {
      this.mapListService.zoomOnSeveralSelectedLayers(this._ms.map, id_observations);
    }
  }

  setSelectedObs() {
    // array of id_sythese values of selected observations
    this.selectedObs = [];
    this.selectedIndex = [];
    this.selectedPages = [];
    if (this.mapListService.selectedRow.length === 0) {
      this.selectedObs = [];
    } else {
      for (let obs in this.mapListService.selectedRow) {
        this.selectedObs.push(
          this.mapListService.selectedRow[obs]["id_synthese"]
        );
      }
    }

    for (let obs of this.selectedObs) {
      // find position of selected observations in the ngxtable from id_synthese of selected observations
      this.selectedIndex.push(
        this.mapListService.tableData.findIndex(i => i.id_synthese === obs)
      );
    }

    // find page from an ngxindex
    for (let ind of this.selectedIndex) {
      let PageIndex = (ind + 1) / this.table._limit;
      this.selectedPages.push(Math.ceil(PageIndex));
    }
  }

  onStatusChange(cd_nomenclature) {
    for (let obs in this.mapListService.selectedRow) {
      this.mapListService.selectedRow[obs][
        "cd_nomenclature_validation_status"
      ] = cd_nomenclature;

      this.mapListService.selectedRow[obs]["validation_auto"] = "";
    }
    this.mapListService.selectedRow = [...this.mapListService.selectedRow];
  }

  onValidationDateChange(date) {
    for (let obs in this.mapListService.selectedRow) {
      this.mapListService.selectedRow[obs]["validation_date"] = date;
    }
    this.mapListService.selectedRow = [...this.mapListService.selectedRow];
  }

  // update the number of row per page when resize the window
  @HostListener("window:resize", ["$event"])
  onResize(event) {
    this.rowNumber = Math.trunc(event.target.innerHeight / 37);
  }

  backToModule(url_source, id_pk_source) {
    const link = document.createElement("a");
    link.target = "_blank";
    link.href = url_source + "/" + id_pk_source;
    link.setAttribute("visibility", "hidden");
    document.body.appendChild(link);
    link.click();
    link.remove();
  }

  getRowClass() {
    return "row-sm clickable";
  }

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
    this.deselectAll();
  }

  openInfoModal(row) {
    this.oneSyntheseObs = row;
    const modalRef = this.ngbModal.open(ValidationModalInfoObsComponent, {
      size: "lg",
      windowClass: "large-modal"
    });

    modalRef.componentInstance.id_synthese = row.id_synthese;
    modalRef.componentInstance.uuidSynthese = row.unique_id_sinp;
    modalRef.componentInstance.validationStatus = this.validationStatus;
    modalRef.componentInstance.mapListService = this.mapListService;
    modalRef.componentInstance.modifiedStatus.subscribe(modifiedStatus => {
      for (let obs in this.mapListService.tableData) {
        if (
          this.mapListService.tableData[obs].id_synthese ==
          modifiedStatus.id_synthese
        ) {
          this.mapListService.tableData[obs].cd_nomenclature_validation_status =
            modifiedStatus.new_status;
          this.mapListService.tableData[obs].validation_auto = "";
        }
      }
    });
    modalRef.componentInstance.valDate.subscribe(data => {
      for (let obs in this.mapListService.selectedRow) {
        this.mapListService.selectedRow[obs]["validation_date"] = data;
      }
      this.mapListService.selectedRow = [...this.mapListService.selectedRow];
    });
  }

  getValidationStatusMnemonique(code) {
    var statusF = this.validationStatus.filter((st) => st.cd_nomenclature == code);
    if (statusF.length > 0) {
      return statusF[0].mnemonique;
    }
    else {
      return null;
    }
  }
}
