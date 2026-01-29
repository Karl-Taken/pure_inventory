import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { isSlotWithItem, findAvailableSlot } from '../../helpers';
import { setClipboard } from '../../utils/setClipboard';
import { store, useAppDispatch, useAppSelector } from '../../store';
import React from 'react';
import { Menu, MenuItem } from '../utils/menu/Menu';
import { openSplitDialog } from '../../store/inventory';
import { closeContextMenu } from '../../store/contextMenu';
import { InventoryType, SlotWithItem, Slot } from '../../typings';

interface DataProps {
  action: string;
  component?: string;
  slot?: number;
  serial?: string;
  id?: number;
}

interface Button {
  label: string;
  index: number;
  group?: string;
}

interface Group {
  groupName: string | null;
  buttons: ButtonWithIndex[];
}

interface ButtonWithIndex extends Button {
  index: number;
}

interface GroupedButtons extends Array<Group> { }

type MoveResponse = { success: boolean; slot?: number; error?: string };

const InventoryContext: React.FC = () => {
  const contextMenu = useAppSelector((state) => state.contextMenu);
  const item = contextMenu.item;
  const inventoryType = contextMenu.inventoryType || InventoryType.PLAYER;
  const inventoryId = contextMenu.inventoryId ?? undefined;
  const isPlayerInventory = inventoryType === InventoryType.PLAYER;
  const dispatch = useAppDispatch();

  const ensureItemInPockets = async (): Promise<number | null> => {
    if (!item) return null;

    if (isPlayerInventory) {
      return item.slot;
    }

    if (!inventoryId) {
      return null;
    }

    if (!item.name) return null;

    const state = store.getState().inventory;
    const playerInventory = state.leftInventory;
    const itemData = Items[item.name];

    if (!itemData) {
      return null;
    }

    const playerInventoryId = playerInventory.id || 'player';

    let targetSlot: Slot | undefined = findAvailableSlot(item, itemData, playerInventory.items);
    let fallbackSlot: SlotWithItem | undefined;

    if (!targetSlot) {
      fallbackSlot = playerInventory.items.find((slot): slot is SlotWithItem => isSlotWithItem(slot, true));

      if (!fallbackSlot) {
        return null;
      }

      targetSlot = { slot: fallbackSlot.slot };
    }

    const response = await fetchNui<MoveResponse>('contextMoveToPlayer', {
      fromSlot: item.slot,
      fromType: inventoryType,
      toSlot: targetSlot.slot,
      toType: InventoryType.PLAYER,
      count: item.count ?? 1,
      fromInventory: inventoryId,
      toInventory: playerInventoryId,
    });

    if (!response?.success) {
      return null;
    }

    return response.slot ?? targetSlot.slot;
  };

  const handleClick = async (data: DataProps) => {
    if (!item) return;
    let shouldClose = false;

    switch (data && data.action) {
      case 'use':
        await fetchNui('contextUseItem', {
          slot: item.slot,
          inventory: inventoryId ?? null,
          inventoryType,
          item,
        });
        shouldClose = true;
        break;
      case 'give':
        {
          const slot = await ensureItemInPockets();
          if (!slot) return;
          onGive({ name: item.name, slot });
          shouldClose = true;
        }
        break;
      case 'give_nearby':
        {
          const slot = await ensureItemInPockets();
          if (!slot) return;
          fetchNui('giveItemNearby', { slot, count: item.count });
          shouldClose = true;
        }
        break;
      case 'drop':
        if (isSlotWithItem(item)) {
          // If dropping from a backpack (non-player inventory) we want to drop into the world
          // instead of moving the item into the player's inventory. Call the swap/drop flow
          // directly with toType = 'newdrop'. For player inventory, keep the normal onDrop flow.
          if (inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK) {
            const count = item.count ?? 1;
            await fetchNui('swapItems', {
              fromSlot: item.slot,
              fromType: inventoryType,
              toSlot: 1,
              toType: 'newdrop',
              count,
              fromInventory: inventoryId,
            });
          } else {
            onDrop({
              item: { name: item.name, slot: item.slot },
              inventory: inventoryType,
              inventoryId,
              metadata: item.metadata,
            });
          }
        }
        shouldClose = true;
        break;
      case 'remove':
        {
          const slot = await ensureItemInPockets();
          if (!slot) return;
          fetchNui('removeComponent', { component: data?.component, slot });
          shouldClose = true;
        }
        break;
      case 'removeAmmo':
        {
          const slot = await ensureItemInPockets();
          if (!slot) return;
          fetchNui('removeAmmo', slot);
          shouldClose = true;
        }
        break;
      case 'copy':
        setClipboard(data.serial || '');
        shouldClose = true;
        break;
      case 'custom':
        {
          const slot = await ensureItemInPockets();
          if (!slot) return;
          fetchNui('useButton', { id: (data?.id || 0) + 1, slot });
          shouldClose = true;
        }
        break;
      case 'split':
        if (item.count && item.count > 1) {
          dispatch(openSplitDialog({ item, inventoryType }));
          shouldClose = true;
        }
        break;
    }

    if (shouldClose) {
      dispatch(closeContextMenu());
    }
  };

  const groupButtons = (buttons: any): GroupedButtons => {
    return buttons.reduce((groups: Group[], button: Button, index: number) => {
      if (button.group) {
        const groupIndex = groups.findIndex((group) => group.groupName === button.group);
        if (groupIndex !== -1) {
          groups[groupIndex].buttons.push({ ...button, index });
        } else {
          groups.push({
            groupName: button.group,
            buttons: [{ ...button, index }],
          });
        }
      } else {
        groups.push({
          groupName: null,
          buttons: [{ ...button, index }],
        });
      }
      return groups;
    }, []);
  };

  return (
    <>
      <Menu>
        <MenuItem onClick={() => void handleClick({ action: 'use' })} label={Locale.ui_use || 'Use'} />
        <MenuItem onClick={() => void handleClick({ action: 'give' })} label={Locale.ui_give || 'Give'} />
        <MenuItem onClick={() => void handleClick({ action: 'give_nearby' })} label={Locale.ui_give_nearby || 'Give Nearby'} />
        <MenuItem onClick={() => void handleClick({ action: 'drop' })} label={Locale.ui_drop || 'Drop'} />
        {item && item.count && item.count > 1 && (
          <MenuItem onClick={() => void handleClick({ action: 'split' })} label={Locale.ui_split || 'Split'} />
        )}
        {item && item.metadata?.ammo > 0 && (
          <MenuItem onClick={() => void handleClick({ action: 'removeAmmo' })} label={Locale.ui_remove_ammo} />
        )}
        {item && item.metadata?.serial && (
          <MenuItem onClick={() => void handleClick({ action: 'copy', serial: item.metadata?.serial })} label={Locale.ui_copy} />
        )}
        {item && item.metadata?.components && item.metadata?.components.length > 0 && (
          <Menu label={Locale.ui_removeattachments}>
            {item &&
              item.metadata?.components.map((component: string, index: number) => (
                <MenuItem
                  key={index}
                  onClick={() => void handleClick({ action: 'remove', component })}
                  label={Items[component]?.label || ''}
                />
              ))}
          </Menu>
        )}
        {((item && item.name && Items[item.name]?.buttons?.length) || 0) > 0 && (
          <>
            {item &&
              item.name &&
              groupButtons(Items[item.name]?.buttons).map((group: Group, index: number) => (
                <React.Fragment key={index}>
                  {group.groupName ? (
                    <Menu label={group.groupName}>
                      {group.buttons.map((button: Button) => (
                        <MenuItem
                          key={button.index}
                          onClick={() => void handleClick({ action: 'custom', id: button.index })}
                          label={button.label}
                        />
                      ))}
                    </Menu>
                  ) : (
                    group.buttons.map((button: Button) => (
                      <MenuItem
                        key={button.index}
                        onClick={() => void handleClick({ action: 'custom', id: button.index })}
                        label={button.label}
                      />
                    ))
                  )}
                </React.Fragment>
              ))}
          </>
        )}
      </Menu>
    </>
  );
};

export default InventoryContext;
