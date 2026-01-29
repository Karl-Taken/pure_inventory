import React from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';
import { InventoryType } from '../../typings';

const PlayerBackpack: React.FC = () => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const backpack = leftInventory.backpack;

  if (!backpack || backpack.slots <= 0) {
    return null;
  }

  return <InventoryGrid inventory={backpack} uiTypeOverride={InventoryType.BACKPACK} />;
};

export default PlayerBackpack;
