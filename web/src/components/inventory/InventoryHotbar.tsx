import React, { useEffect, useMemo, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import SlideUp from '../utils/transitions/SlideUp';
import { SlotWithItem } from '../../typings';

const HOTBAR_SLOTS = 5;
const HOTBAR_TIMEOUT = 3000;

const formatWeight = (weight?: number, amount?: number) => {
  if (!weight) return '0.00kg';
  const total = (weight * (amount ?? 1)) / 1000;
  return `${total.toFixed(2)}kg`;
};

const InventoryHotbar: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [handle, setHandle] = useState<NodeJS.Timeout>();
  const inventoryItems = useAppSelector(selectLeftInventory).items;

  const inventoryFallback = useMemo(
    () =>
      inventoryItems.slice(0, HOTBAR_SLOTS).map((item) =>
        isSlotWithItem(item) ? (item as SlotWithItem) : null
      ),
    [inventoryItems]
  );

  const [hotbarItems, setHotbarItems] = useState<Array<SlotWithItem | null>>(inventoryFallback);

  useEffect(() => {
    if (!visible) {
      setHotbarItems(inventoryFallback);
    }
  }, [inventoryFallback, visible]);

  useNuiEvent('toggleHotbar', (payload: unknown) => {
    let open: boolean | undefined;
    let incomingItems: SlotWithItem[] | undefined;

    if (typeof payload === 'boolean') {
      open = payload;
    } else if (payload && typeof payload === 'object') {
      const maybeOpen = (payload as { open?: unknown }).open;
      if (typeof maybeOpen === 'boolean') open = maybeOpen;

      const maybeItems = (payload as { items?: unknown }).items;
      if (Array.isArray(maybeItems)) incomingItems = maybeItems as SlotWithItem[];
    }

    if (open === false) {
      setVisible(false);
      handle && clearTimeout(handle);
      setHotbarItems(inventoryFallback);
      return;
    }

    const normalizedItems = Array.from({ length: HOTBAR_SLOTS }, (_, index) => {
      const slotItem = incomingItems?.[index];
      return slotItem && isSlotWithItem(slotItem) ? slotItem : inventoryFallback[index] ?? null;
    });

    setHotbarItems(normalizedItems);
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
          {Array.from({ length: HOTBAR_SLOTS }, (_, index) => {
            const slot = index + 1;
            const slotItem = hotbarItems[index] ?? null;
            const hasItem = !!slotItem;
            const label = hasItem ? slotItem.metadata?.label ?? Items[slotItem.name]?.label ?? slotItem.name : '';
            const amount = (slotItem as any)?.amount ?? slotItem?.count ?? 0;
            const weight = hasItem ? formatWeight(slotItem?.weight ?? 0, amount) : '';
            const quality =
              (slotItem as any)?.info?.quality ?? (slotItem as any)?.metadata?.quality ?? slotItem?.durability;
            const durability =
              hasItem && typeof quality === 'number' ? Math.max(Math.min(quality, 100), 0) : null;
            const durabilityClass =
              durability === null ? '' : durability > 75 ? 'high' : durability > 25 ? 'medium' : 'low';

            return (
              <div key={`hotbar-slot-${slot}`} className={`item-slot hotbar-slot${hasItem ? ' has-item' : ''}`} data-hotkey={slot}>
                {/* <div className="item-slot-key">
                  <span>{slot}</span>
                </div> */}
                {hasItem && (
                  <div className="item-slot-content">
                    <div className="item-slot-amount">
                      <span>x{amount}</span>
                    </div>
                    <div className="item-slot-img">
                      <img src={getItemUrl(slotItem)} alt={label} />
                    </div>
                    <div className="item-slot-footer">
                      <span className="item-name">{label}</span>
                      <span className="item-weight">{weight}</span>
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
            );
          })}
        </div>
      </div>
    </SlideUp>
  );
};

export default InventoryHotbar;
