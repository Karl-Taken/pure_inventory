import React from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import UtilitySlot from './UtilitySlot';
import { Locale } from '../../store/locale';
import { InventoryType } from '../../typings';

const UtilityInventory: React.FC = () => {
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

  return (
    <div className="utility-inventory-section">
      <div className="utility-header">
        <span>{t('utility', 'Utility')}</span>
      </div>
      <div className="utility-slots">
        {utility.items.map((slot, index) => (
          <UtilitySlot
            key={`utility-slot-${index + 1}`}
            slotIndex={index + 1}
            slot={slot}
            inventoryType={InventoryType.PLAYER}
            config={config}
          />
        ))}
      </div>
    </div>
  );
};

export default UtilityInventory;
