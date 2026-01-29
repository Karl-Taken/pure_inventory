import { createAsyncThunk } from '@reduxjs/toolkit';
import { fetchNui } from '../utils/fetchNui';

export const cancelCraft = createAsyncThunk(
    'inventory/cancelCraft',
    async (
        data: { benchId: string; jobIndex: number },
        { rejectWithValue }
    ) => {
        try {
            const response = await fetchNui<boolean>('cancelCraft', data);

            if (response === false) {
                return rejectWithValue(response);
            }
        } catch (error) {
            return rejectWithValue(false);
        }
    }
);
