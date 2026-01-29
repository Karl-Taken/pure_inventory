import { Slot } from './slot';

export type UtilityConfig = {
  labels?: Record<number, string>;
  icons?: Record<number, string>;
  iconSizes?: Record<number, number>;
  items?: Record<number, string[]>;
};

export type UtilityState = {
  slots: number;
  offset: number;
  items: Slot[];
  config?: UtilityConfig;
};
