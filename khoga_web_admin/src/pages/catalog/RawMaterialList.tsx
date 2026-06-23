import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { listRawMaterials, deactivateRawMaterial, type RawMaterial } from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function RawMaterialList() {
  const [items, setItems] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const load = () => {
    listRawMaterials()
      .then(setItems)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return items;
    return items.filter((m) => [m.code, m.name, m.category].some((f) => f?.toLowerCase().includes(q)));
  }, [items, search]);

  const deactivate = async (m: RawMaterial) => {
    if (!window.confirm(`Ngừng sử dụng nguyên liệu "${m.name}"?`)) return;
    setError('');
    try { await deactivateRawMaterial(m.id); load(); }
    catch (err) { setError(errorMessage(err)); }
  };

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Nguyên Liệu</h1>
          <p className="page-subtitle">Master nguyên liệu — mã bất biến, đơn vị khóa khi đã dùng (UC-74/BR-63/64).</p>
        </div>
        <Link to="/raw-materials/new" className="btn btn--primary">+ Thêm Nguyên Liệu</Link>
      </div>

      <div className="toolbar">
        <input className="input toolbar__search" placeholder="Tìm theo mã / tên / nhóm…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Mã</th><th>Tên</th><th>Đơn Vị</th><th>Định Mức Tối Thiểu</th><th>Chi Phí Chuẩn</th><th>Nhóm</th><th>Trạng Thái</th><th>Hành Động</th></tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={8} className="table__empty">Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={8} className="table__empty">Chưa có nguyên liệu.</td></tr>
            ) : filtered.map((m) => (
              <tr key={m.id}>
                <td className="muted">{m.code}</td>
                <td style={{ fontWeight: 600 }}>{m.name}</td>
                <td>{m.unit}</td>
                <td>{m.suggestedMinThreshold ?? '—'}</td>
                <td>{m.standardCost != null ? `${m.standardCost.toLocaleString('vi-VN')} đ` : '—'}</td>
                <td>{m.category || '—'}</td>
                <td><span className={`badge ${m.active ? 'badge--active' : 'badge--inactive'}`}>{m.active ? 'Đang dùng' : 'Ngừng'}</span></td>
                <td>
                  <span className="actions-cell">
                    <Link to={`/raw-materials/${m.id}/edit`} className="link-action">Sửa</Link>
                    {m.active && <button className="link-action link-action--danger" onClick={() => deactivate(m)}>Ngừng dùng</button>}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
