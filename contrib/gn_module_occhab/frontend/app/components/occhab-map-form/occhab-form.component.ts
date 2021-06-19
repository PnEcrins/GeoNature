import { Component, OnInit } from "@angular/core";
import { OcchabFormService } from "../../services/form-service";
import { OcchabStoreService } from "../../services/store.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OccHabDataService } from "../../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { geomanDrawOption } from "@geonature_common/map/geoman-draw.options";
import { MapService } from "@geonature_common/map/map.service";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { CommonService } from "@geonature_common/service/common.service";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";
import { filter } from "rxjs/operators";
import { L } from "leaflet";
@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss", "../responsive-map.scss"],
  providers: [OcchabFormService]
})
export class OccHabFormComponent implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  public geomanDrawOptions = geomanDrawOption;
  public filteredHab: any;
  private _sub: Subscription;
  public editionMode = false;
  public MAP_SMALL_HEIGHT = "50vh !important;";
  public MAP_FULL_HEIGHT = "87vh";
  public mapHeight = this.MAP_FULL_HEIGHT;
  public appConfig = AppConfig;
  public moduleConfig = ModuleConfig;
  public showHabForm = false;
  public showTabHab = false;
  public showDepth = false;
  public disabledForm = true;
  public firstFileLayerMessage = true;
  public currentGeoJsonFileLayer;
  public markerCoordinates;
  public currentEditingStation: any;
  // boolean tocheck if the station has at least one hab (control the validity of the form)
  public atLeastOneHab = false;
  public datasets: Array<any>;
  public currentStations: Array<any>;
  public stationsgeoJson: L.geoJSON;

  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _gnDataService: DataFormService,
    private _mapService: MapService
  ) { }

  ngOnInit() {
    // Récupère les datasets compatibles avec OccHab
    this._gnDataService.getDatasets({ 'module_code': 'OCCHAB' }).subscribe(data => {
      this.datasets = data.data;
    })
    this.leafletDrawOptions;
    this.geomanDrawOptions;
    geomanDrawOption.draw.drawPolyline = false;
    geomanDrawOption.draw.drawCircle = true;
    geomanDrawOption.draw.drawRectangle = false;

    this.currentStations = [];

    this.occHabForm.stationForm = this.occHabForm.initStationForm();
    this.occHabForm.stationForm.controls.geom_4326.valueChanges.subscribe(d => {
      this.disabledForm = false;
    });
    this.storeService.defaultNomenclature$
      .pipe(filter(val => val !== null))
      .subscribe(val => {
        this.occHabForm.patchDefaultNomenclaureStation(val);
      });
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      if (params["id_station"]) {
        this.editionMode = true;
        this.atLeastOneHab = true;
        this.showHabForm = false;
        this.showTabHab = true;
        this._occHabDataService
          .getOneStation(params["id_station"])
          .subscribe(station => {
            this.currentEditingStation = station;
            if (station.geometry.type == "Point") {
              // set the input for the marker component
              this.markerCoordinates = station.geometry.coordinates;
            } else {
              // set the input for leaflet draw component
              this.currentGeoJsonFileLayer = station.geometry;
            }
            this.occHabForm.patchStationForm(station);
          });
      }
    });
  }

  fetchDatasetStations(datasetId, event) {
    this._occHabDataService.getStations(
      { 'id_dataset': datasetId }
    ).subscribe(geojsonStations => {
      if (event.checked) {
        // If checkbox checked, we add to related data to the currentStations list
        this.currentStations.push({ IdDB: datasetId, Data: geojsonStations });
      } else {
        // If the checkbox is unchecked, we find the related data in the currentStations list and we remove it
        var indexDataset = this.currentStations.findIndex(dict => dict.IdDB == datasetId);
        this.currentStations.splice(indexDataset, 1);
      }

      // We start a new featureCollection that will contain all the selected features
      var featureCollection = {
        type: 'FeatureCollection',
        features: []
      };
      // We add all the features contained in the currentStations list, in the featureCollection
      this.currentStations.forEach(function (feature) {
        featureCollection.features.push(feature.Data);
      });

      // We display the features on the map
      this.setDatasetOnLayers(datasetId, featureCollection);
    })
  }

  setDatasetOnLayers(datasetId, stations) {
    // const stationsLayerGroup = this._mapService.L.geoJSON(this.geojsonStations$.getValue());
    if (this.stationsgeoJson) {
      this._mapService.map.removeLayer(this.stationsgeoJson);
    }

    this.stationsgeoJson = this._mapService.L.geoJSON(stations, {
      pointToLayer: (feature, latlng) => {
        return this._mapService.L.circleMarker(latlng)
      }
    });

    //this._mapService.layerControl.addOverlay(stationsLayerGroup, datasetId);
    this.stationsgeoJson.addTo(this._mapService.map);

  }

  formIsDisable() {
    if (this.disabledForm) {
      this._commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  addNewHab() {
    this.occHabForm.addNewHab();
    this.showHabForm = true;
  }

  validateHabitat() {
    this.showHabForm = false;
    this.showTabHab = true;
    this.occHabForm.currentEditingHabForm = null;
    this.atLeastOneHab = true;
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.occHabForm.editHab(index);
    this.showHabForm = true;
  }

  cancelHab() {
    this.showHabForm = false;
    this.occHabForm.cancelHab();
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.postStation(station).subscribe(
      data => {
        this.occHabForm.resetAllForm();
        this._router.navigate(["occhab"]);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }

  formatter(item) {
    return item.search_name;
  }

  loadDatasetGeom(event) {
    console.log(event);
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
