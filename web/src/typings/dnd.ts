import { Inventory } from './inventory';
import { Slot, SlotWithItem } from './slot';

export type DragSource = {
  item: Pick<SlotWithItem, 'slot' | 'name'>;
  inventory: Inventory['type'];
  inventoryId?: string | number;
  image?: string;
  metadata?: SlotWithItem['metadata'];
};

export type DropTarget = {
  item: Pick<Slot, 'slot'>;
  inventory: Inventory['type'];
  inventoryId?: string | number;
};
