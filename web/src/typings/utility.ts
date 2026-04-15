import { Slot } from './slot';

export type UtilityConfig = {
  labels?: Record<number, string>;
  icons?: Record<number, string>;
  iconSizes?: Record<number, number>;
  items?: Record<number, string[]>;
  hotbarSlots?: number[];
  hotkeys?: Record<number, string>;
  quickSlotLabels?: Record<number, string>;
  tabHotkeys?: {
    inventory?: string;
    utility?: string;
  };
  layout?: Record<number, { row?: number; column?: number }>;
};

export type UtilityState = {
  slots: number;
  offset: number;
  items: Slot[];
  config?: UtilityConfig;
};
