import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory, InventoryType } from '../../typings';
import InventorySlot from './InventorySlot';
import { getTotalWeight } from '../../helpers';
import { useAppSelector } from '../../store';
import { Locale } from '../../store/locale';
import { useIntersection } from '../../hooks/useIntersection';
import { fetchNui } from '../../utils/fetchNui';
import pocketIcon from '../../assets/svg/pocket.svg';
import othersIcon from '../../assets/svg/others.svg';
import backpackIcon from '../../assets/svg/backpack1.svg';
import vestIcon from '../../assets/svg/vest.svg';

const PAGE_SIZE = 30;

type InventoryGridProps = React.PropsWithChildren<{
  inventory: Inventory;
  uiTypeOverride?: InventoryType;
  style?: React.CSSProperties;
}>;

const InventoryGrid: React.FC<InventoryGridProps> = ({ inventory, uiTypeOverride, style, children }) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? getTotalWeight(inventory.items) : 0),
    [inventory.maxWeight, inventory.items]
  );
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };
  const [page, setPage] = useState(0);
  const containerRef = useRef(null);
  const { ref, entry } = useIntersection({ threshold: 0.5 });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const weightPercent = inventory.maxWeight ? Math.min((weight / inventory.maxWeight) * 100, 100) : 0;

  const uiType = (uiTypeOverride || inventory.type || InventoryType.PLAYER) as InventoryType | string;

  const iconMap: Record<string, string> = {
    [InventoryType.PLAYER]: pocketIcon,
    [InventoryType.CONTAINER]: backpackIcon,
    [InventoryType.BACKPACK]: backpackIcon,
    [InventoryType.OTHER_BACKPACK]: backpackIcon,
    [InventoryType.SHOP]: othersIcon,
    [InventoryType.CRAFTING]: othersIcon,
  };

  const resolveIcon = () => {
    const metadata = (inventory as { metadata?: { icon?: string } }).metadata;
    if (metadata?.icon && typeof metadata.icon === 'string') {
      return metadata.icon;
    }

    if (typeof uiType === 'string' && iconMap[uiType]) return iconMap[uiType];

    const label = inventory.label?.toLowerCase();
    if (label) {
      if (label.includes('trunk') || label.includes('glovebox') || label.includes('bag')) return backpackIcon;
      if (label.includes('armor') || label.includes('vest')) return vestIcon;
    }

    return othersIcon;
  };

  const weightClass =
    weightPercent >= 90 ? 'danger' : weightPercent >= 60 ? 'warning' : weightPercent > 0 ? 'safe' : undefined;

  const isPlayerInventory = uiType === InventoryType.PLAYER;
  const isPlayerBackpack = uiType === InventoryType.BACKPACK;
  const isOtherBackpack = uiType === InventoryType.OTHER_BACKPACK;
  const hasChildren = React.Children.count(children) > 0;
  const sectionClasses: string[] = [];

  if (isPlayerBackpack) {
    sectionClasses.push('backpack-section');
  } else {
    sectionClasses.push('inventory-section');

    if (isPlayerInventory) {
      sectionClasses.push('player-inventory-section', 'lean-left');

      if (hasChildren) {
        sectionClasses.push('with-backpack');
      }
    } else if (isOtherBackpack) {
      sectionClasses.push('other-backpack-section', 'lean-right');
    } else {
      sectionClasses.push('other-inventory-section', 'lean-right');
    }
  }

  const sectionClassName = sectionClasses.filter(Boolean).join(' ');

  const ContainerTag = (isPlayerBackpack ? 'div' : 'section') as keyof JSX.IntrinsicElements;
  const headerClassName = isPlayerBackpack ? 'backpack-header' : 'inventory-header';
  const gridWrapperClassName = isPlayerBackpack ? 'backpack-grid' : 'inventory-grid';

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => ++prev);
    }
  }, [entry]);

  return (
    <ContainerTag className={sectionClassName} style={{ pointerEvents: isBusy ? 'none' : 'auto', ...style }}>
      <div className={headerClassName}>
        <div className="header-content">
          <div className="inventory-title">
            <i className="inventory-badge">
              <img src={resolveIcon()} alt="inventory badge" />
            </i>
            <span>
              {inventory.label ||
                (inventory.type === InventoryType.PLAYER
                  ? t('pockets', 'Pockets')
                  : t('inventory', 'Inventory'))}
            </span>
          </div>
          {uiType === InventoryType.PLAYER && (
            <button className="close-button" onClick={() => fetchNui('exit')}>
              <span className="material-symbols-rounded">expand_more</span>
            </button>
          )}
        </div>
        {inventory.maxWeight && (
          <div className="weight-bar-wrapper">
            <i className="fas fa-weight-hanging" />
            <div className="weight-info">
              <span className="weight-text">
                {(weight / 1000).toFixed(2)}/{(inventory.maxWeight / 1000).toFixed(0)}kg
              </span>
              <div className="weight-bar">
                <div className={`weight-bar-fill ${weightClass || ''}`} style={{ width: `${weightPercent}%` }} />
              </div>
            </div>
          </div>
        )}
      </div>
      <div className={gridWrapperClassName}>
        <div className="item-grid" ref={containerRef}>
          {inventory.items.slice(0, (page + 1) * PAGE_SIZE).map((item, index) => (
            <InventorySlot
              key={`${uiType}-${inventory.id}-${item.slot}`}
              item={item}
              ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
              inventoryType={uiType as Inventory['type']}
              inventoryGroups={inventory.groups}
              inventoryId={inventory.id}
            />
          ))}
        </div>
      </div>
      {children}
    </ContainerTag>
  );
};

export default InventoryGrid;
