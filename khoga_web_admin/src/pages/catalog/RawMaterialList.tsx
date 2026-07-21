import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { listRawMaterials, deactivateRawMaterial, type RawMaterial } from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function RawMaterialList() {
  const navigate = useNavigate();
  const [items, setItems] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');

  const loadData = () => {
    setLoading(true);
    setError('');
    listRawMaterials()
      .then(setItems)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(loadData, []);

  // Unique categories list for dropdown filter
  const categoriesList = useMemo(() => {
    const set = new Set<string>();
    items.forEach((item) => {
      if (item.category) set.add(item.category);
    });
    return Array.from(set);
  }, [items]);

  // Filtered raw materials
  const filteredItems = useMemo(() => {
    const q = search.trim().toLowerCase();
    return items.filter((m) => {
      if (selectedCategory && m.category !== selectedCategory) return false;
      if (!q) return true;
      return [m.code, m.name, m.category, m.unit].some((f) => f?.toLowerCase().includes(q));
    });
  }, [items, search, selectedCategory]);

  const handleDeactivate = async (m: RawMaterial) => {
    if (!window.confirm(`Bạn có chắc chắn muốn vô hiệu / ngừng dùng nguyên liệu "${m.name}"?`)) return;
    setError('');
    try {
      await deactivateRawMaterial(m.id);
      loadData();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px', fontFamily: 'Inter, Segoe UI, Roboto, sans-serif' }}>
      
      {/* ── Page Header matching Figma #372:16 ── */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '16px',
        }}
      >
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontFamily: 'Roboto, sans-serif' }}>
            HQ Admin Portal &rsaquo; Quản lý kho nguyên liệu
          </div>
          <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11', fontFamily: 'Inter, sans-serif' }}>
            Quản Lý Nguyên Liệu (Toàn Chuỗi)
          </h1>
        </div>

        <Link
          to="/raw-materials/new"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            height: '38px',
            padding: '0 20px',
            background: '#3D2314',
            borderRadius: '8px',
            color: '#FFFFFF',
            fontSize: '16px',
            fontWeight: 700,
            textDecoration: 'none',
            fontFamily: 'Inter, sans-serif',
            cursor: 'pointer',
          }}
        >
          + Thêm Nguyên Liệu
        </Link>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {/* ── Filter Toolbar (#372:20) ── */}
      <div style={{ display: 'flex', gap: '14px', alignItems: 'center', flexWrap: 'wrap' }}>
        {/* Category Dropdown */}
        <select
          aria-label="Lọc theo nhóm nguyên liệu"
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          style={{
            height: '42px',
            padding: '0 14px',
            background: '#FFFFFF',
            border: '1px solid #E5DBCF',
            borderRadius: '8px',
            fontSize: '14px',
            color: '#2C1A11',
            outline: 'none',
            cursor: 'pointer',
            fontFamily: 'Inter, sans-serif',
            minWidth: '180px',
          }}
        >
          <option value="">Tất cả nhóm nguyên liệu</option>
          {categoriesList.map((cat) => (
            <option key={cat} value={cat}>
              {cat}
            </option>
          ))}
        </select>

        {/* Search input */}
        <input
          type="text"
          placeholder="Tìm theo mã, tên, nhóm nguyên liệu..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            height: '42px',
            width: '280px',
            padding: '0 14px',
            background: '#FFFFFF',
            border: '1px solid #E5DBCF',
            borderRadius: '8px',
            fontSize: '14px',
            color: '#2C1A11',
            outline: 'none',
            fontFamily: 'Inter, sans-serif',
          }}
        />
      </div>

      {/* ── Table Container Card (#372:21) ── */}
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '10px',
          padding: '21px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
          overflowX: 'auto',
        }}
      >
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '16px' }}>
          <thead>
            <tr style={{ background: '#F5ECE1', height: '49px' }}>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Inter, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '132px',
                }}
              >
                Mã NL
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Inter, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '231px',
                }}
              >
                Tên Nguyên Liệu
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Inter, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '202px',
                }}
              >
                Đơn Vị Tính
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Inter, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '142px',
                }}
              >
                Tồn Tối Thiểu Gợi Ý
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Inter, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '143px',
                }}
              >
                Mô Tả / Nhóm
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Segoe UI, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '139px',
                }}
              >
                Trạng thái
              </th>
              <th
                style={{
                  padding: '14px 15px',
                  fontFamily: 'Segoe UI, sans-serif',
                  fontWeight: 700,
                  fontSize: '16px',
                  color: '#3D2314',
                  textAlign: 'left',
                  borderBottom: '1px solid #EADDD3',
                  width: '146px',
                }}
              >
                Hành động
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '30px', color: '#8C766C' }}>
                  Đang tải danh sách nguyên liệu…
                </td>
              </tr>
            ) : filteredItems.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '30px', color: '#8C766C' }}>
                  Chưa có nguyên liệu nào.
                </td>
              </tr>
            ) : (
              filteredItems.map((m) => (
                <tr
                  key={m.id}
                  style={{
                    height: '49px',
                    borderBottom: '1px solid #EADDD3',
                  }}
                >
                  {/* Mã NL (#372:40) */}
                  <td style={{ padding: '14px 15px', color: '#2C1A11', fontWeight: 700, fontFamily: 'Inter, sans-serif' }}>
                    {m.code}
                  </td>

                  {/* Tên Nguyên Liệu (#372:42) */}
                  <td style={{ padding: '14px 15px', color: '#2C1A11', fontWeight: 400, fontFamily: 'Inter, sans-serif' }}>
                    {m.name}
                  </td>

                  {/* Đơn Vị Tính (#372:44) */}
                  <td style={{ padding: '14px 15px', color: '#2C1A11', fontWeight: 400, fontFamily: 'Inter, sans-serif' }}>
                    {m.unit}
                  </td>

                  {/* Tồn Tối Thiểu Gợi Ý (#372:46) */}
                  <td style={{ padding: '14px 15px', color: '#2C1A11', fontWeight: 400, fontFamily: 'Inter, sans-serif' }}>
                    {m.suggestedMinThreshold != null ? `${m.suggestedMinThreshold} ${m.unit}` : '—'}
                  </td>

                  {/* Mô Tả / Nhóm (#372:48) */}
                  <td style={{ padding: '14px 15px', color: '#2C1A11', fontWeight: 400, fontFamily: 'Inter, sans-serif' }}>
                    {m.category || '—'}
                  </td>

                  {/* Trạng thái (#372:50) */}
                  <td style={{ padding: '14px 15px' }}>
                    {m.active ? (
                      <span
                        style={{
                          display: 'inline-block',
                          padding: '4px 8px',
                          borderRadius: '6px',
                          background: '#E8F5E9',
                          color: '#2E7D32',
                          fontSize: '12px',
                          fontWeight: 700,
                          fontFamily: 'Inter, sans-serif',
                        }}
                      >
                        Đang dùng
                      </span>
                    ) : (
                      <span
                        style={{
                          display: 'inline-block',
                          padding: '4px 8px',
                          borderRadius: '6px',
                          background: '#FCE4EC',
                          border: '1px solid #F48FB1',
                          color: '#C62828',
                          fontSize: '12px',
                          fontWeight: 700,
                          fontFamily: 'Inter, sans-serif',
                        }}
                      >
                        Ngừng dùng
                      </span>
                    )}
                  </td>

                  {/* Hành động (#372:52) */}
                  <td style={{ padding: '14px 15px' }}>
                    <div style={{ display: 'flex', gap: '14px', alignItems: 'center' }}>
                      <span
                        onClick={() => navigate(`/raw-materials/${m.id}/edit`)}
                        style={{
                          fontSize: '14px',
                          fontWeight: 700,
                          color: '#3D2314',
                          cursor: 'pointer',
                          fontFamily: 'Segoe UI, sans-serif',
                        }}
                      >
                        Sửa
                      </span>
                      {m.active && (
                        <span
                          onClick={() => handleDeactivate(m)}
                          style={{
                            fontSize: '14px',
                            fontWeight: 700,
                            color: '#C62828',
                            cursor: 'pointer',
                            fontFamily: 'Segoe UI, sans-serif',
                          }}
                        >
                          Vô hiệu
                        </span>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
