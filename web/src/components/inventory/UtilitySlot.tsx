import React, { useEffect, useMemo } from 'react';
import { useDrag, useDragDropManager, useDrop } from 'react-dnd';
import { useMergeRefs } from '@floating-ui/react';
import { DragSource, InventoryType, Slot, SlotWithItem, UtilityConfig } from '../../typings';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { useAppDispatch } from '../../store';
import { fetchNui } from '../../utils/fetchNui';
import vestIcon from '../../assets/svg/vest.svg';
import backpackIcon from '../../assets/svg/backpack.svg';
import othersIcon from '../../assets/svg/others.svg';
import pocketIcon from '../../assets/svg/pocket.svg';
import phoneIcon from '../../assets/svg/phone.svg';
import parachuteIcon from '../../assets/svg/parachute.svg';
import { Items } from '../../store/items';
import useNuiEvent from '../../hooks/useNuiEvent';
import { ItemsPayload } from '../../reducers/refreshSlots';
import { openContextMenu } from '../../store/contextMenu';
import FallbackItemImage from '../utils/FallbackItemImage';

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
      const img = new Image();
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      return img;
    })()
    : undefined;

type UtilitySlotProps = {
  slotIndex: number;
  slot: Slot;
  inventoryType: InventoryType;
  config?: UtilityConfig;
  hotkeyLabel?: string;
  style?: React.CSSProperties;
};

const iconMap: Record<string, string> = {
  'vest': vestIcon,
  'vest.svg': vestIcon,
  'backpack': backpackIcon,
  'backpack.svg': backpackIcon,
  'others': othersIcon,
  'others.svg': othersIcon,
  'pocket': pocketIcon,
  'pocket.svg': pocketIcon,
  'phone': phoneIcon,
  'phone.svg': phoneIcon,
  'parachute': parachuteIcon,
  'parachute.svg': parachuteIcon,
};

const UtilitySlot: React.FC<UtilitySlotProps> = ({ slotIndex, slot, inventoryType, config, hotkeyLabel, style }) => {
  const manager = useDragDropManager();
  const dispatch = useAppDispatch();
  const hasItem = isSlotWithItem(slot);
  const slotItem = hasItem ? (slot as SlotWithItem) : null;
  const zeroIndex = slotIndex - 1;

  const resolveConfigValue = <T,>(
    collection:
      | Record<string, T | undefined>
      | Record<number, T | undefined>
      | Array<T | undefined>
      | undefined
  ): T | undefined => {
    if (!collection) return undefined;

    if (Array.isArray(collection)) {
      return collection[zeroIndex] ?? collection[slotIndex];
    }

    const asRecord = collection as Record<string | number, T | undefined>;
    const indexKey = slotIndex.toString();
    const zeroKey = zeroIndex.toString();
    const direct =
      asRecord[indexKey] ??
      asRecord[zeroKey] ??
      asRecord[slotIndex] ??
      asRecord[zeroIndex];

    if (direct !== undefined) {
      return direct;
    }

    const numericCandidates = Object.entries(asRecord)
      .map(([key, value]) => ({ key: Number(key), value }))
      .filter((entry) => !Number.isNaN(entry.key))
      .sort((a, b) => a.key - b.key);

    if (numericCandidates.length > 0) {
      return (
        numericCandidates[zeroIndex]?.value ??
        numericCandidates.find((entry) => entry.key === slotIndex)?.value ??
        numericCandidates.find((entry) => entry.key === zeroIndex)?.value
      );
    }

    const orderedEntries = Object.entries(asRecord);
    return orderedEntries[zeroIndex]?.[1] ?? orderedEntries[slotIndex]?.[1];
  };

  const iconKeyRaw = resolveConfigValue(config?.icons);
  const iconKey = typeof iconKeyRaw === 'string' ? iconKeyRaw.trim() : undefined;
  const iconMapKey = iconKey ? iconKey.toLowerCase() : undefined;
  const fallbackIcon = iconMap['others'] ?? iconMap['others.svg'] ?? othersIcon;
  const iconSource =
    (iconMapKey && iconMap[iconMapKey]) ||
    (iconKey && iconKey.includes('/') ? iconKey : fallbackIcon);

  const iconSizeRaw = resolveConfigValue(config?.iconSizes);
  const iconSize = typeof iconSizeRaw === 'number' && iconSizeRaw > 0 ? iconSizeRaw : undefined;

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
      }),
      canDrop: (source) =>
        inventoryType === InventoryType.PLAYER &&
        (source.inventory === InventoryType.PLAYER || source.inventory === InventoryType.UTILITY),
      drop: (source) => {
        if (inventoryType !== InventoryType.PLAYER) return;
        fetchNui<boolean>('moveToUtilitySlot', {
          utilitySlot: slotIndex,
          fromSlot: source.item.slot,
          fromUtilitySlot:
            typeof source.metadata?.utilitySlot === 'number' ? source.metadata.utilitySlot : undefined,
        });
      },
    }),
    [inventoryType, slotIndex]
  );

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
      canDrag: () => inventoryType === InventoryType.PLAYER && hasItem,
      item: () => {
        if (!hasItem || !slotItem) return null;
        return {
          inventory: InventoryType.UTILITY,
          item: { name: slotItem.name, slot: slotItem.slot },
          metadata: slotItem.metadata,
          image: `url(${getItemUrl(slotItem) || 'none'})`,
        };
      },
    }),
    [hasItem, inventoryType, slotItem]
  );

  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  useNuiEvent('refreshSlots', (data: { items?: ItemsPayload | ItemsPayload[] }) => {
    if (!isDragging || !data.items) return;
    if (!Array.isArray(data.items)) return;

    const matchingUpdate = data.items.find((entry) => entry.item?.slot === slot.slot);

    if (!matchingUpdate) return;

    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  const refs = useMergeRefs([drop, drag, preview]);

  const resolvedLabelRaw = resolveConfigValue(config?.labels);
  const configuredLabel = typeof resolvedLabelRaw === 'string' ? resolvedLabelRaw : resolvedLabelRaw ? String(resolvedLabelRaw) : '';

  const itemLabel = useMemo(() => {
    if (!hasItem || !slotItem) return configuredLabel;
    return slotItem.metadata?.label ?? Items[slotItem.name]?.label ?? slotItem.name;
  }, [configuredLabel, hasItem, slotItem]);

  const iconStyle = iconSize ? { width: `${iconSize}px`, height: `${iconSize}px` } : undefined;

  const amountText = slotItem?.count ? slotItem.count.toLocaleString('en-us') : '';
  const weightText = useMemo(() => {
    if (!hasItem || !slotItem?.weight) return '';
    if (slotItem.weight >= 1000) {
      return `${(slotItem.weight / 1000).toFixed(2)}kg`;
    }
    return `${slotItem.weight.toFixed(0)}g`;
  }, [hasItem, slotItem]);

  const quality =
    slotItem?.metadata?.quality ??
    slotItem?.durability ??
    slotItem?.metadata?.durability ??
    slotItem?.metadata?.armorDurability;
  const durability =
    hasItem && typeof quality === 'number'
      ? Math.max(Math.min(quality, 100), 0)
      : null;
  const durabilityClass =
    durability === null ? '' : durability > 75 ? 'high' : durability > 25 ? 'medium' : 'low';

  const rarity = hasItem && slotItem ? (slotItem.metadata?.rarity || Items[slotItem.name]?.rarity) : undefined;
  const rarityClass = rarity ? ` rarity-${rarity.toLowerCase()}` : '';
  const utilityHotkeyProps = hotkeyLabel ? { 'data-hotkey': hotkeyLabel } : {};

  const handleContext = (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();

    if (inventoryType !== InventoryType.PLAYER || !slotItem) return;

    dispatch(
      openContextMenu({
        item: slotItem,
        coords: { x: event.clientX, y: event.clientY },
        inventoryType: InventoryType.PLAYER,
      })
    );
  };

  return (
    <div
      ref={refs}
      onContextMenu={handleContext}
      className={`utility-slot${hasItem ? ' has-item' : ''}${isOver ? ' drag-over' : ''}${rarityClass}`}
      data-slot={slot.slot}
      data-slot-index={slot.slot}
      data-inventory-type={inventoryType}
      data-inventory-id=""
      data-utility={slotIndex}
      {...utilityHotkeyProps}
      style={{
        opacity: isDragging ? 0.4 : 1,
        '--borderColor': rarity ? '#ffffff' : undefined,
        ...style,
      } as React.CSSProperties}
    >
      <div className="rarity-glow" />
      {configuredLabel && <div className="utility-slot-label">{configuredLabel}</div>}
      {iconSource && <img className="utility-slot-icon" src={iconSource} alt="" style={iconStyle} />}
      {hasItem && slotItem && (
        <div className="item-slot-content">
          {rarity ? <div className="item-rarity-label">{rarity.toUpperCase()}</div> : null}
          {amountText && (
            <div className="item-slot-amount">
              <span>{amountText}x</span>
            </div>
          )}
          <div className="item-slot-img">
            <FallbackItemImage src={getItemUrl(slotItem)} alt={itemLabel} />
          </div>
          <div className="item-slot-footer">
            <span className="item-name">{itemLabel}</span>
          </div>
          <span className="item-weight">{weightText}</span>
          {durability !== null && (
            <div className="item-slot-durability">
              <div
                className={`item-slot-durability-fill ${durabilityClass}`}
                style={{ width: `${durability}%` }}
              />
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default UtilitySlot;
