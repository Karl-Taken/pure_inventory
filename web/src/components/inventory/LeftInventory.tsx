import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';
import { InventoryType } from '../../typings';
import PlayerBackpack from './PlayerBackpack';

const LeftInventory: React.FC = () => {
  const leftInventory = useAppSelector(selectLeftInventory);

  return (
    <InventoryGrid inventory={leftInventory} uiTypeOverride={InventoryType.PLAYER} style={{ maxHeight: '86%' }}>
      <PlayerBackpack />
    </InventoryGrid>
  );
};

export default LeftInventory;
