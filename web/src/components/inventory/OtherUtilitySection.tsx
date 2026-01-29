import React from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import UtilitySlot from './UtilitySlot';
import { Locale } from '../../store/locale';
import { InventoryType } from '../../typings';

const OtherUtilitySection: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const utility = rightInventory.utility;
  const config = utility?.config;
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  if (!utility || utility.slots <= 0) {
    return null;
  }

  return (
    <div className="other-utility-section">
      <div className="utility-header">
        <span>{rightInventory.label || t('utility', 'Utility')}</span>
      </div>
      <div className="utility-slots">
        {utility.items.map((slot, index) => (
          <UtilitySlot
            key={`other-utility-slot-${index + 1}`}
            slotIndex={index + 1}
            slot={slot}
            inventoryType={InventoryType.OTHER_UTILITY}
            config={config}
          />
        ))}
      </div>
    </div>
  );
};

export default OtherUtilitySection;
