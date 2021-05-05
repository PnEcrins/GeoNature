import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BaseChartDirective } from 'ng2-charts';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-af-card',
  templateUrl: './af-card.component.html',
  styleUrls: ['./af-card.component.scss']
})
export class AfCardComponent implements OnInit {
  public id_af: number;
  public af: any;
  public acquisitionFrameworks: any;
  @ViewChild(BaseChartDirective) chart: BaseChartDirective;
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
        filter: function(legendItem, chartData) {
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
  public APP_CONFIG = AppConfig;

  constructor(private _dfs: DataFormService, private _route: ActivatedRoute) {}
  ngOnInit() {
    this._route.params.subscribe(params => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf(this.id_af);
      }
    });
  }
  getAf(id_af: number) {
    this._dfs.getAcquisitionFrameworkDetails(id_af).subscribe(data => {
      this.af = data;
      if (this.af.acquisition_framework_start_date) {
        var start_date = new Date(this.af.acquisition_framework_start_date);
        this.af.acquisition_framework_start_date = start_date.toLocaleDateString();
      }
      if (this.af.acquisition_framework_end_date) {
        var end_date = new Date(this.af.acquisition_framework_end_date);
        this.af.acquisition_framework_end_date = end_date.toLocaleDateString();
      }
      if (this.af.datasets) {
        this._dfs
          .getTaxaDistribution('group2_inpn', { id_af: this.af.id_acquisition_framework })
          .subscribe(data2 => {
            this.pieChartData.length = 0;
            this.pieChartLabels.length = 0;
            this.pieChartData = [];
            this.pieChartLabels = [];
            for (let row of data2) {
              this.pieChartData.push(row['count']);
              this.pieChartLabels.push(row['group']);
            }
            this.spinner = false;
            setTimeout(() => {
              this.chart.chart.update();
            }, 1000);
          });
      }
    });
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${
      this.af.id_acquisition_framework
    }`;
    window.open(url);
  }
}
