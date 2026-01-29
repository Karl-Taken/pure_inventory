import { canStack, findAvailableSlot, getItemData, getTargetInventory, isSlotWithItem } from '../helpers';
import { validateMove } from '../thunks/validateItems';
import { store } from '../store';
import { DragSource, DropTarget, InventoryType } from '../typings';
import { moveSlots, stackSlots, swapSlots } from '../store/inventory';
import { Items } from '../store/items';
import { fetchNui } from '../utils/fetchNui';

export const onDrop = async (source: DragSource, target?: DropTarget) => {
  const { inventory: state } = store.getState();

  if (source.inventory === InventoryType.UTILITY) {
    const utilityData = state.leftInventory.utility;
    const offset = utilityData?.offset ?? 0;
    let utilitySlot = source.metadata?.utilitySlot;

    if (!utilitySlot && offset && source.item.slot >= offset) {
      utilitySlot = source.item.slot - offset;
    }

    if (utilitySlot && utilitySlot > 0) {
      fetchNui('moveFromUtilitySlot', {
        utilitySlot,
        toSlot: target?.item.slot ?? null,
      });
    }

    return;
  }

  const { sourceInventory, targetInventory } = getTargetInventory(
    state,
    source.inventory,
    target?.inventory,
    source.inventoryId,
    target?.inventoryId
  );

  if (!targetInventory) return;

  const sourceSlot = sourceInventory.items[source.item.slot - 1];

  if (!isSlotWithItem(sourceSlot, true)) {
    return console.error(`Slot ${source.item.slot} has no item data`);
  }

  const sourceName = sourceSlot.name;
  let sourceData = Items[sourceName];

  if (sourceData === undefined) {
    sourceData = (await getItemData(sourceName)) ?? Items[sourceName];
  }

  if (!sourceData) return console.error(`${sourceName} item data undefined!`);

  // If dragging from container slot
  if (sourceSlot.metadata?.container !== undefined) {
    // Prevent storing container in container
    if (targetInventory.type === InventoryType.CONTAINER)
      return console.log(`Cannot store container ${sourceSlot.name} inside another container`);

    // Prevent dragging of container slot when opened
    if (state.rightInventory.id === sourceSlot.metadata.container)
      return console.log(`Cannot move container ${sourceSlot.name} when opened`);
  }

  const targetSlot = target
    ? targetInventory.items[target.item.slot - 1]
    : findAvailableSlot(sourceSlot, sourceData, targetInventory.items);

  if (targetSlot === undefined) return console.error('Target slot undefined!');

  // If dropping on container slot when opened
  if (targetSlot.metadata?.container !== undefined && state.rightInventory.id === targetSlot.metadata.container)
    return console.log(`Cannot swap item ${sourceSlot.name} with container ${targetSlot.name} when opened`);

  const count =
    state.shiftPressed && sourceSlot.count > 1 && sourceInventory.type !== 'shop'
      ? Math.floor(sourceSlot.count / 2)
      : state.itemAmount === 0 || state.itemAmount > sourceSlot.count
      ? sourceSlot.count
      : state.itemAmount;

  const data = {
    fromSlot: sourceSlot,
    toSlot: targetSlot,
    fromType: sourceInventory.type,
    toType: targetInventory.type,
    count: count,
    fromInventory: source.inventoryId ?? sourceInventory.id,
    toInventory: target?.inventoryId ?? targetInventory.id,
  };

  store.dispatch(
    validateMove({
      ...data,
      fromSlot: sourceSlot.slot,
      toSlot: targetSlot.slot,
    })
  );

  isSlotWithItem(targetSlot, true)
    ? sourceData.stack && canStack(sourceSlot, targetSlot)
      ? store.dispatch(
          stackSlots({
            ...data,
            toSlot: targetSlot,
          })
        )
      : store.dispatch(
          swapSlots({
            ...data,
            toSlot: targetSlot,
          })
        )
    : store.dispatch(moveSlots(data));
};
