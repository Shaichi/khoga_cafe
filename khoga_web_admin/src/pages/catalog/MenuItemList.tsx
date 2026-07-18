import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { listMenuItems, listCategories, deleteMenuItem, type MenuItem, type Category } from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function MenuItemList() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState('');

  const load = () => {
    Promise.all([listMenuItems(), listCategories().catch(() => [])])
      .then(([m, c]) => { setItems(m.filter((i) => !i.deleted)); setCategories(c); })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return items.filter((m) => {
      if (categoryId && m.categoryId !== categoryId) return false;
      if (!q) return true;
      return [m.name, m.abbreviation, m.barcode].some((f) => f?.toLowerCase().includes(q));
    });
  }, [items, search, categoryId]);

  const remove = async (m: MenuItem) => {
    if (!window.confirm(`Xóa món "${m.name}"? (ẩn khỏi danh mục, giữ lịch sử bán)`)) return;
    setError('');
    try { await deleteMenuItem(m.id); load(); }
    catch (err) { setError(errorMessage(err)); }
  };

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Thực Đơn</h1>
          <p className="page-subtitle">Quản lý món & công thức.</p>
        </div>
        <div className="actions-cell">
          <Link to="/catalog/categories" className="btn btn--ghost">Quản lý danh mục</Link>
          <Link to="/catalog/new" className="btn btn--primary">+ Thêm Món</Link>
        </div>
      </div>

      <div className="toolbar">
        <input className="input toolbar__search" placeholder="Tìm theo tên / viết tắt / barcode…" value={search} onChange={(e) => setSearch(e.target.value)} />
        <select className="input toolbar__select" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
          <option value="">Tất cả danh mục</option>
          {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Tên Món</th><th>Danh Mục</th><th>Giá</th><th>Viết Tắt</th><th>Barcode</th><th>Trạng Thái</th><th>Hành Động</th></tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} className="table__empty">Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={7} className="table__empty">Chưa có món nào.</td></tr>
            ) : filtered.map((m) => (
              <tr key={m.id}>
                <td style={{ fontWeight: 600 }}>{m.name}</td>
                <td>{m.categoryName || '—'}</td>
                <td>{m.price.toLocaleString('vi-VN')} đ</td>
                <td className="muted">{m.abbreviation}</td>
                <td className="muted">{m.barcode || '—'}</td>
                <td><span className={`badge ${m.active ? 'badge--active' : 'badge--inactive'}`}>{m.active ? 'Đang bán' : 'Ngừng bán'}</span></td>
                <td>
                  <span className="actions-cell">
                    <Link to={`/catalog/${m.id}/edit`} className="link-action">Sửa</Link>
                    <button className="link-action link-action--danger" onClick={() => remove(m)}>Xóa</button>
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
