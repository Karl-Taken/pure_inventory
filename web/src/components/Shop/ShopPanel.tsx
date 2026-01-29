import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory, selectRightInventory, setItemAmount } from '../../store/inventory';
import { buyItem } from '../../thunks/buyItem';
import { Locale } from '../../store/locale';
import { InventoryType, SlotWithItem } from '../../typings';
import { getItemUrl, getTotalWeight, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import { isEqual } from 'lodash';
import { useDrag, useDrop } from 'react-dnd';
import type { DragSource } from '../../typings';
import shopBadgeIcon from '../../assets/svg/others.svg';

type PaymentMethod = 'cash' | 'bank';

type ShopEntry = {
  slot: number;
  item: SlotWithItem;
  label: string;
  description?: string;
  category: string;
  count?: number;
  price: number;
  currency?: string;
  weight: number;
  image: string;
};

type BasketLine = {
  slot: number;
  name: string;
  label: string;
  price: number;
  currency?: string;
  weight: number;
  qty: number;
  max: number;
  image: string;
  metadata?: SlotWithItem['metadata'];
};

const ALL_CATEGORY = 'All';

const clampQty = (value: number, max: number) => {
  if (!Number.isFinite(value)) return 1;
  const next = Math.max(1, Math.floor(value));
  if (max > 0) return Math.min(next, max);
  return next;
};

const formatPrice = (price: number, currency?: string) => {
  const localeKey = Locale.localeString;
  const localeString =
    localeKey && localeKey !== 'localeString' && localeKey !== ''
      ? localeKey
      : (typeof navigator !== 'undefined' ? navigator.language : 'en-US') || 'en-US';
  // Force Latin digits to avoid locale-specific numerals (e.g., Arabic-Indic) when using EN UI.
  const localeWithLatinDigits = `${localeString}-u-nu-latn`;

  if (currency && currency !== 'money' && currency !== 'black_money') {
    return price.toLocaleString(localeWithLatinDigits as string);
  }

  const symbol = Locale.$ || '$';
  return `${symbol}${price.toLocaleString(localeWithLatinDigits as string)}`;
};

const resolveCategory = (slot: SlotWithItem) => {
  const metadata = slot.metadata;

  if (metadata?.category && typeof metadata.category === 'string') return metadata.category;
  if (metadata?.type && typeof metadata.type === 'string') return metadata.type;
  if (metadata?.class && typeof metadata.class === 'string') return metadata.class;

  return 'General';
};

const notify = async (type: 'success' | 'error', message: string) => {
  await fetch('https://ox_inventory/notify', {
    method: 'POST',
    body: JSON.stringify({ type, message }),
  });
};

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
        const img = new Image();
        img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
        return img;
      })()
    : undefined;

type ShopItemCardProps = {
  entry: ShopEntry;
  inventoryId: string | number;
  isSelected: boolean;
  disabled: boolean;
  onSelect: () => void;
  onDoubleClick: () => void;
  onDragStart: (entry: ShopEntry) => void;
  onDragEnd: () => void;
};

const ShopItemCard: React.FC<ShopItemCardProps> = ({
  entry,
  inventoryId,
  isSelected,
  disabled,
  onSelect,
  onDoubleClick,
  onDragStart,
  onDragEnd,
}) => {
  const outOfStock = entry.count !== undefined && entry.count <= 0;

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      item: () => {
        onDragStart(entry);
        return {
          inventory: InventoryType.SHOP,
          inventoryId,
          item: { slot: entry.slot, name: entry.item.name },
          metadata: entry.item.metadata,
        };
      },
      canDrag: !disabled && !outOfStock,
      collect: (monitor) => ({
        isDragging: monitor.isDragging(),
      }),
      end: () => {
        onDragEnd();
      },
    }),
    [disabled, entry, inventoryId, onDragEnd, onDragStart, outOfStock]
  );

  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  const setRefs = useCallback(
    (node: HTMLButtonElement | null) => {
      if (node) drag(node);
    },
    [drag]
  );

  return (
    <button
      ref={setRefs}
      key={`shop-${entry.slot}`}
      className={`shop-slot item-slot has-item ${isSelected ? 'selected' : ''} ${
        outOfStock ? 'slot-restricted' : ''
      } ${isDragging ? 'dragging' : ''}`}
      onClick={onSelect}
      onDoubleClick={onDoubleClick}
      disabled={disabled || outOfStock}
      data-slot={entry.slot}
      data-slot-index={entry.slot}
      data-inventory-type={InventoryType.SHOP}
      data-inventory-id={inventoryId !== undefined && inventoryId !== null ? String(inventoryId) : ''}
      style={{ opacity: isDragging ? 0.5 : 1 }}
    >
      <div className="item-price">
        <i className="fas fa-dollar-sign" />
        <span>{formatPrice(entry.price, entry.currency)}</span>
      </div>

      <div className="item-slot-amount">
        <span>{entry.count !== undefined ? `${entry.count}x` : '-'}</span>
      </div>

      <div className="item-slot-content">
        <div className="item-slot-img">
          {entry.image ? <img src={entry.image} alt={entry.label} /> : null}
        </div>
        <div className="item-slot-footer">
          <div className="item-name">{entry.label}</div>
          <div className="item-weight">{(entry.weight / 1000).toFixed(2)}kg</div>
        </div>
      </div>
    </button>
  );
};

const ShopPanel: React.FC = () => {
  const dispatch = useAppDispatch();
  const left = useAppSelector(selectLeftInventory);
  const right = useAppSelector(selectRightInventory);
  const dragQuantityRef = useRef<number>(1);
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [selectedSlot, setSelectedSlot] = useState<number | null>(null);
  const [shopQty, setShopQty] = useState<number>(1);
  const [shopSearch, setShopSearch] = useState<string>('');
  const [shopCategory, setShopCategory] = useState<string>(ALL_CATEGORY);
  const [basket, setBasket] = useState<BasketLine[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const outOfStockText = t('shop_nostock', 'Item is out of stock');
  const noSpaceText = t('shop_no_space', 'No inventory space available');

  const shopEntries = useMemo<ShopEntry[]>(() => {
    return right.items
      .filter((slot): slot is SlotWithItem => isSlotWithItem(slot as any))
      .map((slot) => {
        const itemData = Items[slot.name];
        const label = slot.metadata?.label || itemData?.label || slot.name;
        const description = slot.metadata?.description || itemData?.description;

        return {
          slot: slot.slot,
          item: slot,
          label,
          description,
          category: resolveCategory(slot),
          count: slot.count,
          price: slot.price ?? 0,
          currency: slot.currency,
          weight: slot.weight ?? 0,
          image: getItemUrl(slot) || '',
        };
      });
  }, [right.items]);

  useEffect(() => {
    setSelectedSlot(null);
    setShopQty(1);
    setShopSearch('');
    setShopCategory(ALL_CATEGORY);
    setBasket([]);
    dragQuantityRef.current = 1;
    dispatch(setItemAmount(0));
    return () => {
      dispatch(setItemAmount(0));
    };
  }, [dispatch, right.id]);

  useEffect(() => {
    setBasket((prev) => {
      const mapped = prev
        .map((line) => {
          const entry = shopEntries.find((item) => item.slot === line.slot);
          if (!entry) return null;
          const max = entry.count ?? 999;
          const qty = Math.min(line.qty, max > 0 ? max : line.qty);
          if (max === 0 || qty <= 0) return null;

          const updated: BasketLine = {
            ...line,
            max,
            qty,
            price: entry.price,
            currency: entry.currency,
            weight: entry.weight,
            label: entry.label,
            image: entry.image,
            metadata: entry.item.metadata,
          };

          return updated;
        })
        .filter((line): line is BasketLine => line !== null);

      return mapped;
    });
  }, [shopEntries]);

  const categories = useMemo(() => {
    const set = new Set<string>([ALL_CATEGORY]);
    shopEntries.forEach((entry) => set.add(entry.category));
    return Array.from(set);
  }, [shopEntries]);

  const filteredShopItems = useMemo(() => {
    const query = shopSearch.trim().toLowerCase();
    return shopEntries.filter((entry) => {
      if (shopCategory !== ALL_CATEGORY && entry.category !== shopCategory) return false;
      if (!query) return true;

      const haystack = [
        entry.label,
        entry.item.name,
        entry.description,
        entry.item.metadata?.description,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return haystack.includes(query);
    });
  }, [shopEntries, shopCategory, shopSearch]);

  const selectedEntry = useMemo(
    () => shopEntries.find((entry) => entry.slot === selectedSlot) ?? null,
    [shopEntries, selectedSlot]
  );

  const rightWeight = useMemo(() => getTotalWeight(right.items), [right.items]);
  const rightWeightPercent = right.maxWeight ? Math.min((rightWeight / right.maxWeight) * 100, 100) : 0;
  const rightWeightClass =
    rightWeightPercent < 50 ? 'low' : rightWeightPercent < 75 ? 'medium' : 'high';

  const basketSubtotal = useMemo(
    () => basket.reduce((sum, line) => sum + line.price * line.qty, 0),
    [basket]
  );
  const basketTotalWeight = useMemo(
    () => basket.reduce((sum, line) => sum + line.weight * line.qty, 0),
    [basket]
  );
  const basketCount = useMemo(
    () => basket.reduce((sum, line) => sum + line.qty, 0),
    [basket]
  );


  const upsertBasketLine = useCallback(
    (entry: ShopEntry, qty: number) => {
      if (!entry || qty <= 0) return;
      if (entry.count !== undefined && entry.count <= 0) {
        notify('error', outOfStockText);
        return;
      }

      const hardMax = entry.count ?? 999;
      const safeQty = clampQty(qty, hardMax || qty);
      if (safeQty <= 0) return;

      setBasket((prev) => {
        const idx = prev.findIndex((line) => line.slot === entry.slot);
        if (idx > -1) {
          const next = [...prev];
          const combined = clampQty(next[idx].qty + safeQty, hardMax || 999);
          next[idx] = {
            ...next[idx],
            qty: combined,
            max: hardMax || 999,
            price: entry.price,
            currency: entry.currency,
            weight: entry.weight,
            label: entry.label,
            image: entry.image,
            metadata: entry.item.metadata,
          };
          return next;
        }

        const line: BasketLine = {
          slot: entry.slot,
          name: entry.item.name,
          label: entry.label,
          price: entry.price,
          currency: entry.currency,
          weight: entry.weight,
          qty: safeQty,
          max: hardMax || 999,
          image: entry.image,
          metadata: entry.item.metadata,
        };

        return [...prev, line];
      });
    },
    [outOfStockText]
  );

  const handleDragStart = useCallback(
    (entry: ShopEntry) => {
      const max = entry.count ?? 999;
      const qty = clampQty(shopQty, max || shopQty);
      dragQuantityRef.current = qty;
      dispatch(setItemAmount(qty));
    },
    [dispatch, shopQty]
  );

  const handleDragEnd = useCallback(() => {
    dragQuantityRef.current = 1;
    dispatch(setItemAmount(0));
  }, [dispatch]);

  const [{ isOver: isBasketOver }, basketDropRef] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => source.inventory === InventoryType.SHOP,
      drop: (source) => {
        const entry = shopEntries.find((item) => item.slot === source.item.slot);
        if (!entry) return;

        const max = entry.count ?? dragQuantityRef.current;
        if (max <= 0) {
          notify('error', outOfStockText);
          return;
        }

        const qty = clampQty(dragQuantityRef.current, max || dragQuantityRef.current);
        upsertBasketLine(entry, qty);
      },
      collect: (monitor) => ({
        isOver: monitor.isOver({ shallow: true }),
      }),
    }),
    [outOfStockText, shopEntries, upsertBasketLine]
  );

  const pickTargetSlot = useCallback(
    (entry: ShopEntry, preferEmpty: boolean) => {
      const items = left.items;
      const metadata = entry.item.metadata;
      const itemData = Items[entry.item.name];

      if (!preferEmpty && itemData?.stack) {
        const stackTarget = items.find(
          (slot) =>
            isSlotWithItem(slot) &&
            slot.name === entry.item.name &&
            isEqual(slot.metadata, metadata)
        );

        if (stackTarget) return stackTarget.slot;
      }

      const emptySlot = items.find((slot) => !slot?.name);
      return emptySlot ? emptySlot.slot : null;
    },
    [left.items]
  );

  const attemptPurchase = useCallback(
    async (entry: ShopEntry, quantity: number, payment: PaymentMethod = 'cash') => {
      const tryPurchase = async (preferEmpty: boolean) => {
        const targetSlot = pickTargetSlot(entry, preferEmpty);

        if (!targetSlot) {
          await notify('error', noSpaceText);
          return false;
        }

        try {
          await dispatch(
            buyItem({
              fromSlot: entry.slot,
              fromType: right.type,
              toSlot: targetSlot,
              toType: left.type || InventoryType.PLAYER,
              count: quantity,
              payment,
            })
          ).unwrap();

          return true;
        } catch {
          return false;
        }
      };

      if (await tryPurchase(false)) return true;
      return await tryPurchase(true);
    },
    [dispatch, left.type, noSpaceText, pickTargetSlot, right.type]
  );

  const handleSelect = (slot: number) => {
    setSelectedSlot((prev) => (prev === slot ? null : slot));
    setShopQty(1);
  };

  const handleAddSelectedToBasket = () => {
    if (!selectedEntry) return;
    upsertBasketLine(selectedEntry, shopQty);
  };

  const handleUpdateBasketQty = (index: number, value: number) => {
    setBasket((prev) => {
      const next = [...prev];
      const line = next[index];
      if (!line) return prev;
      const max = line.max || 999;
      next[index] = { ...line, qty: clampQty(value, max) };
      return next;
    });
  };

  const handleRemoveFromBasket = (index: number) => {
    setBasket((prev) => prev.filter((_, idx) => idx !== index));
  };

  const handleBuySelected = async () => {
    if (!selectedEntry || isProcessing) return;

    const max = selectedEntry.count ?? shopQty;
    if (max === 0) {
      notify('error', outOfStockText);
      return;
    }

    const qty = clampQty(shopQty, max || shopQty);

    setIsProcessing(true);
    const success = await attemptPurchase(selectedEntry, qty, 'cash');
    setIsProcessing(false);

    if (success) {
      setSelectedSlot(null);
      setShopQty(1);
    }
  };

  const handleCheckout = async (method: PaymentMethod) => {
    if (!basket.length || isProcessing) return;
    setIsProcessing(true);

    const snapshot = [...basket];
    let halted = false;

    for (const line of snapshot) {
      let remaining = line.qty;

      while (remaining > 0) {
        const entry = shopEntries.find((item) => item.slot === line.slot);
        if (!entry) {
          setBasket((prev) => prev.filter((b) => b.slot !== line.slot));
          break;
        }

        const available = entry.count ?? remaining;
        if (available <= 0) {
          setBasket((prev) => prev.filter((b) => b.slot !== line.slot));
          break;
        }

        const qty = clampQty(remaining, available);
        const success = await attemptPurchase(entry, qty, method);

        if (!success) {
          halted = true;
          remaining = 0;
          break;
        }

        remaining -= qty;
        setBasket((prev) => {
          const next = [...prev];
          const idx = next.findIndex((b) => b.slot === line.slot);
          if (idx === -1) return prev;

          if (remaining <= 0) {
            next.splice(idx, 1);
          } else {
            next[idx] = { ...next[idx], qty: remaining };
          }

          return next;
        });
      }

      if (halted) break;
    }

    setIsProcessing(false);
  };

  const renderCategoryLabel = (category: string) => {
    if (category === ALL_CATEGORY) return t('all', 'All');
    if (category === 'General') return t('general', 'General');
    return category;
  };

  if (!right || right.type !== 'shop') return null;

  return (
    <aside className="shop-panel">
      <div className="inventory-header shop-inventory-header">
        <div className="header-content">
          <div className="inventory-title">
            <i className="inventory-badge">
              <img src={shopBadgeIcon} alt="Shop badge" />
            </i>
            <span>{right.label || t('shop', 'Shop')}</span>
          </div>
        </div>
        {right.maxWeight ? (
          <div className="weight-bar-wrapper">
            <i className="fas fa-weight-hanging" />
            <div className="weight-info">
              <span className="weight-text">
                {(rightWeight / 1000).toFixed(2)}/{(right.maxWeight / 1000).toFixed(0)}kg
              </span>
              <div className="weight-bar">
                <div
                  className={`weight-bar-fill ${rightWeightClass}`}
                  style={{ width: `${rightWeightPercent}%` }}
                />
              </div>
            </div>
          </div>
        ) : null}
      </div>

      <div className="shop-controls">
        <div className="shop-search">
          <span className="material-symbols-rounded">search</span>
          <input
            type="text"
            placeholder={t('shop_search_placeholder', 'Search shop...')}
            value={shopSearch}
            onChange={(event) => setShopSearch(event.target.value)}
            disabled={isProcessing}
          />
        </div>

        <div className="shop-qty-global" title={t('shop_qty_help', 'Quantity used for quick purchases')}>
          <label>{t('quantity_short', t('quantity', 'Qty'))}</label>
          <div className="qty-box">
            <button
              onClick={() => setShopQty((prev) => clampQty(prev - 1, selectedEntry?.count ?? 999))}
              disabled={isProcessing}
            >
              <span className="material-symbols-rounded">remove</span>
            </button>
            <input
              type="number"
              min={1}
              max={selectedEntry?.count ?? 999}
              value={shopQty}
              onChange={(event) =>
                setShopQty(clampQty(Number(event.target.value), selectedEntry?.count ?? 999))
              }
              disabled={isProcessing}
            />
            <button
              onClick={() => setShopQty((prev) => clampQty(prev + 1, selectedEntry?.count ?? 999))}
              disabled={isProcessing}
            >
              <span className="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>
      </div>

      <div className="shop-cats">
        {categories.map((category) => (
          <button
            key={category}
            className={`cat-pill ${shopCategory === category ? 'active' : ''}`}
            onClick={() => setShopCategory(category)}
            disabled={isProcessing}
          >
            {renderCategoryLabel(category)}
          </button>
        ))}
      </div>

      <div className="shop-grid">
        {filteredShopItems.map((entry) => {
          const isSelected = selectedSlot === entry.slot;
          return (
            <ShopItemCard
              key={`shop-${entry.slot}`}
              entry={entry}
              inventoryId={right.id}
              isSelected={isSelected}
              disabled={isProcessing}
              onSelect={() => handleSelect(entry.slot)}
              onDoubleClick={() => handleBuySelected()}
              onDragStart={handleDragStart}
              onDragEnd={handleDragEnd}
            />
          );
        })}
      </div>



      <div
        ref={basketDropRef}
        className={`cart-section basket-dock${isBasketOver ? ' highlight-drop' : ''}`}
      >
        <div className="cart-header">
          {t('shop_cart', 'Shopping Cart')}
          {basketCount > 0 ? <span className="cart-count">{basketCount}</span> : null}
        </div>
        <div className="cart-divider" />

        {basket.length === 0 ? (
          <div className="basket-empty">
            <i className="fas fa-hand-pointer" />
            <p>{t('shop_cart_help', 'Select items and use Add to Cart to build your order.')}</p>
          </div>
        ) : (
          <div className="cart-list basket-list">
            {basket.map((line, index) => (
              <div key={`basket-${line.slot}`} className="cart-item basket-item">
                <div className="cart-left">
                  <div className="cart-thumb">
                    {line.image ? <img src={line.image} alt={line.label} /> : null}
                  </div>
                  <div className="cart-meta">
                    <div className="cart-name">{line.label}</div>
                    <div className="cart-weight">
                      {(line.weight / 1000).toFixed(2)} {t('shop_weight_each', 'kg each')}
                    </div>
                  </div>
                </div>
                <div className="cart-right">
                  <div className="qty-box qty-inline">
                    <button
                      onClick={() => handleUpdateBasketQty(index, line.qty - 1)}
                      disabled={line.qty <= 1 || isProcessing}
                    >
                      <span className="material-symbols-rounded">remove</span>
                    </button>
                    <input
                      type="number"
                      min={1}
                      max={line.max}
                      value={line.qty}
                      onChange={(event) =>
                        handleUpdateBasketQty(index, Number(event.target.value))
                      }
                      disabled={isProcessing}
                    />
                    <button
                      onClick={() => handleUpdateBasketQty(index, line.qty + 1)}
                      disabled={line.qty >= line.max || isProcessing}
                    >
                      <span className="material-symbols-rounded">add</span>
                    </button>
                  </div>

                  <div className="price-chip">
                    {formatPrice(line.price * line.qty, line.currency)}
                  </div>

                  <button
                    className="icon-btn danger btn-x"
                    title={t('remove', 'Remove')}
                    onClick={() => handleRemoveFromBasket(index)}
                    disabled={isProcessing}
                  >
                    <span className="material-symbols-rounded">close</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="total-line">
          <span>{t('total_cost', 'Total cost')}</span>
          <strong>{formatPrice(basketSubtotal)}</strong>
        </div>

        <div className="total-line">
          <span>{t('total_weight', 'Total weight')}</span>
          <strong>{(basketTotalWeight / 1000).toFixed(2)}kg</strong>
        </div>

        <div className="pay-actions">
          <button
            className="btn-pay bank btn-outline"
            onClick={() => handleCheckout('bank')}
            disabled={basket.length === 0 || isProcessing}
          >
            <i className="fas fa-wallet" /> {t('pay_bank', 'Pay Bank')}
          </button>
          <button
            className="btn-pay cash btn-primary"
            onClick={() => handleCheckout('cash')}
            disabled={basket.length === 0 || isProcessing}
          >
            <i className="fas fa-money-bill-wave" /> {t('pay_cash', 'Pay Cash')}
          </button>
        </div>
      </div>
    </aside>
  );
};

export default ShopPanel;


