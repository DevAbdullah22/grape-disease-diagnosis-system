import { beforeEach, describe, expect, it, vi } from 'vitest';
import api, { API_BASE } from '../../../services/api';
import {
  createCategory,
  createItem,
  deleteCategory,
  deleteItem,
  getCategories,
  getCategoryById,
  getCategoryDeleteInfo,
  getItem,
  getItemsByCategory,
  resolveImageUrl,
  updateCategory,
  updateItem
} from './libraryApi';

describe('libraryApi', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('calls category and item endpoints with the expected payloads', async () => {
    const getSpy = vi.spyOn(api, 'get').mockResolvedValue({ data: { ok: true } });
    const postSpy = vi.spyOn(api, 'post').mockResolvedValue({ data: { ok: true } });
    const putSpy = vi.spyOn(api, 'put').mockResolvedValue({ data: { ok: true } });
    const deleteSpy = vi.spyOn(api, 'delete').mockResolvedValue({ data: { ok: true } });

    await getCategories();
    await getCategoryById('cat-1');
    await createCategory({ name: 'الأمراض' });
    await updateCategory({ id: 'cat-1', name: 'الوقاية' });
    await deleteCategory('cat-1');
    await getCategoryDeleteInfo('cat-1');
    await getItemsByCategory('cat-1');
    await getItem('item-1');
    await createItem(new FormData());
    await updateItem('item-1', new FormData());
    await deleteItem('item-1');

    expect(getSpy).toHaveBeenCalledWith('/LibraryCategory');
    expect(getSpy).toHaveBeenCalledWith('/LibraryCategory/cat-1');
    expect(getSpy).toHaveBeenCalledWith('/LibraryCategory/cat-1/delete-info');
    expect(getSpy).toHaveBeenCalledWith('/Library/category/cat-1/items');
    expect(getSpy).toHaveBeenCalledWith('/Library/item/item-1');
    expect(postSpy).toHaveBeenCalledWith('/LibraryCategory', { name: 'الأمراض' });
    expect(putSpy).toHaveBeenCalledWith('/LibraryCategory/cat-1', { name: 'الوقاية' });
    expect(deleteSpy).toHaveBeenCalledWith('/LibraryCategory/cat-1');
    expect(postSpy).toHaveBeenCalledWith(
      '/Library/item',
      expect.any(FormData),
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    expect(putSpy).toHaveBeenCalledWith(
      '/Library/item/item-1',
      expect.any(FormData),
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    expect(deleteSpy).toHaveBeenCalledWith('/Library/item/item-1');
  });

  it('resolves image urls for relative and absolute paths safely', () => {
    expect(resolveImageUrl('/uploads/image.png')).toBe(`${API_BASE}/uploads/image.png`);
    expect(resolveImageUrl('uploads/image.png')).toBe(`${API_BASE}/uploads/image.png`);
    expect(resolveImageUrl('https://cdn.example.com/image.png')).toBe('https://cdn.example.com/image.png');
    expect(resolveImageUrl(null)).toBeUndefined();
    expect(resolveImageUrl({} as unknown as string)).toBeUndefined();
  });
});
