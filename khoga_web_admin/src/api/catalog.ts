import { apiClient } from './client';
import type { ApiResponse, PageResponse } from './types';

/* ===================== Categories ===================== */
export interface Category {
  id: string;
  name: string;
  description: string | null;
  active: boolean;
}
export interface CategoryInput {
  name: string;
  description?: string;
}

export async function listCategories(active?: boolean): Promise<Category[]> {
  const params: Record<string, unknown> = { size: 100 };
  if (active !== undefined) params.active = active;
  const res = await apiClient.get<ApiResponse<PageResponse<Category>>>('/categories', { params });
  return res.data.data.content;
}
export async function createCategory(input: CategoryInput): Promise<Category> {
  const res = await apiClient.post<ApiResponse<Category>>('/categories', input);
  return res.data.data;
}
export async function updateCategory(id: string, input: CategoryInput): Promise<Category> {
  const res = await apiClient.put<ApiResponse<Category>>(`/categories/${id}`, input);
  return res.data.data;
}
export async function archiveCategory(id: string): Promise<void> {
  await apiClient.delete(`/categories/${id}`);
}

/* ===================== Raw materials ===================== */
export interface RawMaterial {
  id: string;
  code: string;
  name: string;
  unit: string;
  suggestedMinThreshold: number | null;
  standardCost: number | null;
  category: string | null;
  active: boolean;
}
export interface CreateRawMaterialInput {
  code: string;
  name: string;
  unit: string;
  suggestedMinThreshold?: number | null;
  standardCost?: number | null;
  category?: string;
}
export interface UpdateRawMaterialInput {
  name: string;
  unit: string;
  suggestedMinThreshold?: number | null;
  standardCost?: number | null;
  category?: string;
  active?: boolean;
}

export async function listRawMaterials(): Promise<RawMaterial[]> {
  const res = await apiClient.get<ApiResponse<PageResponse<RawMaterial>>>('/raw-materials', { params: { size: 200 } });
  return res.data.data.content;
}
export async function getRawMaterial(id: string): Promise<RawMaterial> {
  const res = await apiClient.get<ApiResponse<RawMaterial>>(`/raw-materials/${id}`);
  return res.data.data;
}
export async function createRawMaterial(input: CreateRawMaterialInput): Promise<RawMaterial> {
  const res = await apiClient.post<ApiResponse<RawMaterial>>('/raw-materials', input);
  return res.data.data;
}
export async function updateRawMaterial(id: string, input: UpdateRawMaterialInput): Promise<RawMaterial> {
  const res = await apiClient.put<ApiResponse<RawMaterial>>(`/raw-materials/${id}`, input);
  return res.data.data;
}
export async function deactivateRawMaterial(id: string): Promise<void> {
  await apiClient.delete(`/raw-materials/${id}`);
}

/* ===================== Menu items ===================== */
export interface RecipeLine {
  rawMaterialId: string;
  rawMaterialName?: string;
  quantity: number;
  unit: string;
}
export interface MenuItem {
  id: string;
  name: string;
  price: number;
  categoryId: string | null;
  categoryName: string | null;
  abbreviation: string;
  barcode: string | null;
  active: boolean;
  deleted: boolean;
}
export interface MenuItemDetail extends MenuItem {
  description: string | null;
  imageUrl: string | null;
  recipe: RecipeLine[];
  toppings: unknown[];
}
export interface MenuItemInput {
  name: string;
  price: number;
  description?: string;
  categoryId?: string | null;
  barcode?: string;
  imageUrl?: string;
  recipe: { rawMaterialId: string; quantity: number; unit: string }[];
}

export async function listMenuItems(): Promise<MenuItem[]> {
  const res = await apiClient.get<ApiResponse<PageResponse<MenuItem>>>('/menu-items', { params: { size: 200 } });
  return res.data.data.content;
}
export async function getMenuItem(id: string): Promise<MenuItemDetail> {
  const res = await apiClient.get<ApiResponse<MenuItemDetail>>(`/menu-items/${id}`);
  return res.data.data;
}
export async function createMenuItem(input: MenuItemInput): Promise<MenuItemDetail> {
  const res = await apiClient.post<ApiResponse<MenuItemDetail>>('/menu-items', input);
  return res.data.data;
}
export async function updateMenuItem(id: string, input: MenuItemInput): Promise<MenuItemDetail> {
  const res = await apiClient.put<ApiResponse<MenuItemDetail>>(`/menu-items/${id}`, input);
  return res.data.data;
}
export async function deleteMenuItem(id: string): Promise<void> {
  await apiClient.delete(`/menu-items/${id}`);
}
