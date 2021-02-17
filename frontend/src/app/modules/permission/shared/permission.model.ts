import { IInheritance, IPermission, IPermissionFilter } from '../permission.interface';

export class Permission implements IPermission {
  name: string;
  code: string;
  module: string;
  action: string;
  object: string;
  gathering?: string;
  endDate: string;// TODO: use Date
  filters: IPermissionFilter[];
  isInherited: boolean;
  inheritedBy: IInheritance;
}
