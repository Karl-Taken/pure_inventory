import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { itemDurability } from '../helpers';
import { inventorySlice } from '../store/inventory';
import { Items } from '../store/items';
import { Inventory, InventoryType, Slot, State, UtilityState } from '../typings';

export type ItemsPayload = { item: Slot; inventory?: string | number; inventoryType?: InventoryType };

interface Payload {
  items?: ItemsPayload | ItemsPayload[];
  itemCount?: Record<string, number>;
  weightData?: { inventoryId: string; maxWeight: number };
  slotsData?: { inventoryId: string; slots: number };
  leftUtility?: UtilityState;
  rightUtility?: UtilityState;
  craftingXp?: { xp: number };
}

export const refreshSlotsReducer: CaseReducer<State, PayloadAction<Payload>> = (state, action) => {
  if (action.payload.items) {
    const updates = Array.isArray(action.payload.items) ? action.payload.items : [action.payload.items];
    const curTime = Math.floor(Date.now() / 1000);

    const resolveInventory = (inventoryId?: string | number, inventoryType?: InventoryType): Inventory | undefined => {
      if (inventoryId === undefined || inventoryId === null) {
        if (inventoryType === InventoryType.BACKPACK) return state.leftInventory.backpack || undefined;
        if (inventoryType === InventoryType.OTHER_BACKPACK) return state.rightInventory.backpack || undefined;
        return inventoryType === InventoryType.PLAYER ? state.leftInventory : state.rightInventory;
      }

      if (inventoryId === state.leftInventory.id || inventoryId === 'player') return state.leftInventory;
      if (state.leftInventory.backpack && inventoryId === state.leftInventory.backpack.id) return state.leftInventory.backpack;
      if (inventoryId === state.rightInventory.id) return state.rightInventory;
      if (state.rightInventory.backpack && inventoryId === state.rightInventory.backpack.id) return state.rightInventory.backpack;

      return state.rightInventory;
    };

    updates
      .filter((data) => !!data)
      .forEach((data) => {
        if (!data) return;
        const targetInventory = resolveInventory(data.inventory, data.inventoryType);
        if (!targetInventory) return;

        // Defensive: sometimes the incoming item may be a primitive (number) instead of an object
        // which would cause attempts to access properties (like .metadata) to throw. Normalize it.
        if (typeof data.item !== 'object' || data.item === null) {
          // convert numeric slot into an empty slot object { slot: <n> }
          data.item = { slot: Number(data.item) } as Slot;
        }

        data.item.durability = itemDurability(data.item.metadata, curTime);

        if (targetInventory.utility) {
          const utility = targetInventory.utility;
          const offset = utility.offset || 0;
          let utilitySlot = data.item.metadata?.utilitySlot;

          if (!utilitySlot && offset && data.item.slot >= offset) {
            utilitySlot = data.item.slot - offset;
          }

          if (utilitySlot && utilitySlot >= 1 && utilitySlot <= utility.slots) {
            const index = utilitySlot - 1;
            if (data.item.count) {
              utility.items[index] = data.item;
            } else {
              utility.items[index] = { slot: offset ? offset + utilitySlot : utilitySlot };
            }
            return;
          }
        }

        targetInventory.items[data.item.slot - 1] = data.item;
      });

    if (state.rightInventory.type === InventoryType.CRAFTING) {
      state.rightInventory = { ...state.rightInventory };
    }

  }

  if (action.payload.itemCount) {
    const entries = Object.entries(action.payload.itemCount);

    for (let i = 0; i < entries.length; i++) {
      const [name, count] = entries[i];

      if (Items[name]!) {
        Items[name]!.count += count;
      } else console.log(`Item data for ${name} is undefined`);
    }
  }

  if (action.payload.weightData) {
    const { inventoryId, maxWeight } = action.payload.weightData;

    if (inventoryId === state.leftInventory.id || inventoryId === 'player') {
      state.leftInventory.maxWeight = maxWeight;
    } else if (state.leftInventory.backpack && inventoryId === state.leftInventory.backpack.id) {
      state.leftInventory.backpack.maxWeight = maxWeight;
    } else if (inventoryId === state.rightInventory.id) {
      state.rightInventory.maxWeight = maxWeight;
    } else if (state.rightInventory.backpack && inventoryId === state.rightInventory.backpack.id) {
      state.rightInventory.backpack.maxWeight = maxWeight;
    }
  }

  if (action.payload.slotsData) {
    const { inventoryId, slots } = action.payload.slotsData;

    if (inventoryId === state.leftInventory.id || inventoryId === 'player') {
      state.leftInventory.slots = slots;
      inventorySlice.caseReducers.setupInventory(state, {
        type: 'setupInventory',
        payload: { leftInventory: state.leftInventory },
      });
    } else if (state.leftInventory.backpack && inventoryId === state.leftInventory.backpack.id) {
      const existing = state.leftInventory.backpack.items || [];
      state.leftInventory.backpack.slots = slots;
      state.leftInventory.backpack.items = Array.from(Array(slots), (_, index) => {
        const slot = index + 1;
        return existing.find((entry) => entry.slot === slot) || { slot };
      });
    } else if (inventoryId === state.rightInventory.id) {
      state.rightInventory.slots = slots;
      inventorySlice.caseReducers.setupInventory(state, {
        type: 'setupInventory',
        payload: { rightInventory: state.rightInventory },
      });
    } else if (state.rightInventory.backpack && inventoryId === state.rightInventory.backpack.id) {
      const existing = state.rightInventory.backpack.items || [];
      state.rightInventory.backpack.slots = slots;
      state.rightInventory.backpack.items = Array.from(Array(slots), (_, index) => {
        const slot = index + 1;
        return existing.find((entry) => entry.slot === slot) || { slot };
      });
    }
  }

  if (action.payload.leftUtility) {
    state.leftInventory.utility = action.payload.leftUtility;
  }

  if (action.payload.rightUtility) {
    state.rightInventory.utility = action.payload.rightUtility;
  }

  if (action.payload.craftingXp) {
    const xpValue = action.payload.craftingXp.xp;

    if (state.rightInventory.type === InventoryType.CRAFTING) {
      state.rightInventory.crafting = state.rightInventory.crafting || {};
      const xpInfo = state.rightInventory.crafting.xp;
      if (xpInfo) {
        xpInfo.current = xpValue;
      } else {
        state.rightInventory.crafting.xp = {
          enabled: true,
          current: xpValue,
        };
      }
    }
  }
};
