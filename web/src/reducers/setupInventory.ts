import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { getItemData, itemDurability } from '../helpers';
import { Items } from '../store/items';
import { Inventory, State } from '../typings';

export const normaliseInventory = (
  inventory?: Inventory,
  curTime: number = Math.floor(Date.now() / 1000)
): Inventory | undefined => {
  if (!inventory) return undefined;

  const mappedItems = Array.from(Array(inventory.slots), (_, index) => {
    const slot = index + 1;
    const matchedItem = Object.values(inventory.items).find((entry) => entry?.slot === slot) || { slot };

    if (!matchedItem.name) return matchedItem;

    if (typeof Items[matchedItem.name] === 'undefined') {
      getItemData(matchedItem.name);
    }

    matchedItem.durability = itemDurability(matchedItem.metadata, curTime);
    return matchedItem;
  });

  const normalised: Inventory = {
    ...inventory,
    items: mappedItems,
  };

  if (inventory.backpack) {
    const backpack = normaliseInventory(inventory.backpack, curTime);
    if (backpack) normalised.backpack = backpack;
    else delete normalised.backpack;
  } else {
    delete normalised.backpack;
  }

  if (inventory.otherBackpack) {
    const otherBackpack = normaliseInventory(inventory.otherBackpack, curTime);
    if (otherBackpack) normalised.otherBackpack = otherBackpack;
    else delete normalised.otherBackpack;
  } else {
    delete normalised.otherBackpack;
  }

  if (inventory.storage) {
    const storage = normaliseInventory(inventory.storage, curTime);
    if (storage) normalised.storage = storage;
    else delete normalised.storage;
  } else {
    delete normalised.storage;
  }

  return normalised;
};

export const setupInventoryReducer: CaseReducer<
  State,
  PayloadAction<{
    leftInventory?: Inventory;
    rightInventory?: Inventory;
  }>
> = (state, action) => {
  const { leftInventory, rightInventory } = action.payload;
  const curTime = Math.floor(Date.now() / 1000);

  const normalisedLeft = normaliseInventory(leftInventory, curTime);
  if (normalisedLeft) state.leftInventory = normalisedLeft;

  const normalisedRight = normaliseInventory(rightInventory, curTime);
  if (normalisedRight) state.rightInventory = normalisedRight;

  state.shiftPressed = false;
  state.isBusy = false;
};
