import { getItemData, isSlotWithItem } from '../helpers';
import { store } from '../store';
import { DragSource, DropTarget } from '../typings';
import { Items } from '../store/items';
import { buyItem } from '../thunks/buyItem';

export const onBuy = async (source: DragSource, target: DropTarget) => {
  const { inventory: state } = store.getState();

  const sourceInventory = state.rightInventory;
  const targetInventory = state.leftInventory;

  const sourceSlot = sourceInventory.items[source.item.slot - 1];

  if (!isSlotWithItem(sourceSlot)) throw new Error(`Item ${sourceSlot.slot} name === undefined`);

  if (sourceSlot.count === 0) return;

  const sourceName = sourceSlot.name;
  let sourceData = Items[sourceName];

  if (sourceData === undefined) {
    sourceData = (await getItemData(sourceName)) ?? Items[sourceName];
  }

  if (!sourceData) return console.error(`Item ${sourceName} data undefined!`);

  const targetSlot = targetInventory.items[target.item.slot - 1];

  if (targetSlot === undefined) return console.error(`Target slot undefined`);

  const count =
    state.itemAmount !== 0
      ? sourceSlot.count
        ? state.itemAmount > sourceSlot.count
          ? sourceSlot.count
          : state.itemAmount
        : state.itemAmount
      : 1;

  const data = {
    fromSlot: sourceSlot,
    toSlot: targetSlot,
    fromType: sourceInventory.type,
    toType: targetInventory.type,
    count: count,
  };

  store.dispatch(
    buyItem({
      ...data,
      fromSlot: sourceSlot.slot,
      toSlot: targetSlot.slot,
    })
  );
};
