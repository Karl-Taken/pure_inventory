import React, { useMemo, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  closeSplitDialog,
  refreshSlots,
  selectLeftInventory,
  selectRightInventory,
  setAdditionalMetadata,
  setLeftBackpack,
  setupInventory,
} from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import RightInventory from './RightInventory';
import LeftInventory from './LeftInventory';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import SplitDialog from './SplitDialog';
import UtilityInventory from './UtilityInventory';

type RightPanelTab = 'inventory' | 'utility';

const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const [rightPanelTab, setRightPanelTab] = useState<RightPanelTab>('inventory');
  const dispatch = useAppDispatch();
  const rightInventory = useAppSelector(selectRightInventory);
  const leftInventory = useAppSelector(selectLeftInventory);

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    setRightPanelTab('inventory');
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
    dispatch(closeSplitDialog());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    dispatch(setupInventory(data));
    setRightPanelTab('inventory');
    !inventoryVisible && setInventoryVisible(true);
  });

  useNuiEvent<{ direction?: number }>('cycleInventoryTab', (data) => {
    const direction = data?.direction === -1 ? -1 : 1;
    setRightPanelTab(direction < 0 ? 'inventory' : 'utility');
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent<InventoryProps | false>('setPlayerBackpack', (backpack) => {
    const nextBackpack = backpack === false ? undefined : backpack;
    dispatch(setLeftBackpack(nextBackpack));
  });

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  const hasOtherBackpack = Boolean(rightInventory?.backpack && rightInventory.backpack.slots > 0);
  const hasRightInventoryPanel =
    rightInventory && rightInventory.type !== 'crafting' && rightInventory.type !== 'shop';

  const otherWrapperClasses = ['other-sections-wrapper', 'lean-right'];
  if (hasRightInventoryPanel && hasOtherBackpack) {
    otherWrapperClasses.push('other-compact');
  }

  const inventoryTabKey = leftInventory.utility?.config?.tabHotkeys?.inventory || 'Q';
  const utilityTabKey = leftInventory.utility?.config?.tabHotkeys?.utility || 'E';

  const floatingTabs = useMemo(
    () => (
      <div className="inventory-tab-group inventory-floating-tabs">
        <button
          type="button"
          className={`inventory-tab-button${rightPanelTab === 'inventory' ? ' active' : ''}`}
          onClick={() => setRightPanelTab('inventory')}
        >
          <span className="inventory-tab-key">{inventoryTabKey}</span>
          Inventory
        </button>
        <button
          type="button"
          className={`inventory-tab-button${rightPanelTab === 'utility' ? ' active' : ''}`}
          onClick={() => setRightPanelTab('utility')}
        >
          <span className="inventory-tab-key">{utilityTabKey}</span>
          Utility
        </button>
      </div>
    ),
    [inventoryTabKey, rightPanelTab, utilityTabKey]
  );

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className="inventory-container">
          <LeftInventory />
          <InventoryControl />
          <div className={otherWrapperClasses.join(' ')}>
            {rightPanelTab === 'utility' ? (
              <section className="inventory-section other-utility-section">
                <UtilityInventory sidePanel />
              </section>
            ) : (
              <RightInventory />
            )}
          </div>
          <Tooltip />
          <InventoryContext />
          <SplitDialog />
        </div>
        {floatingTabs}
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
