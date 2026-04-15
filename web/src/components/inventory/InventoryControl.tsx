import React from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [, use] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));

  const [, give] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onGive(source.item);
    },
  }));

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.valueAsNumber =
      isNaN(event.target.valueAsNumber) || event.target.valueAsNumber < 0 ? 0 : Math.floor(event.target.valueAsNumber);
    dispatch(setItemAmount(event.target.valueAsNumber));
  };

  const decreaseAmount = () => {
    dispatch(setItemAmount(itemAmount > 0 ? itemAmount - 1 : 0));
  };

  const increaseAmount = () => {
    dispatch(setItemAmount(itemAmount < 999 ? itemAmount + 1 : 999));
  };

  const clearAmount = () => {
    dispatch(setItemAmount(0));
  };

  return (
    <>
      <div className="gqty">
        <div className={`gqty__wrap ${itemAmount > 0 ? 'gqty--active' : ''}`} title="Default quantity for drag & drop">
          <span className="gqty__label">{t('quantity_short', t('quantity', 'Qty'))}</span>
          <button className="gqty__btn" onClick={decreaseAmount}>
            <span className="material-symbols-rounded">remove</span>
          </button>
          <input
            className="gqty__input"
            type="number"
            value={itemAmount || ''}
            onChange={inputHandler}
            min={0}
            max={999}
            placeholder={itemAmount === 0 ? t('amount', 'Amount') : undefined}
          />
          <button className="gqty__btn" onClick={increaseAmount}>
            <span className="material-symbols-rounded">add</span>
          </button>
          <button className="gqty__clear" onClick={clearAmount} disabled={itemAmount === 0}>
            <span className="material-symbols-rounded">close</span>
          </button>
        </div>
      </div>

      {/* <div className="inventory-actions">
        <button className="inventory-action-button" ref={use}>
          {Locale.ui_use || 'Use'}
        </button>
        <button className="inventory-action-button" ref={give}>
          {Locale.ui_give || 'Give'}
        </button>
        <button className="inventory-action-button" onClick={() => fetchNui('exit')}>
          {Locale.ui_close || 'Close'}
        </button>
      </div> */}

    </>
  );
};

export default InventoryControl;
