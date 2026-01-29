import { createAsyncThunk } from '@reduxjs/toolkit';
import { fetchNui } from '../utils/fetchNui';

export const craftItem = createAsyncThunk(
  'inventory/craftItem',
  async (
    data: { benchId: string; benchIndex?: number; recipeSlot: number; storageId?: string; count: number; toSlot?: number },
    { rejectWithValue }
  ) => {
    try {
      const response = await fetchNui<boolean>('craftItem', data);

      if (response === false) {
        return rejectWithValue(response);
      }
    } catch (error) {
      return rejectWithValue(false);
    }
  }
);
