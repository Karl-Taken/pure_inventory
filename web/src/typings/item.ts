export type ItemData = {
  name: string;
  label: string;
  stack: boolean;
  usable: boolean;
  close: boolean;
  count: number;
  ammo?: boolean;
  magazine?: boolean;
  weapon?: boolean;
  ammoType?: string;
  capacity?: number;
  description?: string;
  buttons?: string[];
  ammoName?: string;
  image?: string;
  rarity?: string;
};
