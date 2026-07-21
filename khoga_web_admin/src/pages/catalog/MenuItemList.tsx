import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  listMenuItems,
  listCategories,
  deleteMenuItem,
  archiveCategory,
  updateMenuItem,
  getMenuItem,
  type MenuItem,
  type Category,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function MenuItemList() {
  const navigate = useNavigate();
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('');

  // Modal State for Delete Item Confirmation (Figma #298:57)
  const [deletingItem, setDeletingItem] = useState<MenuItem | null>(null);

  // Modal State for Category Delete Confirmation
  const [deletingCategory, setDeletingCategory] = useState<Category | null>(null);

  const loadData = () => {
    setLoading(true);
    setError('');
    Promise.all([listMenuItems(), listCategories().catch(() => [])])
      .then(([m, c]) => {
        setItems(m.filter((i) => !i.deleted));
        setCategories(c);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(loadData, []);

  // Filtered items by selected category
  const filteredItems = useMemo(() => {
    return items.filter((m) => {
      if (selectedCategoryId && m.categoryId !== selectedCategoryId) return false;
      return true;
    });
  }, [items, selectedCategoryId]);

  // Confirm Delete Item
  const confirmDeleteItem = async (m: MenuItem) => {
    setError('');
    try {
      await deleteMenuItem(m.id);
      setDeletingItem(null);
      loadData();
    } catch (err) {
      setError(errorMessage(err));
      setDeletingItem(null);
    }
  };

  // Confirm Delete Category
  const confirmDeleteCategory = async (c: Category) => {
    setError('');
    try {
      await archiveCategory(c.id);
      if (selectedCategoryId === c.id) setSelectedCategoryId('');
      setDeletingCategory(null);
      loadData();
    } catch (err) {
      setError(errorMessage(err));
      setDeletingCategory(null);
    }
  };

  const handleToggleStatus = async (m: MenuItem) => {
    setError('');
    try {
      const fullItem = await getMenuItem(m.id);
      await updateMenuItem(m.id, {
        name: fullItem.name,
        price: fullItem.price,
        description: fullItem.description || undefined,
        categoryId: fullItem.categoryId,
        barcode: fullItem.barcode || undefined,
        imageUrl: fullItem.imageUrl || undefined,
        recipe: fullItem.recipe.map((r) => ({
          rawMaterialId: r.rawMaterialId,
          quantity: r.quantity,
          unit: r.unit,
        })),
      });
      loadData();
    } catch (err) {
      loadData();
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', fontFamily: 'Roboto, sans-serif' }}>

      {/* ── Page Header matching Figma #266:16 ── */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '16px',
        }}
      >
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11' }}>
          Quản Lý Thực Đơn &amp; Danh Mục
        </h1>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          {/* + Thêm Danh Mục button links to dedicated page /catalog/categories/new */}
          <Link
            to="/catalog/categories/new"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              height: '40px',
              padding: '0 18px',
              background: 'transparent',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              color: '#3D2314',
              fontSize: '16px',
              fontWeight: 700,
              textDecoration: 'none',
              cursor: 'pointer',
              fontFamily: 'Roboto, sans-serif',
            }}
          >
            + Thêm Danh Mục
          </Link>

          {/* + Thêm Món Ăn button */}
          <Link
            to="/catalog/new"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              height: '40px',
              padding: '0 18px',
              background: '#3D2314',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '16px',
              fontWeight: 700,
              textDecoration: 'none',
              cursor: 'pointer',
            }}
          >
            + Thêm Món Ăn
          </Link>
        </div>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {/* ── Main Content Area: 2 Panels (370px Left, 740px Right) ── */}
      <div style={{ display: 'flex', gap: '30px', alignItems: 'flex-start' }}>

        {/* ── Left Panel: Danh Mục (#266:24) ── */}
        <div
          style={{
            width: '370px',
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '21px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            boxSizing: 'border-box',
          }}
        >
          {/* H2 Title */}
          <div
            style={{
              paddingBottom: '11px',
              marginBottom: '16px',
              borderBottom: '1px solid #F2EDE8',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#3D2314' }}>
              Danh Mục
            </h2>

          </div>

          {/* Category List */}
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {/* All categories option */}
            <div
              onClick={() => setSelectedCategoryId('')}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '10px 0',
                borderBottom: '1px solid #F9F6F3',
                cursor: 'pointer',
                background: selectedCategoryId === '' ? '#FDFAF7' : 'transparent',
              }}
            >
              <span style={{ fontSize: '16px', fontWeight: 700, color: '#2C1A11', lineHeight: '35px' }}>
                Tất cả danh mục
              </span>
            </div>

            {categories.map((cat) => {
              const isSelected = selectedCategoryId === cat.id;
              return (
                <div
                  key={cat.id}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '10px 0',
                    borderBottom: '1px solid #F9F6F3',
                    background: isSelected ? '#FDFAF7' : 'transparent',
                  }}
                >
                  <span
                    onClick={() => setSelectedCategoryId(isSelected ? '' : cat.id)}
                    style={{
                      fontSize: '16px',
                      fontWeight: 700,
                      color: '#2C1A11',
                      lineHeight: '35px',
                      cursor: 'pointer',
                      flex: 1,
                    }}
                  >
                    {cat.name}
                  </span>

                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                    <Link
                      to={`/catalog/categories/${cat.id}`}
                      style={{
                        fontSize: '13px',
                        fontWeight: 600,
                        color: '#3D2314',
                        cursor: 'pointer',
                        lineHeight: '28px',
                        textDecoration: 'none',
                      }}
                    >
                      Sửa
                    </Link>
                    <span
                      onClick={() => setDeletingCategory(cat)}
                      style={{
                        fontSize: '13px',
                        fontWeight: 600,
                        color: '#C62828',
                        cursor: 'pointer',
                        lineHeight: '28px',
                      }}
                    >
                      Xóa
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* ── Right Panel: Danh Sách Món Ăn (#266:43) ── */}
        <div
          style={{
            width: '740px',
            flex: 1,
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '21px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            boxSizing: 'border-box',
          }}
        >
          {/* H2 Title */}
          <div
            style={{
              paddingBottom: '11px',
              marginBottom: '16px',
              borderBottom: '1px solid #F2EDE8',
            }}
          >
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#3D2314' }}>
              Danh Sách Món Ăn
            </h2>
          </div>

          {/* Table (#266:46 & #298:9) */}
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '16px' }}>
              <thead>
                <tr style={{ background: '#F5ECE1', height: '42.5px' }}>
                  <th
                    style={{
                      padding: '12px',
                      fontWeight: 600,
                      fontSize: '16px',
                      color: '#3D2314',
                      textAlign: 'left',
                      borderBottom: '1px solid #EADDD3',
                      width: '140px',
                    }}
                  >
                    Tên Món
                  </th>
                  <th
                    style={{
                      padding: '12px',
                      fontWeight: 600,
                      fontSize: '16px',
                      color: '#3D2314',
                      textAlign: 'left',
                      borderBottom: '1px solid #EADDD3',
                      width: '105px',
                    }}
                  >
                    Danh Mục
                  </th>
                  <th
                    style={{
                      padding: '12px',
                      fontWeight: 600,
                      fontSize: '16px',
                      color: '#3D2314',
                      textAlign: 'left',
                      borderBottom: '1px solid #EADDD3',
                      width: '116px',
                    }}
                  >
                    Giá bán
                  </th>
                  <th
                    style={{
                      padding: '12px',
                      fontWeight: 600,
                      fontSize: '16px',
                      color: '#3D2314',
                      textAlign: 'left',
                      borderBottom: '1px solid #EADDD3',
                      width: '112px',
                    }}
                  >
                    Trạng thái
                  </th>
                  <th
                    style={{
                      padding: '12px',
                      fontWeight: 600,
                      fontSize: '16px',
                      color: '#3D2314',
                      textAlign: 'left',
                      borderBottom: '1px solid #EADDD3',
                      width: '224px',
                    }}
                  >
                    Hành động
                  </th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: '30px', color: '#8C766C' }}>
                      Đang tải danh sách món…
                    </td>
                  </tr>
                ) : filteredItems.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: '30px', color: '#8C766C' }}>
                      Chưa có món ăn nào.
                    </td>
                  </tr>
                ) : (
                  filteredItems.map((m) => (
                    <tr
                      key={m.id}
                      style={{
                        height: '43px',
                        borderBottom: '1px solid #EADDD3',
                      }}
                    >
                      {/* Tên Món */}
                      <td style={{ padding: '12px', color: '#2C1A11', fontWeight: 400, fontSize: '16px' }}>
                        {m.name}
                      </td>

                      {/* Danh Mục */}
                      <td style={{ padding: '12px', color: '#2C1A11', fontWeight: 400, fontSize: '16px' }}>
                        {m.categoryName || '—'}
                      </td>

                      {/* Giá bán */}
                      <td style={{ padding: '12px', color: '#2C1A11', fontWeight: 400, fontSize: '16px' }}>
                        {m.price.toLocaleString('vi-VN')} VND
                      </td>

                      {/* Trạng thái */}
                      <td style={{ padding: '12px' }}>
                        {m.active ? (
                          <span style={{ fontSize: '13px', fontWeight: 600, color: '#2E7D32' }}>
                            ● Đang bán
                          </span>
                        ) : (
                          <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C' }}>
                            ○ Tạm ngưng
                          </span>
                        )}
                      </td>

                      {/* Hành động */}
                      <td style={{ padding: '12px' }}>
                        <div style={{ display: 'flex', gap: '14px', alignItems: 'center' }}>
                          <span
                            onClick={() => navigate(`/catalog/${m.id}`)}
                            style={{
                              fontSize: '14px',
                              fontWeight: 600,
                              color: '#3D2314',
                              cursor: 'pointer',
                            }}
                          >
                            Chi tiết
                          </span>
                          <span
                            onClick={() => handleToggleStatus(m)}
                            style={{
                              fontSize: '14px',
                              fontWeight: 600,
                              color: m.active ? '#D84315' : '#2E7D32',
                              cursor: 'pointer',
                            }}
                          >
                            {m.active ? 'Tạm ngưng' : 'Tiếp tục'}
                          </span>
                          <span
                            onClick={() => navigate(`/catalog/${m.id}/edit`)}
                            style={{
                              fontSize: '14px',
                              fontWeight: 600,
                              color: '#3D2314',
                              cursor: 'pointer',
                            }}
                          >
                            Sửa
                          </span>
                          <span
                            onClick={() => setDeletingItem(m)}
                            style={{
                              fontSize: '14px',
                              fontWeight: 700,
                              color: '#C62828',
                              cursor: 'pointer',
                            }}
                          >
                            Xóa
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* ── Category Delete Confirmation Modal ── */}
      {deletingCategory && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.45)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
          }}
        >
          <div
            style={{
              width: '484px',
              background: '#FFFFFF',
              borderRadius: '14px',
              boxShadow: '0px 20px 60px 0px rgba(0, 0, 0, 0.25)',
              padding: '32px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              boxSizing: 'border-box',
              fontFamily: 'Roboto, sans-serif',
            }}
          >
            <div
              style={{
                width: '52px',
                height: '52px',
                borderRadius: '26px',
                background: '#FDE8E8',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '24px',
                marginBottom: '16px',
              }}
            >
              🗑️
            </div>

            <h3
              style={{
                margin: '0 0 8px 0',
                fontSize: '20px',
                fontWeight: 700,
                color: '#2C1A11',
                textAlign: 'center',
              }}
            >
              Xác Nhận Xóa Danh Mục
            </h3>

            <div style={{ fontSize: '15px', color: '#5C3826', textAlign: 'center', marginBottom: '4px' }}>
              Bạn đang xóa danh mục:
            </div>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#C62828', textAlign: 'center', marginBottom: '16px' }}>
              "{deletingCategory.name}"
            </div>

            <div
              style={{
                width: '100%',
                background: '#FFF8F8',
                border: '1px solid #F5C6C6',
                borderRadius: '8px',
                padding: '12px',
                fontSize: '13px',
                color: '#C62828',
                textAlign: 'center',
                lineHeight: '1.4',
                marginBottom: '24px',
                boxSizing: 'border-box',
              }}
            >
              ⚠️ Các món ăn thuộc danh mục này sẽ chuyển sang trạng thái chưa phân loại.
            </div>

            <div style={{ display: 'flex', gap: '12px', width: '100%' }}>
              <button
                type="button"
                onClick={() => setDeletingCategory(null)}
                style={{
                  flex: 1,
                  height: '43px',
                  background: '#F5ECE1',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  color: '#3D2314',
                  fontSize: '15px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'Inter, sans-serif',
                }}
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={() => confirmDeleteCategory(deletingCategory)}
                style={{
                  flex: 1,
                  height: '43px',
                  background: '#C62828',
                  border: 'none',
                  borderRadius: '8px',
                  color: '#FFFFFF',
                  fontSize: '15px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'Inter, sans-serif',
                }}
              >
                Xác nhận Xóa
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Confirmation Modal for Deleting Item (Figma #298:57) ── */}
      {deletingItem && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.45)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
          }}
        >
          <div
            style={{
              width: '484px',
              background: '#FFFFFF',
              borderRadius: '14px',
              boxShadow: '0px 20px 60px 0px rgba(0, 0, 0, 0.25)',
              padding: '32px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              boxSizing: 'border-box',
              fontFamily: 'Roboto, sans-serif',
            }}
          >
            {/* Trash icon circle */}
            <div
              style={{
                width: '52px',
                height: '52px',
                borderRadius: '26px',
                background: '#FDE8E8',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '24px',
                marginBottom: '16px',
              }}
            >
              🗑️
            </div>

            {/* Title */}
            <h3
              style={{
                margin: '0 0 8px 0',
                fontSize: '20px',
                fontWeight: 700,
                color: '#2C1A11',
                textAlign: 'center',
              }}
            >
              Xác Nhận Xóa Món
            </h3>

            {/* Message */}
            <div style={{ fontSize: '15px', color: '#5C3826', textAlign: 'center', marginBottom: '4px' }}>
              Bạn đang xóa món:
            </div>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#C62828', textAlign: 'center', marginBottom: '16px' }}>
              "{deletingItem.name}"
            </div>

            {/* Warning Box */}
            <div
              style={{
                width: '100%',
                background: '#FFF8F8',
                border: '1px solid #F5C6C6',
                borderRadius: '8px',
                padding: '12px',
                fontSize: '13px',
                color: '#C62828',
                textAlign: 'center',
                lineHeight: '1.4',
                marginBottom: '24px',
                boxSizing: 'border-box',
              }}
            >
              ⚠️ Hành động này không thể hoàn tác. Món ăn sẽ bị xóa vĩnh viễn khỏi thực đơn và không thể khôi phục.
            </div>

            {/* Action Buttons */}
            <div style={{ display: 'flex', gap: '12px', width: '100%' }}>
              <button
                type="button"
                onClick={() => setDeletingItem(null)}
                style={{
                  flex: 1,
                  height: '43px',
                  background: '#F5ECE1',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  color: '#3D2314',
                  fontSize: '15px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'Inter, sans-serif',
                }}
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={() => confirmDeleteItem(deletingItem)}
                style={{
                  flex: 1,
                  height: '43px',
                  background: '#C62828',
                  border: 'none',
                  borderRadius: '8px',
                  color: '#FFFFFF',
                  fontSize: '15px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'Inter, sans-serif',
                }}
              >
                Xác nhận Xóa
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
