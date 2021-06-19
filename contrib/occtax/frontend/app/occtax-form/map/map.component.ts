import { Component, OnInit, AfterViewInit, OnDestroy } from "@angular/core";
import { Subscription } from "rxjs";
import { filter, map, distinctUntilChanged } from "rxjs/operators";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { geomanDrawOption } from "@geonature_common/map/geoman-draw.options";
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleConfig } from "../../module.config";
import { MapService } from '@geonature_common/map/map.service';
import { OcctaxFormMapService } from "./map.service";
import { OcctaxFormService } from "../occtax-form.service";

@Component({
  selector: "pnx-occtax-form-map",
  templateUrl: "map.component.html",
})
export class OcctaxFormMapComponent implements OnInit, AfterViewInit, OnDestroy {
  public leafletDrawOptions: any;
  public geomanDrawOptions: any;
  public firstFileLayerMessage = true;
  public occtaxConfig = ModuleConfig;
  private _subscriptions: Subscription[] = [];

  public coordinates = null;
  public geometry = null;
  public firstGeom = true;

  constructor(
    private ms: OcctaxFormMapService,
    private _commonService: CommonService,
    private _occtaxFormService: OcctaxFormService,
    private _mapService: MapService
  ) { }

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;
    leafletDrawOption.draw.marker = false;
    leafletDrawOption.draw.polyline = true;
    leafletDrawOption.edit.remove = false;
    this.leafletDrawOptions = leafletDrawOption;
    geomanDrawOption.draw.drawPolyline = true;
    this.geomanDrawOptions = geomanDrawOption;
    // set the input for the marker component
    // set the coord only when load data and when its edition mode (id_releve)
    // after the marker component does it by itself whith the ouput
    // when modifie the coordinates innput, it create twice the marker
    this._subscriptions.push(
      this.ms.geojson
        .pipe(
          filter((geojson) => geojson !== null),
          distinctUntilChanged(),
          map((geojson) => geojson.geometry)
        )
        .subscribe((geometry) => {
          if (geometry.type == "Point") {
            this.coordinates = geometry.coordinates;
          } else {
            // set the input for leafletdraw component
            this.geometry = geometry;
          }
        })
    );

    // to get geometry from filelayer
    this._subscriptions.push(
      this._mapService.gettingGeojson$
        .subscribe(geojson => {
          this.ms.geometry = geojson;
        })
    );
  }

  ngAfterViewInit() {
    if (this._mapService.currentExtend) {
      this._mapService.map.setView(
        this._mapService.currentExtend.center,
        this._mapService.currentExtend.zoom
      )
    }
    let filelayerFeatures = this._mapService.fileLayerFeatureGroup.getLayers();
    // si il y a encore des filelayer -> on désactive le marker par defaut
    if (filelayerFeatures.length > 0) {
      this._mapService.setEditingMarker(false);
      this._mapService.fileLayerEditionMode = true;
    }

    filelayerFeatures.forEach(el => {
      if ((el as any).getLayers()[0].options.color == "red") {
        (el as any).setStyle({ color: "green", opacity: 0.2 });
      }
    });
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  sendGeoInfo(geojson) {
    this._occtaxFormService.disabled = false;
    this.ms.geometry = geojson;
  }

  ngOnDestroy() {
    this.ms.reset();
    this._subscriptions.forEach(s => { s.unsubscribe(); });
  }
}
