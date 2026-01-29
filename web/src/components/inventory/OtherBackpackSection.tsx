import React from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';
import { InventoryType } from '../../typings';

const OtherBackpackSection: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const backpack = rightInventory.backpack;

  if (!backpack || backpack.slots <= 0) {
    return null;
  }

  return <InventoryGrid inventory={backpack} uiTypeOverride={InventoryType.OTHER_BACKPACK} />;
};

export default OtherBackpackSection;
