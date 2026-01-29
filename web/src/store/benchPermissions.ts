import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from '.';

export type BenchMember = {
  identifier: string;
  name: string;
  online: boolean;
  serverId?: number;
  addedBy?: string;
};

export type BenchRole = {
  id: number;
  name: string;
  canUse: boolean;
  canMove: boolean;
  canPack: boolean;
  canManage: boolean;
  memberCount: number;
  members: BenchMember[];
};

export type OnlinePlayer = {
  identifier: string;
  name: string;
  serverId?: number;
  roleId?: number;
};

export type PlayerPermissions = {
  canUse: boolean;
  canMove: boolean;
  canPack: boolean;
  canManage: boolean;
  isOwner: boolean;
  roleId?: number;
  roleName?: string;
};

export type BenchPermissionsPayload = {
  benchId: string;
  benchLabel?: string;
  owner?: { identifier: string; name: string; online: boolean; serverId?: number };
  roles: BenchRole[];
  onlinePlayers: OnlinePlayer[];
  canTransfer: boolean;
  isOwner: boolean;
  playerPermissions?: PlayerPermissions;
};

type BenchPermissionsState = {
  open: boolean;
  benchId?: string;
  benchLabel?: string;
  owner?: { identifier: string; name: string; online: boolean; serverId?: number };
  roles: BenchRole[];
  onlinePlayers: OnlinePlayer[];
  canTransfer: boolean;
  isOwner: boolean;
  playerPermissions?: PlayerPermissions;
};

const initialState: BenchPermissionsState = {
  open: false,
  roles: [],
  onlinePlayers: [],
  canTransfer: false,
  isOwner: false,
};

const benchPermissionsSlice = createSlice({
  name: 'benchPermissions',
  initialState,
  reducers: {
    setBenchPermissions(state, action: PayloadAction<BenchPermissionsPayload>) {
      const payload = action.payload;
      state.open = true;
      state.benchId = payload.benchId;
      state.benchLabel = payload.benchLabel;
      state.owner = payload.owner;
      state.roles = payload.roles ?? [];
      state.onlinePlayers = payload.onlinePlayers ?? [];
      state.canTransfer = payload.canTransfer ?? false;
      state.isOwner = payload.isOwner ?? false;
      state.playerPermissions = payload.playerPermissions;
    },
    closeBenchPermissions(state) {
      state.open = false;
      state.benchId = undefined;
      state.benchLabel = undefined;
      state.owner = undefined;
      state.roles = [];
      state.onlinePlayers = [];
      state.canTransfer = false;
      state.isOwner = false;
      state.playerPermissions = undefined;
    },
  },
});

export const { setBenchPermissions, closeBenchPermissions } = benchPermissionsSlice.actions;
export const selectBenchPermissions = (state: RootState) => state.benchPermissions;

export default benchPermissionsSlice.reducer;
