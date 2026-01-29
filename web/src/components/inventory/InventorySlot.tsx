import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { DragSource, Inventory, InventoryType, Slot, SlotWithItem } from '../../typings';
import { useDrag, useDragDropManager, useDrop } from 'react-dnd';
import { useAppDispatch } from '../../store';
import { onDrop } from '../../dnd/onDrop';
import { onBuy } from '../../dnd/onBuy';
import { Items } from '../../store/items';
import { canCraftItem, canPurchaseItem, getItemUrl, isSlotWithItem } from '../../helpers';
import { onUse } from '../../dnd/onUse';
import { Locale } from '../../store/locale';
import { onCraft } from '../../dnd/onCraft';
import useNuiEvent from '../../hooks/useNuiEvent';
import { ItemsPayload } from '../../reducers/refreshSlots';
import { closeTooltip, openTooltip } from '../../store/tooltip';
import { openContextMenu } from '../../store/contextMenu';
import { useMergeRefs } from '@floating-ui/react';

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
      const img = new Image();
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      return img;
    })()
    : undefined;

interface SlotProps {
  inventoryId: Inventory['id'];
  inventoryType: Inventory['type'];
  inventoryGroups: Inventory['groups'];
  item: Slot;
}

const InventorySlot: React.ForwardRefRenderFunction<HTMLDivElement, SlotProps> = (
  { item, inventoryId, inventoryType, inventoryGroups },
  ref
) => {
  const manager = useDragDropManager();
  const dispatch = useAppDispatch();
  const timerRef = useRef<number | null>(null);

  const canDrag = useCallback(() => {
    return canPurchaseItem(item, { type: inventoryType, groups: inventoryGroups }) && canCraftItem(item, inventoryType);
  }, [item, inventoryType, inventoryGroups]);

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
      item: () =>
        isSlotWithItem(item, inventoryType !== InventoryType.SHOP)
          ? {
            inventory: inventoryType,
            inventoryId,
            item: { name: item.name, slot: item.slot },
            image: item?.name ? `url(${getItemUrl(item) || 'none'})` : undefined,
            metadata: item.metadata,
          }
          : null,
      canDrag,
    }),
    [inventoryType, item]
  );



  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
      }),
      drop: (source) => {
        dispatch(closeTooltip());
        switch (source.inventory) {
          case InventoryType.SHOP:
            onBuy(source, { inventory: inventoryType, item: { slot: item.slot } });
            break;
          case InventoryType.CRAFTING:
            onCraft(source, { inventory: inventoryType, item: { slot: item.slot } });
            break;
          default:
            onDrop(source, { inventory: inventoryType, inventoryId, item: { slot: item.slot } });
            break;
        }
      },
      canDrop: (source) =>
        (source.item.slot !== item.slot || source.inventory !== inventoryType) &&
        inventoryType !== InventoryType.SHOP &&
        inventoryType !== InventoryType.CRAFTING,
    }),
    [inventoryType, item]
  );

  useNuiEvent('refreshSlots', (data: { items?: ItemsPayload | ItemsPayload[] }) => {
    if (!isDragging && !data.items) return;
    if (!Array.isArray(data.items)) return;

    const itemSlot = data.items.find(
      (dataItem) => dataItem.item.slot === item.slot && dataItem.inventory === inventoryId
    );

    if (!itemSlot) return;

    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  const connectRef = (element: HTMLDivElement) => drag(drop(element));

  const handleContext = (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();

    const isPlayerSlot = inventoryType === InventoryType.PLAYER;
    const isPlayerBackpackSlot = inventoryType === InventoryType.BACKPACK;

    if (!(isPlayerSlot || isPlayerBackpackSlot) || !isSlotWithItem(item)) return;

    dispatch(
      openContextMenu({
        item,
        coords: { x: event.clientX, y: event.clientY },
        inventoryType,
        inventoryId,
      })
    );
  };

  const handleClick = (event: React.MouseEvent<HTMLDivElement>) => {
    dispatch(closeTooltip());
    if (timerRef.current) clearTimeout(timerRef.current);
    if (event.ctrlKey && isSlotWithItem(item) && inventoryType !== 'shop' && inventoryType !== 'crafting') {
      // Include inventoryId so reverse (right -> left) fast stack moves work correctly.
      // Previously missing inventoryId caused server-side validation to fail for non-player inventories.
      onDrop({ item: item, inventory: inventoryType, inventoryId });
    } else if (event.altKey && isSlotWithItem(item) && inventoryType === 'player') {
      onUse(item);
    }
  };

  const refs = useMergeRefs([connectRef, ref]);

  const hasItem = isSlotWithItem(item);
  const slotClasses = useMemo(() => {
    const classes = ['item-slot'];
    if (hasItem) {
      classes.push('has-item');
      const rarity = item.metadata?.rarity || Items[item.name]?.rarity;
      if (rarity) {
        classes.push(`rarity-${rarity.toLowerCase()}`);
      }
    }
    if (!canPurchaseItem(item, { type: inventoryType, groups: inventoryGroups }) || !canCraftItem(item, inventoryType)) {
      classes.push('slot-restricted');
    }
    if (isOver) classes.push('drag-over');
    if (isDragging) classes.push('dragging');
    return classes.join(' ');
  }, [hasItem, inventoryType, inventoryGroups, item, isOver, isDragging]);


  const itemLabel = useMemo(() => {
    if (!hasItem) return '';
    if (item.metadata?.label) return item.metadata.label;
    return Items[item.name]?.label || item.name;
  }, [hasItem, item]);

  const itemWeightText = useMemo(() => {
    if (!hasItem || !item.weight) return '';
    if (item.weight >= 1000) {
      return `${(item.weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 2 })}kg`;
    }
    return `${item.weight.toLocaleString('en-us', { minimumFractionDigits: 0 })}g`;
  }, [hasItem, item]);

  const durabilityValue = hasItem && item.durability !== undefined ? Math.max(Math.min(item.durability, 100), 0) : null;
  const durabilityClass =
    durabilityValue === null
      ? ''
      : durabilityValue > 75
        ? 'high'
        : durabilityValue > 25
          ? 'medium'
          : 'low';

  const priceMarkup = () => {
    if (inventoryType !== InventoryType.SHOP || !hasItem || item.price === undefined) return null;

    if (item.currency && item.currency !== 'money' && item.currency !== 'black_money' && item.price > 0) {
      return (
        <div className="item-slot-price icon">
          <img src={item.currency ? getItemUrl(item.currency) : 'none'} alt="item currency" />
          <span>{item.price.toLocaleString('en-us')}</span>
        </div>
      );
    }

    if (item.price > 0) {
      const isBlackMoney = item.currency === 'black_money';
      const classes = ['item-slot-price'];
      if (isBlackMoney) classes.push('dirty');

      return (
        <div className={classes.join(' ')}>
          <span>
            {Locale.$ || '$'}
            {item.price.toLocaleString('en-us')}
          </span>
        </div>
      );
    }

    return null;
  };

  const hotkey = inventoryType === InventoryType.PLAYER && item.slot <= 5 ? String(item.slot) : undefined;

  return (
    <div
      ref={refs}
      onContextMenu={handleContext}
      onClick={handleClick}
      className={slotClasses}
      data-slot={item.slot}
      data-slot-index={item.slot}
      data-inventory-type={inventoryType}
      data-inventory-id={inventoryId !== undefined && inventoryId !== null ? String(inventoryId) : ''}
      data-hotkey={hotkey}
      style={{
        opacity: isDragging ? 0.4 : 1.0,
      }}
    >
      <div className="rarity-glow" />
      {hasItem && (
        <div
          className="item-slot-content"
          onMouseEnter={() => {
            timerRef.current = window.setTimeout(() => {
              dispatch(openTooltip({ item, inventoryType }));
            }, 500) as unknown as number;
          }}
          onMouseLeave={() => {
            dispatch(closeTooltip());
            if (timerRef.current) {
              clearTimeout(timerRef.current);
              timerRef.current = null;
            }
          }}
        >
          {item.metadata?.rarity || Items[item.name]?.rarity ? (
            <div className="item-rarity-label">
              {(item.metadata?.rarity || Items[item.name]?.rarity).toUpperCase()}
            </div>
          ) : null}
          <div className="item-slot-amount">{item.count ? <span>{item.count.toLocaleString('en-us')}x</span> : null}</div>
          <div className="item-slot-img">
            <img src={getItemUrl(item)} alt={itemLabel} />
          </div>
          {priceMarkup()}
          <div className="item-slot-footer">
            <span className="item-name">{itemLabel}</span>
            <span className="item-weight">{itemWeightText}</span>
          </div>
          {durabilityValue !== null && inventoryType !== InventoryType.SHOP && (
            <div className="item-slot-durability">
              <div className={`item-slot-durability-fill ${durabilityClass}`} style={{ width: `${durabilityValue}%` }} />
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default React.memo(React.forwardRef(InventorySlot));




