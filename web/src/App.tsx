import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setupInventory } from './store/inventory';
import { Inventory } from './typings';
import { useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';
import BenchPermissionsModal from './components/Crafting/BenchPermissionsModal';
import { useScale } from './hooks/useScale';
import { ItemNotificationsDisplay } from './components/utils/ItemNotifications';

type ThemeConfig = {
  colors?: Record<string, string>;
};

type RarityConfig = {
  Enabled: boolean;
  Levels: Record<string, {
    label: string;
    text: string;
    background: string;
    color: string;
    animation?: boolean;
  }>;
};

const applyRarityStyles = (config?: RarityConfig) => {
  if (!config || !config.Enabled) return;

  let style = document.getElementById('rarity-styles');
  if (!style) {
    style = document.createElement('style');
    style.id = 'rarity-styles';
    document.head.appendChild(style);
  }

  let css = '';
  Object.entries(config.Levels).forEach(([key, level]) => {
    const rarityClass = `rarity-${key.toLowerCase()}`;
    const selector = `.item-slot.${rarityClass}, .utility-slot.${rarityClass}`;
    // Set --borderColor for the pseudo-element glow
    // Set background from config (usually a radial gradient)
    // Set border-color to transparent to hide the default border
    css += `${selector} { --borderColor: ${level.color} !important; background: ${level.background} !important; border-color: transparent !important; }\n`;
    css += `${selector} .item-name { color: ${level.text} !important; }\n`;

    if (level.animation) {
      css += `${selector} .rarity-glow { animation: ${rarityClass}-pulse 3s infinite ease-in-out !important; }\n`;
      css += `@keyframes ${rarityClass}-pulse { 
        0% { filter: drop-shadow(0 0 3px ${level.color}); } 
        50% { filter: drop-shadow(0 0 8px ${level.color}); } 
        100% { filter: drop-shadow(0 0 3px ${level.color}); } 
        }\n`;
    }
  });

  style.innerHTML = css;
};

const applyTheme = (theme?: ThemeConfig) => {
  if (!theme) return;
  const root = document.documentElement;

  const colors = theme.colors || {};
  Object.entries(colors).forEach(([key, value]) => {
    if (typeof value === 'string' && value.length > 0) {
      const varName = key.startsWith('--') ? key : `--${key.replace(/_/g, '-')}`;
      root.style.setProperty(varName, value);
    }
  });
};

debugData([
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'test',
        type: 'player',
        slots: 50,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'iron',
            weight: 3000,
            metadata: {
              description: `name: Svetozar Miletic  \n Gender: Male`,
              ammo: 3,
              mustard: '60%',
              ketchup: '30%',
              mayo: '10%',
            },
            count: 5,
          },
          { slot: 2, name: 'powersaw', weight: 0, count: 1, metadata: { durability: 75 } },
          { slot: 3, name: 'copper', weight: 100, count: 12, metadata: { type: 'Special' } },
          {
            slot: 4,
            name: 'water',
            weight: 100,
            count: 1,
            metadata: { description: 'Generic item description' },
          },
          { slot: 5, name: 'water', weight: 100, count: 1 },
          {
            slot: 6,
            name: 'backwoods',
            weight: 100,
            count: 1,
            metadata: {
              label: 'Russian Cream',
              imageurl: 'https://i.imgur.com/2xHhTTz.png',
            },
          },
        ],
      },
      rightInventory: {
        id: 'shop',
        type: 'crafting',
        slots: 5000,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'lockpick',
            weight: 500,
            price: 300,
            ingredients: {
              iron: 5,
              copper: 12,
              powersaw: 0.1,
            },
            metadata: {
              description: 'Simple lockpick that breaks easily and can pick basic door locks',
            },
          },
        ],
      },
    },
  },
]);

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  useScale();
  const manager = useDragDropManager();

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
    theme?: ThemeConfig;
    rarity?: RarityConfig;
  }>('init', ({ locale, items, leftInventory, imagepath, theme, rarity }) => {
    // console.log('[ox_inventory] Init received. Rarity config:', rarity);

    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) {
      Items[name] = items[name];
      const item = items[name];
      if (item && item.rarity) {
        // console.log(`[ox_inventory] Item ${name} has rarity: ${item.rarity}`);
      }
    }

    setImagePath(imagepath);
    applyTheme(theme);
    applyRarityStyles(rarity);
    dispatch(setupInventory({ leftInventory }));
  });

  fetchNui('uiLoaded', {});

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <>
      <div
        style={{
          width: '100vw',
          height: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            width: '120rem',
            height: '67.5rem',
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          <div className="app-wrapper">
            <InventoryComponent />
            <KeyPress />
          </div>
          <BenchPermissionsModal />
          <ItemNotificationsDisplay />
        </div>
      </div>
      <DragPreview />
    </>
  );
};

addEventListener("dragstart", function (event) {
  event.preventDefault()
})

export default App;
