import React, { useEffect, useMemo, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import SlideUp from '../utils/transitions/SlideUp';
import { SlotWithItem } from '../../typings';
import FallbackItemImage from '../utils/FallbackItemImage';

const HOTBAR_TIMEOUT = 3000;

const formatWeight = (weight?: number, amount?: number) => {
  if (!weight) return '0.00kg';
  const total = (weight * (amount ?? 1)) / 1000;
  return `${total.toFixed(2)}kg`;
};

const InventoryHotbar: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [handle, setHandle] = useState<NodeJS.Timeout>();
  const leftInventory = useAppSelector(selectLeftInventory);
  const utility = leftInventory.utility;
  const hotbarSlotIndexes = utility?.config?.hotbarSlots || [1, 2, 3, 4, 5];
  const quickSlotLabels = utility?.config?.quickSlotLabels;
  const resolveQuickSlotLabel = (quickSlot: number) => {
    if (Array.isArray(quickSlotLabels)) {
      return quickSlotLabels[quickSlot - 1] ?? quickSlotLabels[quickSlot];
    }

    return quickSlotLabels?.[quickSlot] ?? quickSlotLabels?.[String(quickSlot) as unknown as number];
  };
  const defaultHotkeys = hotbarSlotIndexes.map((_, index) => resolveQuickSlotLabel(index + 1) || String(index + 1));

  const inventoryFallback = useMemo(
    () =>
      hotbarSlotIndexes.map((slotIndex) => {
        const utilityItem = utility?.items?.[slotIndex - 1];
        return utilityItem && isSlotWithItem(utilityItem) ? (utilityItem as SlotWithItem) : null;
      }),
    [hotbarSlotIndexes, utility]
  );

  const [hotbarItems, setHotbarItems] = useState<Array<SlotWithItem | null>>(inventoryFallback);
  const [hotbarLabels, setHotbarLabels] = useState<string[]>(defaultHotkeys);

  useEffect(() => {
    if (!visible) {
      setHotbarItems(inventoryFallback);
      setHotbarLabels(defaultHotkeys);
    }
  }, [defaultHotkeys, inventoryFallback, visible]);

  useNuiEvent('toggleHotbar', (payload: unknown) => {
    let open: boolean | undefined;
    let incomingItems: SlotWithItem[] | undefined;
    let incomingHotkeys: string[] | undefined;

    if (typeof payload === 'boolean') {
      open = payload;
    } else if (payload && typeof payload === 'object') {
      const maybeOpen = (payload as { open?: unknown }).open;
      if (typeof maybeOpen === 'boolean') open = maybeOpen;

      const maybeItems = (payload as { items?: unknown }).items;
      if (Array.isArray(maybeItems)) incomingItems = maybeItems as SlotWithItem[];

      const maybeHotkeys = (payload as { hotkeys?: unknown }).hotkeys;
      if (Array.isArray(maybeHotkeys)) incomingHotkeys = maybeHotkeys.map((hotkey) => String(hotkey));
    }

    if (open === false) {
      setVisible(false);
      handle && clearTimeout(handle);
      setHotbarItems(inventoryFallback);
      setHotbarLabels(defaultHotkeys);
      return;
    }

    const normalizedItems = Array.from({ length: hotbarSlotIndexes.length }, (_, index) => {
      const slotItem = incomingItems?.[index];
      return slotItem && isSlotWithItem(slotItem) ? slotItem : inventoryFallback[index] ?? null;
    });

    setHotbarItems(normalizedItems);
    setHotbarLabels(
      Array.from({ length: hotbarSlotIndexes.length }, (_, index) => incomingHotkeys?.[index] || defaultHotkeys[index] || String(index + 1))
    );
    if (handle) clearTimeout(handle);
    setVisible(true);
    setHandle(
      setTimeout(() => {
        setVisible(false);
        setHandle(undefined);
      }, HOTBAR_TIMEOUT)
    );
  });

  return (
    <SlideUp in={visible}>
      <div className="hotbar-container" style={{ bottom: '2%' }}>
        <div className="hotbar">
          {Array.from({ length: hotbarSlotIndexes.length }, (_, index) => {
            const slot = index + 1;
            const slotItem = hotbarItems[index] ?? null;
            const hasItem = !!slotItem;
            const label = hasItem ? slotItem.metadata?.label ?? Items[slotItem.name]?.label ?? slotItem.name : '';
            const amount = (slotItem as any)?.amount ?? slotItem?.count ?? 0;
            const weight = hasItem ? formatWeight(slotItem?.weight ?? 0, amount) : '';
            const rarity = hasItem ? slotItem?.metadata?.rarity ?? Items[slotItem.name]?.rarity : undefined;
            const quality =
              (slotItem as any)?.info?.quality ?? (slotItem as any)?.metadata?.quality ?? slotItem?.durability;
            const durability =
              hasItem && typeof quality === 'number' ? Math.max(Math.min(quality, 100), 0) : null;
            const durabilityClass =
              durability === null ? '' : durability > 75 ? 'high' : durability > 25 ? 'medium' : 'low';

            return (
              <div key={`hotbar-slot-${slot}`} className="hotbar-slot-wrapper">
                <div className="hotbar-slot-title">HOTKEY SLOT {slot}</div>
                <div
                  className={`item-slot hotbar-slot${hasItem ? ' has-item' : ''}${rarity ? ` rarity-${rarity.toLowerCase()}` : ''}`}
                  data-hotkey={hotbarLabels[index] || slot}
                >
                  {hasItem && (
                    <div className="item-slot-content">
                      {rarity ? <div className="item-rarity-label">{rarity.toUpperCase()}</div> : null}
                      <span className="item-weight">{weight}</span>
                      <div className="item-slot-amount">
                        <span>{amount}x</span>
                      </div>
                      <div className="item-slot-img">
                        <FallbackItemImage src={getItemUrl(slotItem)} alt={label} />
                      </div>
                      <div className="item-slot-footer">
                        <span className="item-name">{label}</span>
                      </div>
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
              </div>
            );
          })}
        </div>
      </div>
    </SlideUp>
  );
};

export default InventoryHotbar;
