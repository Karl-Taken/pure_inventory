import React from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import UtilitySlot from './UtilitySlot';
import { Locale } from '../../store/locale';
import { InventoryType, Slot } from '../../typings';
import utilityFigure from '../../assets/svg/utility-figure.svg';

type UtilityInventoryProps = {
  sidePanel?: boolean;
  headerExtras?: React.ReactNode;
};

const UtilityInventory: React.FC<UtilityInventoryProps> = ({ sidePanel = false, headerExtras }) => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const utility = leftInventory.utility;
  const config = utility?.config;
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  if (!utility || utility.slots <= 0) {
    return null;
  }

  const quickSlotLabels = config?.quickSlotLabels || {};
  const resolveQuickSlotLabel = (quickSlot: number) => {
    if (Array.isArray(quickSlotLabels)) {
      return quickSlotLabels[quickSlot - 1] ?? quickSlotLabels[quickSlot];
    }

    return quickSlotLabels[quickSlot] ?? quickSlotLabels[String(quickSlot) as unknown as number];
  };
  const offset = utility.offset || 0;

  const createEmptySlot = (slotIndex: number): Slot => ({
    slot: offset > 0 ? offset + slotIndex : slotIndex,
  });

  const getSlot = (slotIndex: number): Slot => utility.items[slotIndex - 1] ?? createEmptySlot(slotIndex);

  const displaySlots = {
    backpack: { slotIndex: 1, slot: getSlot(1) },
    armor: { slotIndex: 2, slot: getSlot(2) },
    phone: { slotIndex: 3, slot: getSlot(3) },
    parachute: { slotIndex: 4, slot: getSlot(4) },
    weapon1: { slotIndex: 5, slot: getSlot(5) },
    weapon2: { slotIndex: 6, slot: getSlot(6) },
    hot1: { slotIndex: 7, slot: getSlot(7) },
    hot2: { slotIndex: 8, slot: getSlot(8) },
    hot3: { slotIndex: 9, slot: getSlot(9) },
  };

  const slotQuickOrder: Partial<Record<number, number>> = {
    5: 1,
    6: 2,
    7: 3,
    8: 4,
    9: 5,
  };

  const renderSlot = (key: string, entry: { slotIndex: number; slot: Slot }) => (
    <UtilitySlot
      key={key}
      slotIndex={entry.slotIndex}
      slot={entry.slot}
      inventoryType={InventoryType.PLAYER}
      config={config}
      hotkeyLabel={entry.slotIndex >= 5 ? resolveQuickSlotLabel(slotQuickOrder[entry.slotIndex] || 0) : undefined}
    />
  );

  return (
    <div className={`utility-inventory-section utility-tab-panel${sidePanel ? ' side-panel' : ''}`}>
      {!sidePanel && (
        <div className="utility-header utility-tabs-header">
          <span>{t('utility', 'Utility')}</span>
        </div>
      )}
      <div className="utility-layout utility-layout-explicit">
        <div className="utility-side-column utility-side-column-left">
          {renderSlot('backpack', displaySlots.backpack)}
          {renderSlot('armor', displaySlots.armor)}
          {renderSlot('phone', displaySlots.phone)}
        </div>

        <div className="utility-center-column">
          <div className="utility-figure-card">
            <img className="utility-figure" src={utilityFigure} alt="" />
          </div>
        </div>

        <div className="utility-side-column utility-side-column-right">
          {renderSlot('parachute', displaySlots.parachute)}
          {renderSlot('weapon1', displaySlots.weapon1)}
          {renderSlot('weapon2', displaySlots.weapon2)}
        </div>

        <div className="utility-bottom-row">
          {renderSlot('hot1', displaySlots.hot1)}
          {renderSlot('hot2', displaySlots.hot2)}
          {renderSlot('hot3', displaySlots.hot3)}
        </div>
      </div>
    </div>
  );
};

export default UtilityInventory;
