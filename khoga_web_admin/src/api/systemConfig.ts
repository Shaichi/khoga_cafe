import { apiClient } from './client';
import type { ApiResponse } from './types';

/** com.khoga.config.dto.SystemConfigResponse — one GLOBAL config entry. */
export interface SystemConfigItem {
  key: string;
  value: string;
  updatedBy: string | null;
  updatedAt: string | null;
}

/** UC-24: all chain-wide settings. */
export async function listGlobalConfig(): Promise<SystemConfigItem[]> {
  const res = await apiClient.get<ApiResponse<SystemConfigItem[]>>('/system-config');
  return res.data.data;
}

/** UC-24: update one config key (SSADMIN only on the backend). */
export async function updateGlobalConfig(key: string, value: string): Promise<SystemConfigItem> {
  const res = await apiClient.put<ApiResponse<SystemConfigItem>>(`/system-config/${key}`, { value });
  return res.data.data;
}
