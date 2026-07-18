import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import {
  listCategories,
  createCategory,
  updateCategory,
  archiveCategory,
  type Category,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function CategoryList() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingId, setEditingId] = useState<string | 'new' | null>(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);

  const load = () => {
    listCategories()
      .then(setCategories)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const startCreate = () => { setEditingId('new'); setName(''); setDescription(''); setError(''); };
  const startEdit = (c: Category) => { setEditingId(c.id); setName(c.name); setDescription(c.description ?? ''); setError(''); };
  const cancel = () => { setEditingId(null); };

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSaving(true);
    try {
      if (editingId === 'new') await createCategory({ name, description });
      else if (editingId) await updateCategory(editingId, { name, description });
      setEditingId(null);
      load();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const archive = async (c: Category) => {
    if (!window.confirm(`Lưu trữ danh mục "${c.name}"?`)) return;
    setError('');
    try {
      await archiveCategory(c.id);
      load();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <Link to="/catalog" className="back-link">← Thực đơn</Link>
          <h1 className="page-title">Quản Lý Danh Mục</h1>
          <p className="page-subtitle">Nhóm món trong thực đơn.</p>
        </div>
        {editingId === null && (
          <button className="btn btn--primary" onClick={startCreate}>+ Thêm Danh Mục</button>
        )}
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {editingId !== null && (
        <form className="form-card" onSubmit={save} style={{ marginBottom: 20 }}>
          <h2 className="section-title" style={{ marginTop: 0 }}>{editingId === 'new' ? 'Thêm danh mục' : 'Chỉnh sửa danh mục'}</h2>
          <div className="field">
            <label className="label">Tên danh mục *</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="VD: Cà phê" required />
          </div>
          <div className="field">
            <label className="label">Mô tả</label>
            <input className="input" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Mô tả ngắn (tùy chọn)" />
          </div>
          <div className="form-actions">
            <button type="submit" className="btn btn--primary" disabled={saving}>{saving ? 'Đang lưu…' : 'Lưu'}</button>
            <button type="button" className="btn btn--ghost" onClick={cancel}>Hủy</button>
          </div>
        </form>
      )}

      <div className="table-wrap">
        <table className="table">
          <thead><tr><th>Tên Danh Mục</th><th>Mô Tả</th><th>Trạng Thái</th><th>Hành Động</th></tr></thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} className="table__empty">Đang tải…</td></tr>
            ) : categories.length === 0 ? (
              <tr><td colSpan={4} className="table__empty">Chưa có danh mục.</td></tr>
            ) : categories.map((c) => (
              <tr key={c.id}>
                <td style={{ fontWeight: 600 }}>{c.name}</td>
                <td className="muted">{c.description || '—'}</td>
                <td><span className={`badge ${c.active ? 'badge--active' : 'badge--inactive'}`}>{c.active ? 'Hoạt động' : 'Đã lưu trữ'}</span></td>
                <td>
                  <span className="actions-cell">
                    <button className="link-action" onClick={() => startEdit(c)}>Sửa</button>
                    {c.active && <button className="link-action link-action--danger" onClick={() => archive(c)}>Lưu trữ</button>}
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
