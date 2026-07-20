import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import {
  archiveCategory,
  createCategory,
  listCategories,
  listMenuItems,
  setMenuItemActive,
  updateCategory,
  type Category,
  type MenuItem,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

type CategoryDialog =
  | { mode: 'create' }
  | { mode: 'edit'; category: Category };

export default function MenuItemList() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [categoryDialog, setCategoryDialog] = useState<CategoryDialog | null>(null);
  const [categoryName, setCategoryName] = useState('');
  const [categoryDescription, setCategoryDescription] = useState('');
  const [savingCategory, setSavingCategory] = useState(false);

  const [updatingStatusId, setUpdatingStatusId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [menuItems, categoryList] = await Promise.all([
        listMenuItems(),
        listCategories(),
      ]);
      setItems(menuItems.filter((item) => !item.deleted));
      setCategories(categoryList);
      setError('');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const openCreateCategory = () => {
    setCategoryName('');
    setCategoryDescription('');
    setCategoryDialog({ mode: 'create' });
    setError('');
  };

  const openEditCategory = (category: Category) => {
    setCategoryName(category.name);
    setCategoryDescription(category.description ?? '');
    setCategoryDialog({ mode: 'edit', category });
    setError('');
  };

  const closeCategoryDialog = () => {
    if (!savingCategory) setCategoryDialog(null);
  };

  const saveCategory = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!categoryDialog) return;

    const name = categoryName.trim();
    if (!name) {
      setError('Tên danh mục không được để trống.');
      return;
    }

    setSavingCategory(true);
    setError('');
    try {
      const payload = {
        name,
        description: categoryDescription.trim(),
      };

      if (categoryDialog.mode === 'create') {
        await createCategory(payload);
      } else {
        await updateCategory(categoryDialog.category.id, payload);
      }

      setCategoryDialog(null);
      await load();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSavingCategory(false);
    }
  };

  const removeCategory = async (category: Category) => {
    const confirmed = window.confirm(
      `Xóa danh mục "${category.name}"?\n\nDanh mục chỉ được xóa khi không còn món đang bán.`,
    );
    if (!confirmed) return;

    setError('');
    try {
      await archiveCategory(category.id);
      await load();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  const toggleItemStatus = async (item: MenuItem) => {
    const nextActive = !item.active;
    const action = nextActive ? 'tiếp tục bán' : 'tạm ngưng bán';
    if (!window.confirm(`Bạn có chắc muốn ${action} món "${item.name}"?`)) return;

    setUpdatingStatusId(item.id);
    setError('');
    try {
      await setMenuItemActive(item.id, nextActive);
      await load();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setUpdatingStatusId(null);
    }
  };

  const activeCategories = categories.filter((category) => category.active);

  return (
    <div className="catalog-management-page">
      <div className="catalog-management-page__header">
        <h1 className="catalog-management-page__title">Quản Lý Thực Đơn &amp; Danh Mục</h1>

        <div className="catalog-management-page__header-actions">
          <button
            type="button"
            className="catalog-button catalog-button--outline"
            onClick={openCreateCategory}
          >
            + Thêm Danh Mục
          </button>
          <Link to="/catalog/new" className="catalog-button catalog-button--primary">
            + Thêm Món Ăn
          </Link>
        </div>
      </div>

      {error && <div className="alert alert--error catalog-management-page__alert">{error}</div>}

      <div className="catalog-management-grid">
        <section className="catalog-panel catalog-panel--categories">
          <div className="catalog-panel__heading">Danh Mục</div>
          <div className="catalog-panel__divider" />

          <div className="category-list">
            {loading ? (
              <div className="catalog-empty">Đang tải…</div>
            ) : activeCategories.length === 0 ? (
              <div className="catalog-empty">Chưa có danh mục.</div>
            ) : (
              activeCategories.map((category) => (
                <div className="category-row" key={category.id}>
                  <span className="category-row__name">{category.name}</span>
                  <span className="category-row__actions">
                    <button
                      type="button"
                      className="catalog-text-action"
                      onClick={() => openEditCategory(category)}
                    >
                      Sửa
                    </button>
                    <button
                      type="button"
                      className="catalog-text-action catalog-text-action--danger"
                      onClick={() => void removeCategory(category)}
                    >
                      Xóa
                    </button>
                  </span>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="catalog-panel catalog-panel--items">
          <div className="catalog-panel__heading">Danh Sách Món Ăn</div>
          <div className="catalog-panel__divider" />

          <div className="catalog-table-wrap">
            <table className="catalog-table">
              <thead>
                <tr>
                  <th>Tên Món</th>
                  <th>Danh Mục</th>
                  <th>Giá bán</th>
                  <th>Trạng thái</th>
                  <th>Hành động</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={5} className="catalog-table__empty">Đang tải…</td>
                  </tr>
                ) : items.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="catalog-table__empty">Chưa có món ăn.</td>
                  </tr>
                ) : (
                  items.map((item) => (
                    <tr key={item.id}>
                      <td>{item.name}</td>
                      <td>{item.categoryName || '—'}</td>
                      <td className="catalog-table__price">
                        {item.price.toLocaleString('vi-VN')} VND
                      </td>
                      <td>
                        <span className={`catalog-status ${item.active ? 'catalog-status--active' : 'catalog-status--inactive'}`}>
                          <span className="catalog-status__dot" />
                          {item.active ? 'Đang bán' : 'Tạm ngưng'}
                        </span>
                      </td>
                      <td>
                        <div className="catalog-row-actions">
                          <Link to={`/catalog/${item.id}`} className="catalog-text-action">
                            Chi tiết
                          </Link>
                          <button
                            type="button"
                            className={`catalog-text-action ${item.active ? 'catalog-text-action--pause' : 'catalog-text-action--continue'}`}
                            disabled={updatingStatusId === item.id}
                            onClick={() => void toggleItemStatus(item)}
                          >
                            {updatingStatusId === item.id
                              ? 'Đang lưu…'
                              : item.active
                                ? 'Tạm ngưng'
                                : 'Tiếp tục'}
                          </button>
                          <Link to={`/catalog/${item.id}/edit`} className="catalog-text-action">
                            Sửa
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>
      </div>

      {categoryDialog && (
        <div className="catalog-modal-backdrop" role="presentation" onMouseDown={closeCategoryDialog}>
          <form
            className="catalog-modal"
            onSubmit={saveCategory}
            onMouseDown={(event) => event.stopPropagation()}
          >
            <div className="catalog-modal__header">
              <h2>{categoryDialog.mode === 'create' ? 'Thêm Danh Mục' : 'Sửa Danh Mục'}</h2>
              <button type="button" className="catalog-modal__close" onClick={closeCategoryDialog}>×</button>
            </div>

            <label className="field">
              <span className="label">Tên danh mục *</span>
              <input
                className="input"
                value={categoryName}
                onChange={(event) => setCategoryName(event.target.value)}
                placeholder="Ví dụ: Cà phê"
                autoFocus
                required
              />
            </label>

            <label className="field">
              <span className="label">Mô tả</span>
              <input
                className="input"
                value={categoryDescription}
                onChange={(event) => setCategoryDescription(event.target.value)}
                placeholder="Mô tả ngắn (không bắt buộc)"
              />
            </label>

            <div className="catalog-modal__actions">
              <button type="button" className="catalog-button catalog-button--outline" onClick={closeCategoryDialog}>
                Hủy
              </button>
              <button type="submit" className="catalog-button catalog-button--primary" disabled={savingCategory}>
                {savingCategory ? 'Đang lưu…' : 'Lưu'}
              </button>
            </div>
          </form>
        </div>
      )}

    </div>
  );
}
