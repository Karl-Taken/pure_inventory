import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useDragLayer, XYCoord } from 'react-dnd';
import { DragSource, Inventory, InventoryType, Slot, SlotWithItem } from '../../typings';
import { useAppSelector } from '../../store';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';

interface DragLayerProps {
  item: DragSource | null;
  currentOffset: XYCoord | null;
  isDragging: boolean;
  initialClientOffset: XYCoord | null;
  initialSourceClientOffset: XYCoord | null;
}

const parseCssUrl = (value: string): string | undefined => {
  if (!value) return undefined;
  const match = value.match(/^url\((['"]?)(.+?)\1\)$/i);
  if (match) return match[2];
  return value;
};

const DragPreview: React.FC = () => {
  const { item, isDragging, currentOffset, initialClientOffset, initialSourceClientOffset } =
    useDragLayer<DragLayerProps>((monitor) => {
      const isDragging = monitor.isDragging();
      return {
        item: (isDragging ? monitor.getItem() : null) as DragSource | null,
        currentOffset: isDragging ? monitor.getClientOffset() : null,
        initialClientOffset: monitor.getInitialClientOffset(),
        initialSourceClientOffset: monitor.getInitialSourceClientOffset(),
        isDragging,
      };
    });

  const lastOffset = useRef<XYCoord | null>(null);
  const [previewSize, setPreviewSize] = useState<{ width: number; height: number } | null>(null);

  const { slotData, fallbackAmount } = useAppSelector((state) => {
    const fallbackAmount = state.inventory.itemAmount;

    if (!item?.item) {
      return { slotData: null, fallbackAmount };
    }

    const slotNumber = item.item.slot;
    const desiredType = item.inventory;
    const desiredId =
      item.inventoryId !== undefined && item.inventoryId !== null ? String(item.inventoryId) : undefined;

    const { leftInventory, rightInventory } = state.inventory;

    const idMatches = (inv?: Inventory | null) => {
      if (!inv) return false;

      if (desiredId === undefined) return true;

      if (inv.id === undefined || inv.id === null) {
        if (desiredType && inv.type === desiredType && desiredId === 'player') {
          return true;
        }
        return false;
      }

      return String(inv.id) === desiredId;
    };

    const findSlotInInventory = (inv?: Inventory | null): Slot | undefined => {
      if (!inv) return undefined;

      if (desiredId !== undefined && !idMatches(inv)) {
        return undefined;
      }

      if (desiredId === undefined && desiredType && inv.type !== desiredType) {
        return undefined;
      }

      return inv.items.find((slot) => slot && slot.slot === slotNumber && slot.name !== undefined);
    };

    let slot: Slot | undefined;

    switch (desiredType) {
      case InventoryType.PLAYER:
        slot = findSlotInInventory(leftInventory);
        break;
      case InventoryType.BACKPACK:
        slot = findSlotInInventory(leftInventory.backpack ?? null);
        break;
      case InventoryType.SHOP:
      case InventoryType.CRAFTING:
      case InventoryType.CONTAINER:
        slot = findSlotInInventory(rightInventory);
        break;
      case InventoryType.OTHER_BACKPACK:
        slot = findSlotInInventory(rightInventory.backpack ?? null);
        break;
      case InventoryType.UTILITY:
        slot = leftInventory.utility?.items.find((utilitySlot) => utilitySlot.slot === slotNumber);
        break;
      case InventoryType.OTHER_UTILITY:
        slot = rightInventory.utility?.items.find((utilitySlot) => utilitySlot.slot === slotNumber);
        break;
      default:
        slot = findSlotInInventory(leftInventory) ?? findSlotInInventory(rightInventory);
        break;
    }

    if (!slot) {
      const fallbackInventories: Array<Inventory | null | undefined> = [
        leftInventory,
        leftInventory.backpack,
        rightInventory,
        rightInventory.backpack,
      ];

      for (let i = 0; i < fallbackInventories.length; i++) {
        const inventory = fallbackInventories[i];
        if (!inventory) continue;

        const candidate = inventory.items.find(
          (candidateSlot) => candidateSlot && candidateSlot.slot === slotNumber && candidateSlot.name !== undefined
        );

        if (candidate) {
          slot = candidate;
          break;
        }
      }
    }

    return { slotData: slot ?? null, fallbackAmount };
  });

  const slotWithItem = useMemo(() => {
    if (!slotData) return null;
    return isSlotWithItem(slotData) ? (slotData as SlotWithItem) : null;
  }, [slotData]);

  useEffect(() => {
    if (!isDragging || !item?.item || typeof document === 'undefined') {
      setPreviewSize(null);
      return;
    }

    const slotNumber = item.item.slot;
    const desiredType = item.inventory ?? '';
    const desiredId =
      item.inventoryId !== undefined && item.inventoryId !== null ? String(item.inventoryId) : '';

    const candidates = Array.from(
      document.querySelectorAll<HTMLElement>(`.item-slot[data-slot-index="${slotNumber}"]`)
    );

    let match: HTMLElement | undefined;

    for (const candidate of candidates) {
      const { inventoryType = '', inventoryId = '' } = candidate.dataset;

      const matchesType = inventoryType === desiredType;
      const matchesId =
        desiredId === '' || inventoryId === desiredId || (!inventoryId && desiredType === inventoryType);

      if (matchesType && matchesId) {
        match = candidate;
        break;
      }
    }

    if (!match && candidates.length === 1) {
      match = candidates[0];
    }

    if (match) {
      const rect = match.getBoundingClientRect();
      setPreviewSize({ width: rect.width, height: rect.height });
    } else {
      setPreviewSize(null);
    }
  }, [isDragging, item?.item, item?.inventory, item?.inventoryId]);

  const imageSrc = useMemo(() => {
    if (slotWithItem) {
      const resolved = getItemUrl(slotWithItem);
      if (resolved) return resolved;
    }

    if (slotData && slotData.name) {
      const fromName = getItemUrl(slotData.name);
      if (fromName) return fromName;
    }

    if (item?.image) {
      const parsed = parseCssUrl(item.image);
      if (parsed) return parsed;
    }

    if (item?.item?.name) {
      return getItemUrl(item.item.name);
    }

    return undefined;
  }, [item, slotData, slotWithItem]);

  const sourceInventoryType = item?.inventory;

  const amount = useMemo(() => {
    if (sourceInventoryType === InventoryType.SHOP && fallbackAmount > 0) {
      return fallbackAmount;
    }

    if (slotWithItem) {
      if (typeof slotWithItem.count === 'number') return slotWithItem.count;
      return 1;
    }

    if (fallbackAmount > 0) {
      return fallbackAmount;
    }

    return undefined;
  }, [fallbackAmount, slotWithItem, sourceInventoryType]);

  const displayAmount = useMemo(() => {
    if (amount === undefined || amount === null) return undefined;
    return amount > 0 ? amount : 1;
  }, [amount]);

  const itemLabel = useMemo(() => {
    if (!slotWithItem) {
      if (item?.item?.name) {
        const base = Items[item.item.name]?.label ?? item.item.name;
        return base;
      }
      return '';
    }

    if (slotWithItem.metadata?.label) return slotWithItem.metadata.label;
    return Items[slotWithItem.name]?.label ?? slotWithItem.name ?? '';
  }, [item?.item?.name, slotWithItem]);

  const weightText = useMemo(() => {
    if (!slotWithItem?.weight) return '';

    if (slotWithItem.weight >= 1000) {
      return `${(slotWithItem.weight / 1000).toLocaleString('en-us', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })}kg`;
    }

    return `${slotWithItem.weight.toLocaleString('en-us', { maximumFractionDigits: 0 })}g`;
  }, [slotWithItem]);

  const durabilityValue = useMemo(() => {
    if (!slotWithItem) return null;

    const quality =
      slotWithItem.metadata?.quality ??
      slotWithItem.durability ??
      slotWithItem.metadata?.durability ??
      slotWithItem.metadata?.armorDurability;

    if (typeof quality !== 'number') return null;

    return Math.max(0, Math.min(quality, 100));
  }, [slotWithItem]);

  const durabilityClass =
    durabilityValue === null
      ? ''
      : durabilityValue > 75
        ? 'high'
        : durabilityValue > 25
          ? 'medium'
          : 'low';

  const altLabel = itemLabel || item?.item?.name || 'Dragged item';

  const priceMarkup = useMemo(() => {
    if (sourceInventoryType !== InventoryType.SHOP || !slotWithItem || slotWithItem.price === undefined) {
      return null;
    }

    if (
      slotWithItem.currency &&
      slotWithItem.currency !== 'money' &&
      slotWithItem.currency !== 'black_money' &&
      slotWithItem.price > 0
    ) {
      const currencyImage = getItemUrl(slotWithItem.currency) || undefined;
      return (
        <div className="item-slot-price icon">
          {currencyImage ? <img src={currencyImage} alt="item currency" /> : null}
          <span>{slotWithItem.price.toLocaleString('en-us')}</span>
        </div>
      );
    }

    if (slotWithItem.price > 0) {
      const isBlackMoney = slotWithItem.currency === 'black_money';
      const classes = ['item-slot-price'];
      if (isBlackMoney) classes.push('dirty');

      return (
        <div className={classes.join(' ')}>
          <span>
            {Locale.$ || '$'}
            {slotWithItem.price.toLocaleString('en-us')}
          </span>
        </div>
      );
    }

    return null;
  }, [slotWithItem, sourceInventoryType]);

  const previewClasses = useMemo(() => {
    const isUtility =
      sourceInventoryType === InventoryType.UTILITY || sourceInventoryType === InventoryType.OTHER_UTILITY;
    const baseClass = isUtility ? 'utility-slot' : 'item-slot';

    const classes = [baseClass, 'dragged-item'];
    if (slotWithItem) classes.push('has-item');

    if (!isUtility && sourceInventoryType === InventoryType.SHOP && slotWithItem?.price !== undefined) {
      classes.push('shop-slot');
    }

    const rarity = slotWithItem?.metadata?.rarity || (slotWithItem?.name ? Items[slotWithItem.name]?.rarity : undefined);
    if (rarity) {
      classes.push(`rarity-${rarity.toLowerCase()}`);
    }

    return classes.join(' ');
  }, [slotWithItem, sourceInventoryType]);

  const transform = useMemo(() => {
    if (!isDragging || !currentOffset) {
      if (!lastOffset.current) {
        return 'translate3d(-9999px, -9999px, 0)';
      }
      return `translate3d(${lastOffset.current.x}px, ${lastOffset.current.y}px, 0)`;
    }

    const sourceX = initialSourceClientOffset?.x ?? 0;
    const sourceY = initialSourceClientOffset?.y ?? 0;
    const clientX = initialClientOffset?.x ?? sourceX;
    const clientY = initialClientOffset?.y ?? sourceY;

    const nextOffset: XYCoord = {
      x: currentOffset.x - clientX + sourceX,
      y: currentOffset.y - clientY + sourceY,
    };

    lastOffset.current = nextOffset;
    return `translate3d(${nextOffset.x}px, ${nextOffset.y}px, 0)`;
  }, [currentOffset, initialClientOffset, initialSourceClientOffset, isDragging]);

  const previewStyle = useMemo<React.CSSProperties>(() => {
    const style: React.CSSProperties = {
      transform: `${transform} scale(${sourceInventoryType === InventoryType.UTILITY || sourceInventoryType === InventoryType.OTHER_UTILITY ? 0.85 : 0.85})`,
    };

    if (previewSize) {
      style.width = previewSize.width;
      style.height = previewSize.height;
    } else {
      style.width = 115;
      style.height = 115;
    }

    return style;
  }, [previewSize, transform]);

  return (
    <>
      {isDragging && item?.item && (
        <div className={previewClasses} style={previewStyle}>
          <div className="rarity-glow" />
          <div className="item-slot-content">
            <div className="item-slot-img">{imageSrc ? <img src={imageSrc} alt={altLabel} /> : null}</div>
            {displayAmount !== undefined && (
              <div className="item-slot-amount">
                <span>{displayAmount.toLocaleString('en-us')}</span>
              </div>
            )}
            {priceMarkup}
            {slotWithItem && (itemLabel || weightText) && (
              <div className="item-slot-footer">
                {itemLabel && <span className="item-name">{itemLabel}</span>}
                {weightText && <span className="item-weight">{weightText}</span>}
              </div>
            )}
            {durabilityValue !== null && (
              <div className="item-slot-durability">
                <div
                  className={`item-slot-durability-fill ${durabilityClass}`}
                  style={{ width: `${durabilityValue}%` }}
                />
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
};

export default DragPreview;
