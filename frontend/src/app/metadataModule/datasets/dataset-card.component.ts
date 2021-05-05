import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BaseChartDirective } from 'ng2-charts';
import { AppConfig } from "@geonature_config/app.config";
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

@Component({
  selector: 'pnx-datasets-card',
  templateUrl: './dataset-card.component.html',
  styleUrls: ['./dataset-card.scss']
})
export class DatasetCardComponent implements OnInit {
  public organisms: Array<any>;
  public id_dataset: number;
  public dataset: any;
  public nbTaxons: number;
  public taxs;
  public nbObservations: number;
  public geojsonData: any = null;

  @ViewChild(BaseChartDirective) public chart: BaseChartDirective;

  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = [];
  // Tableau contenant les données du graphe
  public pieChartData = [];
  // Tableau contenant les couleurs et la taille de bordure du graphe
  public pieChartColors = [];
  // Dictionnaire contenant les options à implémenter sur le graphe (calcul des pourcentages notamment)
  public pieChartOptions = {
    cutoutPercentage: 80,
    legend: {
      display: 'true',
      position: 'left',
      labels: {
        fontSize: 15,
        filter: function (legendItem, chartData) {
          return chartData.datasets[0].data[legendItem.index] != 0;
        }
      }
    },
    plugins: {
      labels: [
        {
          render: 'label',
          arc: true,
          fontSize: 14,
          position: 'outside',
          overlap: false
        },
        {
          render: 'percentage',
          fontColor: 'white',
          fontSize: 14,
          fontStyle: 'bold',
          precision: 2,
          textShadow: true,
          overlap: false
        }
      ]
    }
  };

  public spinner = true;

  constructor(
    private _route: ActivatedRoute,
    private _dfs: DataFormService,
    private _commonService: CommonService,
    public _dataService: SyntheseDataService,
    private _router: Router
  ) { }

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getDataset(this.id_dataset);
      }
    });
  }


  getDataset(id) {
    this._dfs.getDatasetDetails(id).subscribe(data => {
      this.dataset = data;
      // first set to 0 to disable delete button
      this.dataset.observation_count = 0;
      // load stat
      this._dataService.getObsCount({'id_dataset': id}).subscribe(count => {
        this.dataset.observation_count = count;
      })
      this._dataService.getTaxaCount({'id_dataset': id}).subscribe(count => {
        this.dataset.taxa_count = count;
      });

      this._dataService.getObsBbox({'id_dataset': id}).subscribe(bbox => {
        this.geojsonData = bbox;
      })
      
      if (this.dataset.modules) {
        this.dataset.modules = this.dataset.modules.map(e => e.module_code).join(', ');
      }
    });
    this._dfs.getTaxaDistribution('group2_inpn', { id_dataset: id }).subscribe(data => {
      this.pieChartData = [];
      this.pieChartLabels = [];
      for (let row of data) {
        this.pieChartData.push(row['count']);
        this.pieChartLabels.push(row['group']);
      }
      // in order to have chart instance
      setTimeout(() => {
        this.chart.chart.update();
      }, 1000);
    });
  }

  uuidReport(ds_id) {
    this._dataService.downloadUuidReport(
      `UUID_JDD-${ds_id}_${this.dataset.unique_dataset_id}`,
      { id_dataset: ds_id }
    );
  }

  sensiReport(ds_id) {
    this._dataService.downloadSensiReport(
      `Sensibilite_JDD-${ds_id}_${this.dataset.unique_dataset_id}`,
      { id_dataset: ds_id }
    );
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/dataset/export_pdf/${this.id_dataset}`;
    window.open(url);
  }

  uuidReportImport(id_import) {
    const imp = this.dataset.imports.find(imp => imp.id_import == id_import);
    this._dataService.downloadUuidReport(
      `UUID_Import-${id_import}_JDD-${imp.id_dataset}`,
      { id_import: id_import }
    );
  }

  sensiReportImport(id_import) {
    console.log("OK");
    const imp = this.dataset.imports.find(imp => imp.id_import == id_import);
    this._dataService.downloadSensiReport(
      `Sensibilite_Import-${id_import}_JDD-${imp.id_dataset}`,
      { id_import: id_import }
    );
  }

  deleteDataset(idDataset) {
    if (window.confirm('Etes-vous sûr de vouloir supprimer ce jeu de données ?')) {
      this._dfs.deleteDs(idDataset).subscribe(d => {
        this._router.navigate(['metadata'])
      });
    }
  }

  importDs(idDataset) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "datasetId": idDataset,
        "resetStepper": true
      }
    };
    this._router.navigate(['/import/process/step/1'], navigationExtras);
  }

  syntheseDs(idDataset) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "id_dataset": idDataset
      }
    };
    this._router.navigate(['/synthese'], navigationExtras);
  }

}
