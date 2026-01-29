
import React, { useEffect, useMemo } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { closeSplitDialog, moveSlots, setSplitAmount } from '../../store/inventory';
import { selectLeftInventory, selectRightInventory } from '../../store/inventory';
import { isSlotWithItem } from '../../helpers';
import { validateMove } from '../../thunks/validateItems';
import { InventoryType } from '../../typings';
import { Locale } from '../../store/locale';

const SplitDialog: React.FC = () => {
  const dispatch = useAppDispatch();
  const split = useAppSelector((state) => state.inventory.splitDialog);
  const leftInventory = useAppSelector(selectLeftInventory);
  const rightInventory = useAppSelector(selectRightInventory);
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const inventory = useMemo(() => {
    switch (split.inventoryType) {
      case InventoryType.PLAYER:
        return leftInventory;
      case InventoryType.BACKPACK:
        // "backpack" type usually maps to leftInventory.backpack in client logic
        return leftInventory.backpack;
      case InventoryType.OTHER_BACKPACK:
        return rightInventory.backpack;
      default:
        // If types match, use that inventory
        if (rightInventory.type === split.inventoryType) return rightInventory;
        if (leftInventory.backpack?.type === split.inventoryType) return leftInventory.backpack;
        return rightInventory;
    }
  }, [split.inventoryType, leftInventory, rightInventory]);

  const currentItem = useMemo(() => {
    if (!split.item || !inventory) return null;
    const slotIndex = split.item.slot - 1;
    const slot = inventory.items[slotIndex];
    return isSlotWithItem(slot) ? slot : null;
  }, [inventory, split.item, split.inventoryType]);

  useEffect(() => {
    if (!split.open) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        dispatch(closeSplitDialog());
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [dispatch, split.open]);

  useEffect(() => {
    if (!split.open || !currentItem) return;
    const maxAmount = Math.max((currentItem.count ?? 0) - 1, 1);
    if (split.amount > maxAmount) {
      dispatch(setSplitAmount(maxAmount));
    } else if (split.amount < 1) {
      dispatch(setSplitAmount(1));
    }
  }, [currentItem, dispatch, split.amount, split.open]);

  if (!split.open || !split.item || !currentItem) {
    return null;
  }

  const maxAmount = Math.max((currentItem.count ?? 0) - 1, 1);
  const amount = Math.min(Math.max(split.amount, 1), maxAmount);

  const handleAmountChange = (value: number) => {
    if (!Number.isFinite(value)) return;
    const sanitized = Math.min(Math.max(Math.floor(value), 1), maxAmount);
    dispatch(setSplitAmount(sanitized));
  };

  const handlePreset = (divisor: number) => {
    if (divisor <= 0) return;
    const preset = Math.max(Math.floor((currentItem.count ?? 1) / divisor), 1);
    dispatch(setSplitAmount(Math.min(preset, maxAmount)));
  };

  const findEmptySlot = () => {
    if (!inventory) return null;
    for (let i = 1; i <= inventory.slots; i++) {
      const slot = inventory.items[i - 1];
      if (!isSlotWithItem(slot)) return i;
    }
    return null;
  };

  const confirmSplit = () => {
    if (!split.item || amount <= 0 || amount >= currentItem.count) {
      dispatch(closeSplitDialog());
      return;
    }

    if (!inventory) return;

    const targetSlotNumber = findEmptySlot();
    if (!targetSlotNumber) {
      dispatch(closeSplitDialog());
      return;
    }

    dispatch(
      validateMove({
        fromSlot: currentItem.slot,
        fromType: split.inventoryType,
        toSlot: targetSlotNumber,
        toType: split.inventoryType,
        count: amount,
        fromInventory: inventory.id,
        toInventory: inventory.id,
      })
    );

    dispatch(
      moveSlots({
        fromSlot: currentItem,
        fromType: split.inventoryType,
        toSlot: { slot: targetSlotNumber },
        toType: split.inventoryType,
        count: amount,
        fromInventory: inventory.id,
        toInventory: inventory.id,
      })
    );

    dispatch(closeSplitDialog());
  };

  return (
    <div className="split-dialog">
      <div className="split-content">
        <h3>{t('ui_split', 'Split').toUpperCase()}</h3>
        <div className="split-input-group">
          <label>{t('item_quantity', 'Item Quantity')}</label>
          <input
            type="number"
            min={1}
            max={maxAmount}
            value={amount}
            onChange={(event) => handleAmountChange(event.target.valueAsNumber)}
          />
          <div className="split-slider">
            <div className="slider-marker active"></div>
          </div>
        </div>
        <div className="split-buttons">
          <button onClick={() => handlePreset(2)}>1/2</button>
          <button onClick={() => handlePreset(3)}>1/3</button>
          <button onClick={() => handlePreset(4)}>1/4</button>
        </div>
        <div className="split-actions">
          <button className="btn-cancel" onClick={() => dispatch(closeSplitDialog())}>
            {t('cancel', 'Cancel')}
          </button>
          <button className="btn-split" onClick={confirmSplit}>
            {t('ui_split', 'Split')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default SplitDialog;
