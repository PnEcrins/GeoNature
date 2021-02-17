import { TemplateRef } from '@angular/core';

export interface IPermissionRequestDatatableColumn {
  prop: string;
  name: string;
  flexGrow: number;
  sortable?: boolean;
  resizeable?: boolean;
  tooltip?: string;
  searchable?: boolean;
  headerClass?: string;
  cellTemplate?: TemplateRef<any>;
  headerTemplate?: TemplateRef<any>;
}

// PERMISSIONS REQUESTS
export interface IPermissionRequest {
  token: string;
  userName: string;
  organismName: string;
  geographicFilters?: number[];
  geographicFiltersLabels?: string[];
  taxonomicFilters?: number[];
  taxonomicFiltersLabels?: string[];
  sensitiveAccess?: boolean;
  endAccessDate?: string;// TODO: use Date
  processedState?: string;
  processedDate?: string;// TODO: use DateTime
  processedBy?: IRolePermission;
  refusalReason?: string;
  additionalData?: IAdditionalData[];
  metaCreateDate?: string;
  metaUpdateDate?: string;
}

export interface IAdditionalData {
  type: string;
  key: string;
  value: any;
  label?: string;
  icon?: string;
  iconSet?: string;
}

// PERMISSIONS ROLE
export interface IRolePermission {
  id: number;
  userName: string;
  organismName?: string;
  type: 'USER' | 'GROUP';
  permissionsNbr?: number;
  permissions?: Record<string, IPermission[]>;// Not use in list to decrease bandwidth consumption.
  groups?: IGroupPermission[]
}

export interface IGroupPermission {
  id: number;
  groupName: string;
}

export interface IPermission {
  name: string;
  code: string;
  gathering?: string;
  module: string;
  action: string;
  object: string;
  endDate: string;// TODO: use Date
  //filters: Record<string, IPermissionFilter[]>;
  filters: IPermissionFilter[];
  isInherited: boolean;
  inheritedBy: IInheritance;
}

export interface IPermissionFilter {
  type: string;
  value: any;
  label?: string | string[];
}

export interface IInheritance {
  byModule: boolean;
  moduleCode: string;
  objectCode: string;
  byGroup: boolean;
  groupName: string;
}

// OBJECT
export interface IObject {
  id: number
  code: string;
  description: string;
}

// MODULES
export interface IModule {
  id: number;
  code: string;
  label: string;
  picto?: string;
  desc?: string;
  group?: string;
  path?: string;
  externalUrl?: string;
  target?: string;
  comment?: string;
  activatedFrontend: boolean;
  activatedBackend: boolean;
  docUrl?: URL;
  order?: number;
}

// ACTION-OJBECT (= PERMISSION)
export interface IActionObject {
  moduleCode: string;
  actionCode: string;
  objectCode: string;
  label: string;
}

export interface IFilter {
  moduleCode: string;
  actionCode: string;
  objectCode: string;
  filterTypeCode: string;
  code: string;
  description: string;
}

export interface IFilterValue {
  id: number;
  filterTypeCode: string;
  filterTypeId: number;
  label: string;
  description: string;
  predefined: boolean;
  valueFormat: string;
  valueOrField: string;
  value?: string | number | boolean;
}
