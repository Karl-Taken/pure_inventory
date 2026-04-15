import React from 'react';
import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import OtherBackpackSection from './OtherBackpackSection';
import ShopPanel from '../Shop/ShopPanel';
import CraftingPanel from '../Crafting/CraftingPanel';

type RightInventoryProps = {
  headerExtras?: React.ReactNode;
};

const RightInventory: React.FC<RightInventoryProps> = ({ headerExtras }) => {
  const rightInventory = useAppSelector(selectRightInventory);
  const showAuxiliarySections = rightInventory?.type !== 'crafting';

  return (
    <div className="right-inventory" style={{ height: '89%' }}>
      {rightInventory?.type === 'shop' ? (
        <ShopPanel />
      ) : rightInventory?.type === 'crafting' ? (
        <CraftingPanel inventory={rightInventory} />
      ) : (
        <InventoryGrid inventory={rightInventory} headerExtras={headerExtras} />
      )}
      {showAuxiliarySections && <OtherBackpackSection />}
    </div>
  );
};

export default RightInventory;
