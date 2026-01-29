import React, { useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import UsefulControls from './UsefulControls';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [infoVisible, setInfoVisible] = useState(false);

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
      <UsefulControls infoVisible={infoVisible} setInfoVisible={setInfoVisible} />
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

      <button className="useful-controls-button" onClick={() => setInfoVisible(true)}>
        <svg xmlns="http://www.w3.org/2000/svg" height="2em" viewBox="0 0 524 524">
          <path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM216 336h24V272H216c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24H216c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 1 1 0 64 32 32 0 1 1 0-64z" />
        </svg>
      </button>
    </>
  );
};

export default InventoryControl;
