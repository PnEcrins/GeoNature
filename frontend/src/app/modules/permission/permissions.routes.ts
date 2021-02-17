import { Routes } from '@angular/router';

// Module components
import { AccessRequestComponent } from './access-request/access-request.component';
import { PermissionDetailComponent } from './permission-detail/permission-detail.component';
import { PermissionListComponent } from "./permission-list/permission-list.component";
import { RequestDetailComponent } from './request-detail/request-detail.component';
import { PendingRequestListComponent } from './request-list/pending-request-list/pending-request-list.component';
import { ProcessedRequestListComponent } from './request-list/processed-request-list/processed-request-list.component';
import { RequestListComponent } from './request-list/request-list.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'roles',
    pathMatch: 'full',
  },
  {
    path: 'roles',
    data: {
      breadcrumb: {
        label: 'Permissions',
        title: 'Liste des permissions par utilisateurs et groupes.',
        iconClass: 'admin_panel_settings',
      },
    },
    children: [
      {
        path: '',
        component: PermissionListComponent,
      },
      {
        path: ':idRole',
        data: {
          breadcrumb: {
            label: 'Rôle: :idRole',
            title: 'Détail des permissions d\'un rôle.',
            iconClass: 'account_circle',
          },
        },
        children: [
          {
            path: '',
            component: PermissionDetailComponent,
          },
        ],
      },
    ],
  },
  {
    path: 'requests',
    data: {
      breadcrumb: {
        label: 'Demandes',
        title: 'Listes des demandes de permissions d\'accès.',
        iconClass: 'how_to_reg',
      },
    },
    children: [
      {
        path: '',
        component: RequestListComponent,
        children: [
          {
            path: '',
            redirectTo: 'pending',
            pathMatch: 'full',
          },
          {
            path: 'pending',
            component: PendingRequestListComponent,
          },
          {
            path: 'processed',
            component: ProcessedRequestListComponent,
          },
        ],
      },
      {
        path: 'add',
        component: AccessRequestComponent,
      },
      {
        path: ':requestToken',
        data: {
          breadcrumb: {
            label: 'Demande: :requestToken',
            title: 'Détail d\'une demande de permissions d\'accès.',
            iconClass: 'check_circle',
          },
        },
        children: [
          {
            path: '',
            component: RequestDetailComponent,
          },
        ],
      },
    ],
  },
];
