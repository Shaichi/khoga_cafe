import {
  useCallback,
  useEffect,
  useState,
} from 'react';

import { Link } from 'react-router-dom';

import {
  archiveCategory,
  listCategories,
  listMenuItems,
  setMenuItemActive,
  type Category,
  type MenuItem,
} from '../../api/catalog';

import { errorMessage } from '../../api/client';

export default function MenuItemList() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [updatingStatusId, setUpdatingStatusId] =
    useState<string | null>(null);

  /*
   * Danh mục đang được chọn để xóa.
   */
  const [deleteTarget, setDeleteTarget] =
    useState<Category | null>(null);

  const [deletingCategory, setDeletingCategory] =
    useState(false);

  const [deleteError, setDeleteError] =
    useState('');

  const load = useCallback(async () => {
    setLoading(true);

    try {
      const [menuItems, categoryList] = await Promise.all([
        listMenuItems(),
        listCategories(),
      ]);

      setItems(
        menuItems.filter((item) => !item.deleted),
      );

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

  /*
   * Mở cửa sổ xác nhận xóa danh mục.
   */
  const openDeleteCategoryModal = (
    category: Category,
  ) => {
    setDeleteTarget(category);
    setDeleteError('');
    setError('');
  };

  /*
   * Đóng cửa sổ xác nhận.
   */
  const closeDeleteCategoryModal = () => {
    if (deletingCategory) {
      return;
    }

    setDeleteTarget(null);
    setDeleteError('');
  };

  /*
   * Gọi API xóa/ẩn danh mục.
   */
  const confirmDeleteCategory = async () => {
    if (!deleteTarget) {
      return;
    }

    setDeletingCategory(true);
    setDeleteError('');
    setError('');

    try {
      await archiveCategory(deleteTarget.id);

      setDeleteTarget(null);
      await load();
    } catch (err) {
      setDeleteError(errorMessage(err));
    } finally {
      setDeletingCategory(false);
    }
  };

  /*
   * Tạm ngưng hoặc tiếp tục bán món.
   */
  const toggleItemStatus = async (
    item: MenuItem,
  ) => {
    const nextActive = !item.active;

    const action = nextActive
      ? 'tiếp tục bán'
      : 'tạm ngưng bán';

    const confirmed = window.confirm(
      `Bạn có chắc muốn ${action} món "${item.name}"?`,
    );

    if (!confirmed) {
      return;
    }

    setUpdatingStatusId(item.id);
    setError('');

    try {
      await setMenuItemActive(
        item.id,
        nextActive,
      );

      await load();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setUpdatingStatusId(null);
    }
  };

  const activeCategories = categories.filter(
    (category) => category.active,
  );

  return (
    <div className="catalog-management-page">
      {/* ==================== HEADER ==================== */}

      <div className="catalog-management-page__header">
        <h1 className="catalog-management-page__title">
          Quản Lý Thực Đơn &amp; Danh Mục
        </h1>

        <div className="catalog-management-page__header-actions">
          <Link
            to="/catalog/categories/new"
            className="catalog-button catalog-button--outline"
          >
            + Thêm Danh Mục
          </Link>

          <Link
            to="/catalog/new"
            className="catalog-button catalog-button--primary"
          >
            + Thêm Món Ăn
          </Link>
        </div>
      </div>

      {/* ==================== LỖI CHUNG ==================== */}

      {error && (
        <div className="alert alert--error catalog-management-page__alert">
          {error}
        </div>
      )}

      <div className="catalog-management-grid">
        {/* ==================== DANH MỤC ==================== */}

        <section className="catalog-panel catalog-panel--categories">
          <div className="catalog-panel__heading">
            Danh Mục
          </div>

          <div className="catalog-panel__divider" />

          <div className="category-list">
            {loading ? (
              <div className="catalog-empty">
                Đang tải…
              </div>
            ) : activeCategories.length === 0 ? (
              <div className="catalog-empty">
                Chưa có danh mục.
              </div>
            ) : (
              activeCategories.map((category) => (
                <div
                  className="category-row"
                  key={category.id}
                >
                  <span className="category-row__name">
                    {category.name}
                  </span>

                  <span className="category-row__actions">
                    <Link
                      to={`/catalog/categories/${category.id}/edit`}
                      className="catalog-text-action"
                    >
                      Sửa
                    </Link>

                    <button
                      type="button"
                      className="catalog-text-action catalog-text-action--danger"
                      onClick={() =>
                        openDeleteCategoryModal(category)
                      }
                    >
                      Xóa
                    </button>
                  </span>
                </div>
              ))
            )}
          </div>
        </section>

        {/* ==================== DANH SÁCH MÓN ĂN ==================== */}

        <section className="catalog-panel catalog-panel--items">
          <div className="catalog-panel__heading">
            Danh Sách Món Ăn
          </div>

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
                    <td
                      colSpan={5}
                      className="catalog-table__empty"
                    >
                      Đang tải…
                    </td>
                  </tr>
                ) : items.length === 0 ? (
                  <tr>
                    <td
                      colSpan={5}
                      className="catalog-table__empty"
                    >
                      Chưa có món ăn.
                    </td>
                  </tr>
                ) : (
                  items.map((item) => (
                    <tr key={item.id}>
                      <td>
                        {item.name}
                      </td>

                      <td>
                        {item.categoryName || '—'}
                      </td>

                      <td className="catalog-table__price">
                        {item.price.toLocaleString(
                          'vi-VN',
                        )}{' '}
                        VND
                      </td>

                      <td>
                        <span
                          className={`catalog-status ${item.active
                              ? 'catalog-status--active'
                              : 'catalog-status--inactive'
                            }`}
                        >
                          <span className="catalog-status__dot" />

                          {item.active
                            ? 'Đang bán'
                            : 'Tạm ngưng'}
                        </span>
                      </td>

                      <td>
                        <div className="catalog-row-actions">
                          <Link
                            to={`/catalog/${item.id}`}
                            className="catalog-text-action"
                          >
                            Chi tiết
                          </Link>

                          <button
                            type="button"
                            className={`catalog-text-action ${item.active
                                ? 'catalog-text-action--pause'
                                : 'catalog-text-action--continue'
                              }`}
                            disabled={
                              updatingStatusId === item.id
                            }
                            onClick={() =>
                              void toggleItemStatus(item)
                            }
                          >
                            {updatingStatusId === item.id
                              ? 'Đang lưu…'
                              : item.active
                                ? 'Tạm ngưng'
                                : 'Tiếp tục'}
                          </button>

                          <Link
                            to={`/catalog/${item.id}/edit`}
                            className="catalog-text-action"
                          >
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

      {/* ==================== MODAL XÓA DANH MỤC ==================== */}

      {deleteTarget && (
        <div
          className="category-delete-backdrop"
          role="presentation"
          onMouseDown={closeDeleteCategoryModal}
        >
          <section
            className="category-delete-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="category-delete-title"
            onMouseDown={(event) =>
              event.stopPropagation()
            }
          >
            <div
              className="category-delete-modal__icon"
              aria-hidden="true"
            >
              <svg
                width="25"
                height="25"
                viewBox="0 0 24 24"
                fill="none"
              >
                <path
                  d="M9 4H15"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                />

                <path
                  d="M4.5 7H19.5"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                />

                <path
                  d="M7 7L7.7 20H16.3L17 7"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />

                <path
                  d="M10 10.5V16.5"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                />

                <path
                  d="M14 10.5V16.5"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                />
              </svg>
            </div>

            <h2
              id="category-delete-title"
              className="category-delete-modal__title"
            >
              Xác Nhận Xóa Danh Mục
            </h2>

            <p className="category-delete-modal__description">
              Bạn có chắc chắn muốn xóa danh mục:
            </p>

            <strong className="category-delete-modal__category-name">
              '{deleteTarget.name}'?
            </strong>

            <p className="category-delete-modal__notice">
              Hành động này sẽ xóa danh mục khỏi danh sách.
              (Lưu ý: Chỉ có thể xóa danh mục khi không có
              món ăn nào bên trong).
            </p>

            {deleteError && (
              <div className="category-delete-modal__error">
                {deleteError}
              </div>
            )}

            <div className="category-delete-modal__actions">
              <button
                type="button"
                className="category-delete-modal__button category-delete-modal__button--cancel"
                disabled={deletingCategory}
                onClick={closeDeleteCategoryModal}
              >
                Hủy (Cancel)
              </button>

              <button
                type="button"
                className="category-delete-modal__button category-delete-modal__button--confirm"
                disabled={deletingCategory}
                onClick={() =>
                  void confirmDeleteCategory()
                }
              >
                {deletingCategory
                  ? 'Đang xóa…'
                  : 'Xác nhận Xóa (Confirm)'}
              </button>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}