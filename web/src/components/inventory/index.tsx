import React, { useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  closeSplitDialog,
  refreshSlots,
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
const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const dispatch = useAppDispatch();
  const rightInventory = useAppSelector(selectRightInventory);

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
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
    !inventoryVisible && setInventoryVisible(true);
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

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className="inventory-container">
          <LeftInventory />
          <InventoryControl />
          <UtilityInventory />
          <div className={otherWrapperClasses.join(' ')}>
            <RightInventory />
          </div>
          <Tooltip />
          <InventoryContext />
          <SplitDialog />
        </div>
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
