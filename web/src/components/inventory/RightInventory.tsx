import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import OtherUtilitySection from './OtherUtilitySection';
import OtherBackpackSection from './OtherBackpackSection';
import ShopPanel from '../Shop/ShopPanel';
import CraftingPanel from '../Crafting/CraftingPanel';

const RightInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const showAuxiliarySections = rightInventory?.type !== 'crafting';

  return (
    <div className="right-inventory" style={{ height: '89%' }}>
      {rightInventory?.type === 'shop' ? (
        <ShopPanel />
      ) : rightInventory?.type === 'crafting' ? (
        <CraftingPanel inventory={rightInventory} />
      ) : (
        <InventoryGrid inventory={rightInventory} />
      )}
      {showAuxiliarySections && <OtherBackpackSection />}
      {/* {showAuxiliarySections && <OtherUtilitySection />} */}
    </div>
  );
};

export default RightInventory;
