import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Inventory, SlotWithItem, CraftSlot } from '../../typings';
import { Locale } from '../../store/locale';
import { Items } from '../../store/items';
import {
  canCraftItem,
  getCraftItemCount,
  getItemCount,
  getItemUrl,
  isSlotWithItem,
  useCurrentTime,
} from '../../helpers';
import { useAppDispatch, useAppSelector } from '../../store';
import { craftItem } from '../../thunks/craftItem';
import { cancelCraft } from '../../thunks/cancelCraft';
import useNuiEvent from '../../hooks/useNuiEvent';

type CraftingRecipe = SlotWithItem & {
  xp?: {
    required?: number;
    reward?: number;
  };
  blueprint?: string;
};

type CraftingInventory = Inventory & {
  index?: number;
  crafting?: {
    xp?: {
      enabled: boolean;
      current: number;
      hideLocked?: boolean;
    };
    blueprints?: Record<string, boolean>;
    blueprintLabels?: Record<string, string>;
  };
};

type CraftingPanelProps = {
  inventory: CraftingInventory;
};

const CraftingPanel: React.FC<CraftingPanelProps> = ({ inventory }) => {
  const dispatch = useAppDispatch();
  const storageFromStore = useAppSelector((state) => state.inventory.leftInventory.backpack);
  const storageInventory = storageFromStore ?? inventory.storage;

  const recipes = useMemo(
    () => inventory.items.filter((slot): slot is CraftingRecipe => isSlotWithItem(slot)),
    [inventory.items]
  );

  const craftingInfo = inventory.crafting;
  const xpInfo = craftingInfo?.xp;
  const xpEnabled = xpInfo?.enabled ?? false;
  const playerXp = xpInfo?.current ?? 0;
  const hideLocked = xpInfo?.hideLocked ?? false;

  const formattedPlayerXp = useMemo(() => {
    if (typeof playerXp !== 'number' || !Number.isFinite(playerXp)) {
      return '0';
    }
    return Math.max(0, Math.floor(playerXp)).toLocaleString();
  }, [playerXp]);

  const [blueprintMap, setBlueprintMap] = useState<Record<string, boolean>>(craftingInfo?.blueprints ?? {});
  const blueprintLabels = craftingInfo?.blueprintLabels ?? {};

  const [search, setSearch] = useState('');
  const [selectedRecipe, setSelectedRecipe] = useState<CraftingRecipe | null>(null);
  const [countToCraft, setCountToCraft] = useState(1);
  const [craftQueue, setCraftQueue] = useState<CraftSlot[]>([]);
  const now = useCurrentTime(250);
  const queueScrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const container = queueScrollRef.current;
    if (!container) return;

    const onWheel = (event: WheelEvent) => {
      const absDeltaY = Math.abs(event.deltaY);
      const absDeltaX = Math.abs(event.deltaX);

      if (absDeltaY <= absDeltaX) return;

      event.preventDefault();
      container.scrollBy({
        left: event.deltaY,
        behavior: 'auto',
      });
    };

    container.addEventListener('wheel', onWheel, { passive: false });

    return () => {
      container.removeEventListener('wheel', onWheel);
    };
  }, []);

  useEffect(() => {
    if (craftingInfo?.blueprints) {
      setBlueprintMap(craftingInfo.blueprints);
    }
  }, [craftingInfo?.blueprints]);

  useEffect(() => {
    const serverQueue = craftingInfo?.queue;
    if (!serverQueue || !serverQueue.length) {
      setCraftQueue([]);
      return;
    }

    const mapped: CraftSlot[] = serverQueue.map((entry) => {
      const recipeSlot = entry.recipeSlot;
      const recipe = inventory.items && inventory.items[recipeSlot - 1];

      const base = (recipe && isSlotWithItem(recipe)) ? recipe : ({} as SlotWithItem);

      const baseCraftCount =
        typeof base.count === 'number'
          ? base.count
          : Array.isArray(base.count)
            ? base.count[0]
            : 1;

      return {
        slot: base.slot ?? recipeSlot,
        name: base.name ?? (entry.recipe as any) ?? '',
        count: base.count ?? 1,
        weight: base.weight ?? 0,
        durability: base.durability,
        price: base.price,
        currency: base.currency,
        ingredients: base.ingredients,
        duration: (entry.duration ? entry.duration * 1000 : base.duration) as any,
        metadata: base.metadata,
        craftCount: Math.max(1, entry.craftCount ?? baseCraftCount),
        startedAt: entry.startedAt ? entry.startedAt * 1000 : undefined,
      } as CraftSlot;
    });

    setCraftQueue(mapped);
  }, [craftingInfo?.queue, inventory.items]);

  useNuiEvent<any>('updateCraftQueue', (serverQueue) => {
    if (!serverQueue || !Array.isArray(serverQueue)) {
      setCraftQueue([]);
      return;
    }

    const mapped: CraftSlot[] = serverQueue.map((entry) => {
      const recipeSlot = entry.recipeSlot;
      const recipe = inventory.items && inventory.items[recipeSlot - 1];
      const base = (recipe && isSlotWithItem(recipe)) ? recipe : ({} as SlotWithItem);

      const baseCraftCount =
        typeof base.count === 'number'
          ? base.count
          : Array.isArray(base.count)
            ? base.count[0]
            : 1;

      return {
        slot: base.slot ?? recipeSlot,
        name: base.name ?? (entry.recipe as any) ?? '',
        count: base.count ?? 1,
        weight: base.weight ?? 0,
        durability: base.durability,
        price: base.price,
        currency: base.currency,
        ingredients: base.ingredients,
        duration: (entry.duration ? entry.duration * 1000 : base.duration) as any,
        metadata: base.metadata,
        craftCount: Math.max(1, entry.craftCount ?? baseCraftCount),
        startedAt: entry.startedAt ? entry.startedAt * 1000 : undefined,
      } as CraftSlot;
    });

    setCraftQueue(mapped);
  });

  // Listen for blueprint updates from server
  useNuiEvent<Record<string, boolean>>('updateBlueprints', (newBlueprints) => {
    setBlueprintMap(newBlueprints);
  });

  const getLockInfo = useCallback(
    (recipe: CraftingRecipe) => {
      const requiredXp = recipe.xp?.required ?? 0;
      const meetsXp = !xpEnabled || playerXp >= requiredXp;
      const blueprintKey = recipe.blueprint;
      const hasBlueprint = !blueprintKey || !!blueprintMap[blueprintKey];
      return {
        requiredXp,
        meetsXp,
        blueprintKey,
        hasBlueprint,
        locked: !(meetsXp && hasBlueprint),
      };
    },
    [xpEnabled, playerXp, blueprintMap]
  );

  const filteredRecipes = useMemo(() => {
    const query = search.trim().toLowerCase();

    return recipes.filter((recipe) => {
      const label =
        recipe.metadata?.label ??
        Items[recipe.name]?.label ??
        recipe.name;

      if (query && !label?.toLowerCase().includes(query)) {
        return false;
      }

      const locks = getLockInfo(recipe);
      if (hideLocked && !locks.hasBlueprint) {
        return false;
      }

      return true;
    });
  }, [recipes, search, hideLocked, getLockInfo]);

  useEffect(() => {
    if (!filteredRecipes.length) {
      setSelectedRecipe(null);
      return;
    }

    if (
      !selectedRecipe ||
      !filteredRecipes.find((recipe) => recipe.slot === selectedRecipe.slot)
    ) {
      setSelectedRecipe(filteredRecipes[0]);
      setCountToCraft(1);
    }
  }, [filteredRecipes, selectedRecipe]);

  const reservedIngredients = useMemo(() => {
    const map: Record<string, number> = {};

    craftQueue.forEach((entry) => {
      if (!entry.ingredients) return;

      Object.entries(entry.ingredients).forEach(([name, amount]) => {
        map[name] = (map[name] || 0) + amount * entry.craftCount;
      });
    });

    return map;
  }, [craftQueue]);

  const rawMaxCraftable = useMemo(() => {
    if (!selectedRecipe || !storageInventory) return 0;
    return getCraftItemCount(selectedRecipe, reservedIngredients, storageInventory);
  }, [selectedRecipe, reservedIngredients, storageInventory]);

  const maxCraftable =
    typeof rawMaxCraftable === 'number' ? rawMaxCraftable : Number.POSITIVE_INFINITY;

  useEffect(() => {
    if (!selectedRecipe) {
      setCountToCraft(1);
      return;
    }

    if (maxCraftable === 0) {
      setCountToCraft(1);
      return;
    }

    if (Number.isFinite(maxCraftable)) {
      setCountToCraft((prev) => Math.max(1, Math.min(prev, maxCraftable)));
    }
  }, [selectedRecipe, maxCraftable]);

  const selectedLockInfo = selectedRecipe ? getLockInfo(selectedRecipe) : null;

  const canQueueSelected =
    !!selectedRecipe &&
    !!storageInventory &&
    canCraftItem(selectedRecipe, inventory.type, reservedIngredients, storageInventory) &&
    maxCraftable !== 0 &&
    !(selectedLockInfo?.locked);

  const handleAdjustCount = (delta: number) => {
    setCountToCraft((prev) => {
      const next = prev + delta;
      if (next < 1) return 1;
      if (Number.isFinite(maxCraftable)) {
        return Math.min(next, maxCraftable);
      }
      return next;
    });
  };

  const handleCountInput = (value: string) => {
    const parsed = Number(value.replace(/\D/g, ''));
    if (!Number.isFinite(parsed) || parsed <= 0) {
      setCountToCraft(1);
      return;
    }

    if (Number.isFinite(maxCraftable)) {
      setCountToCraft(Math.min(parsed, maxCraftable));
    } else {
      setCountToCraft(parsed);
    }
  };


  const handleAddToQueue = () => {
    if (!selectedRecipe || !storageInventory || !canQueueSelected) return;

    const craftCount = Number.isFinite(maxCraftable)
      ? Math.min(countToCraft, maxCraftable || 1)
      : countToCraft;

    dispatch(
      craftItem({
        benchId: inventory.id,
        benchIndex: (inventory as CraftingInventory).index,
        recipeSlot: selectedRecipe.slot,
        storageId: storageInventory.id,
        count: Math.max(1, craftCount),
      })
    );
  };

  const removeFromQueue = (index: number) => {
    dispatch(
      cancelCraft({
        benchId: inventory.id,
        jobIndex: index + 1,
      })
    );
  };

  const renderQueue = () => {
    if (!craftQueue.length) {
      return (
        <p className="crafting-queue-empty">
          {Locale.queue_empty || 'The queue is empty.'}
        </p>
      );
    }

    return (
      <div
        ref={queueScrollRef}
        className="crafting-queue-items"
      >
        {craftQueue.map((entry, index) => {
          const isActive = index === 0 && !!entry.startedAt;
          const duration = entry.duration ?? 3000;
          const started = entry.startedAt ?? now;
          const elapsed = isActive ? Math.min(now - started, duration) : 0;
          const progress = Math.min(100, (elapsed / duration) * 100);
          const remainingMs = Math.max(duration - elapsed, 0);

          const label =
            entry.metadata?.label ??
            Items[entry.name]?.label ??
            entry.name;

          return (
            <div className="crafting-queue-card" key={`${entry.slot}-${index}`}>
              <div className="crafting-queue-card-header">
                <span className="crafting-queue-card-title">{label}</span>
                <button
                  type="button"
                  className="crafting-queue-remove"
                  onClick={() => removeFromQueue(index)}
                >
                  x
                </button>
              </div>
              <div className="crafting-queue-meta">
                <span>{(Locale.quantity || 'Quantity')}: {1}</span>
                {isActive && (
                  <span>
                    {(Locale.crafting || 'Crafting')} - {(remainingMs / 1000).toFixed(1)}s
                  </span>
                )}
              </div>
              <div className="crafting-progress">
                <div className="crafting-progress-fill" style={{ width: `${progress}%` }} />
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  const renderIngredients = () => {
    if (!selectedRecipe?.ingredients) {
      return (
        <p className="crafting-no-ingredients">
          {(Locale.no_items_required || 'No items required').toUpperCase()}
        </p>
      );
    }

    const selectedLockInfo = getLockInfo(selectedRecipe);
    const requiresBlueprint = selectedLockInfo?.blueprintKey && !selectedLockInfo?.hasBlueprint;
    const bpKey = selectedLockInfo?.blueprintKey;
    const bpLabel = bpKey ? (blueprintLabels[bpKey] ?? bpKey) : undefined;

    return (
      <div className="crafting-ingredients">
        <div className="crafting-ingredients-header">
          <span>{Locale.ingredients || 'Ingredients'}</span>
          <span>{Locale.available || 'Available'}</span>
        </div>
        <div className="crafting-ingredients-body">
          {requiresBlueprint && (
            <div className="ingredient-row insufficient">
              <div className="ingredient-info">
                <span className="ingredient-label">
                  {bpLabel ?? bpKey} ({Locale.crafting_blueprint_required || 'Blueprint required'})
                </span>
              </div>
              <div className="ingredient-count">
                0 / 1
              </div>
            </div>
          )}
          {Object.entries(selectedRecipe.ingredients).map(([name, amount]) => {
            const itemData = Items[name];
            const label = itemData?.label ?? name;
            const reservedCount = reservedIngredients[name] || 0;
            const availableCount =
              storageInventory ? Math.max(getItemCount(name, storageInventory) - reservedCount, 0) : 0;
            const requiredTotal = amount * countToCraft;
            const hasEnough = availableCount >= requiredTotal;

            return (
              <div
                className={`ingredient-row ${hasEnough ? '' : 'insufficient'}`}
                key={name}
              >
                <div className="ingredient-info">
                  <span className="ingredient-label">{label}</span>
                </div>
                <div className="ingredient-count">
                  {availableCount.toLocaleString('en-US')} / {requiredTotal.toLocaleString('en-US')}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  const selectedLabel =
    selectedRecipe &&
    (selectedRecipe.metadata?.label ??
      Items[selectedRecipe.name]?.label ??
      selectedRecipe.name);

  const selectedDescription =
    selectedRecipe?.metadata?.description ??
    Items[selectedRecipe?.name || '']?.description;

  const maxLabel =
    rawMaxCraftable === 'infinity'
      ? '∞'
      : typeof rawMaxCraftable === 'number'
        ? rawMaxCraftable.toLocaleString('en-US')
        : String(rawMaxCraftable || 0);

  return (
    <div className="crafting-panel">
      {xpEnabled && (
        <div className="crafting-xp-banner">
          <div className="crafting-xp-info">
            <span className="crafting-xp-label">
              {Locale.crafting_current_xp || 'Your XP'}
            </span>
            <span className="crafting-xp-value">{formattedPlayerXp}</span>
          </div>
          <span className="crafting-xp-caption">
            {Locale.crafting_progress_active || 'Crafting progression active'}
          </span>
        </div>
      )}
      <div className="crafting-header">
        <h2>{selectedLabel || Locale.crafting_bench || 'Crafting Bench'}</h2>
        <div className="crafting-search">
          <input
            type="text"
            placeholder={Locale.craft_search_placeholder || 'Search recipes...'}
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </div>
      </div>

      <div className="crafting-body">
        <div className="crafting-list">
          {filteredRecipes.length === 0 && (
            <p className="crafting-empty">
              {Locale.craft_no_results || 'No recipes found.'}
            </p>
          )}
          {filteredRecipes.map((recipe) => {
            const label =
              recipe.metadata?.label ??
              Items[recipe.name]?.label ??
              recipe.name;

            const image = getItemUrl(recipe);
            const isSelected = selectedRecipe?.slot === recipe.slot;
            const locks = getLockInfo(recipe);
            const canCraftIngredients =
              storageInventory &&
              canCraftItem(recipe, inventory.type, reservedIngredients, storageInventory);
            const canCraft = canCraftIngredients && !locks.locked;

            return (
              <button
                type="button"
                key={recipe.slot}
                className={`crafting-item ${isSelected ? 'selected' : ''} ${canCraft ? '' : 'disabled'} ${locks.locked ? 'locked' : ''}`}
                onClick={() => {
                  setSelectedRecipe(recipe);
                  setCountToCraft(1);
                }}
              >
                <span className="crafting-item-thumb">
                  <img src={image} alt={label} />
                </span>
                <span className="crafting-item-details">
                  <span className="crafting-item-title">{label}</span>
                  {recipe.ingredients && (
                    <span className="crafting-item-meta">
                      {(Locale.craft_ingredients || 'Ingredients')}{' '}
                      {Object.keys(recipe.ingredients).length}
                    </span>
                  )}
                  {/* {locks.locked && (
                    <span className="crafting-item-meta locked">
                      {!locks.meetsXp && xpEnabled
                        ? `${Locale.crafting_xp_requirement || 'Required XP'}: ${locks.requiredXp}`
                        : recipe.blueprint
                        ? `${Locale.crafting_blueprint_required || 'Blueprint required'}: ${blueprintLabels[recipe.blueprint] ?? recipe.blueprint}`
                        : Locale.crafting_blueprint_missing || 'Blueprint required'}
                    </span>
                  )} */}
                </span>
              </button>
            );
          })}
        </div>

        <div className="crafting-details">
          <div className="crafting-preview">
            {selectedRecipe ? (
              <>
                <div className="crafting-preview-thumb">
                  <img src={getItemUrl(selectedRecipe)} alt={selectedLabel || 'recipe'} />
                </div>
                <div className="crafting-preview-info">
                  <h3>{selectedLabel}</h3>
                  {selectedDescription && (
                    <p>{selectedDescription}</p>
                  )}
                  <span className="crafting-max">
                    {(Locale.craft_max || 'Max craftable')}: {maxLabel}
                  </span>
                  {/* {storageInventory && (
                    <span className="crafting-storage">
                      {Locale.crafting_storage || 'Storage'}: {storageInventory.slots} slots · {storageInventory.maxWeight}
                    </span>
                  )} */}
                  {/* {xpEnabled && selectedLockInfo && (
                    <span className={`crafting-requirement ${selectedLockInfo.meetsXp ? 'ready' : 'missing'}`}>
                      {(Locale.crafting_xp_requirement || 'Required XP')}: {selectedLockInfo.requiredXp} ({Locale.crafting_current_xp || 'Your XP'}: {playerXp})
                    </span>
                  )}
                  {selectedLockInfo?.blueprintKey && (
                    <span className={`crafting-requirement ${selectedLockInfo.hasBlueprint ? 'ready' : 'missing'}`}>
                      {(Locale.crafting_blueprint_required || 'Blueprint required')}
                    </span>
                  )} */}
                </div>
              </>
            ) : (
              <p className="crafting-empty">
                {Locale.craft_select_recipe || 'Select a recipe to begin.'}
              </p>
            )}
          </div>

//          {renderIngredients()} 

          <div className="crafting-controls">
            <div className="crafting-amount">
              <span className="crafting-amount-label">
                {(Locale.quantity || 'Quantity')}
              </span>
              <div className="crafting-amount-input">
                <button
                  type="button"
                  onClick={() => handleAdjustCount(-1)}
                  disabled={countToCraft <= 1}
                >
                  -
                </button>
                <input
                  type="text"
                  value={countToCraft}
                  onChange={(event) => handleCountInput(event.target.value)}
                />
                <button
                  type="button"
                  onClick={() => handleAdjustCount(1)}
                  disabled={Number.isFinite(maxCraftable) && countToCraft >= maxCraftable}
                >
                  +
                </button>
              </div>
            </div>

            <div className="crafting-actions">
              <button
                type="button"
                className="crafting-queue-button"
                onClick={handleAddToQueue}
                disabled={!canQueueSelected}
              >
                {(Locale.add_to_queue || 'Add to queue').toUpperCase()}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="crafting-queue">
        <h3>{(Locale.queue || 'Queue').toUpperCase()}</h3>
        {renderQueue()}
      </div>
    </div>
  );
};

export default CraftingPanel;
