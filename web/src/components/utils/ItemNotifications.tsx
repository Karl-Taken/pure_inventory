import React, { useContext } from 'react';
import { createPortal } from 'react-dom';
import { TransitionGroup } from 'react-transition-group';
import useNuiEvent from '../../hooks/useNuiEvent';
import useQueue from '../../hooks/useQueue';
import { Locale } from '../../store/locale';
import { getItemUrl } from '../../helpers';
import { SlotWithItem } from '../../typings';
import { Items } from '../../store/items';
import Fade from './transitions/Fade';

interface ItemNotificationPayload {
  item: SlotWithItem;
  action: string;
  count: number;
}

interface ItemNotificationData {
  id: number;
  payload: ItemNotificationPayload;
  ref: React.RefObject<HTMLDivElement>;
}

export const ItemNotificationsContext = React.createContext<{
  add: (item: ItemNotificationPayload) => void;
  notifications: ItemNotificationData[];
} | null>(null);

export const useItemNotifications = () => {
  const itemNotificationsContext = useContext(ItemNotificationsContext);
  if (!itemNotificationsContext) throw new Error(`ItemNotificationsContext undefined`);
  return itemNotificationsContext;
};

const ItemNotification = React.forwardRef(
  (
    props: { payload: ItemNotificationPayload; style?: React.CSSProperties },
    ref: React.ForwardedRef<HTMLDivElement>
  ) => {
    const slotItem = props.payload.item;
    const label = slotItem.metadata?.label || Items[slotItem.name]?.label || slotItem.name;
    const count = props.payload.count ?? 1;

    return (
      <div className="notification-slot" style={props.style} ref={ref}>
        <div className="notification-title">
          <p>{props.payload.action}</p>
        </div>
        <div className="item-slot-img">
          <img src={getItemUrl(slotItem)} alt={label} />
        </div>
        <div className="item-slot-amount">
          <p>x{count}</p>
        </div>
        <div className="item-slot-label">
          <p>{label}</p>
        </div>
      </div>
    );
  }
);

export const ItemNotificationsProvider = ({ children }: { children: React.ReactNode }) => {
  const queue = useQueue<ItemNotificationData>();

  const add = (payload: ItemNotificationPayload) => {
    const ref = React.createRef<HTMLDivElement>();
    queue.add({ id: Date.now(), payload, ref });

    const timeout = setTimeout(() => {
      queue.remove();
      clearTimeout(timeout);
    }, 2500);
  };

  useNuiEvent<[item: SlotWithItem, text: string, count?: number]>('itemNotify', ([item, text, count]) => {
    add({
      item,
      action: Locale[text] || text,
      count: count ?? 1,
    });
  });

  return (
    <ItemNotificationsContext.Provider value={{ add, notifications: queue.values }}>
      {children}
    </ItemNotificationsContext.Provider>
  );
};

export const ItemNotificationsDisplay: React.FC = () => {
  const { notifications } = useItemNotifications();

  return (
    <TransitionGroup className="notification-container" style={{ bottom: '20%' }}>
      {notifications.map((notification) => (
        <Fade key={`item-notification-${notification.id}`}>
          <ItemNotification payload={notification.payload} ref={notification.ref} />
        </Fade>
      ))}
    </TransitionGroup>
  );
};
