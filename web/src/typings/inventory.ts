import { Slot, CraftSlot } from './slot';
import { UtilityConfig, UtilityState } from './utility';

export enum InventoryType {
  PLAYER = 'player',
  SHOP = 'shop',
  CONTAINER = 'container',
  CRAFTING = 'crafting',
  UTILITY = 'utility',
  OTHER_UTILITY = 'otherUtility',
  BACKPACK = 'backpack',
  OTHER_BACKPACK = 'otherBackpack',
}

export type Inventory = {
  id: string;
  type: string;
  slots: number;
  items: Slot[];
  maxWeight?: number;
  label?: string;
  groups?: Record<string, number>;
  utility?: UtilityState;
  utilityConfig?: UtilityConfig;
  backpack?: Inventory;
  otherBackpack?: Inventory;
  storage?: Inventory;
  crafting?: {
    xp?: {
      enabled: boolean;
      current: number;
      hideLocked?: boolean;
    };
    blueprints?: Record<string, boolean>;
  queue?: any[];
  };
};
