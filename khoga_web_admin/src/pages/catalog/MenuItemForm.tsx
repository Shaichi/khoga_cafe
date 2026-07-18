import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  createMenuItem,
  getMenuItem,
  updateMenuItem,
  listCategories,
  listRawMaterials,
  type Category,
  type RawMaterial,
  type MenuItemInput,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

interface LineState {
  rawMaterialId: string;
  quantity: string;
  unit: string;
}

export default function MenuItemForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [name, setName] = useState('');
  const [price, setPrice] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [barcode, setBarcode] = useState('');
  const [description, setDescription] = useState('');
  const [recipe, setRecipe] = useState<LineState[]>([]);

  const [categories, setCategories] = useState<Category[]>([]);
  const [materials, setMaterials] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    Promise.all([
      listCategories(true).catch(() => []),
      listRawMaterials().catch(() => []),
      id ? getMenuItem(id) : Promise.resolve(null),
    ])
      .then(([cats, mats, item]) => {
        setCategories(cats);
        setMaterials(mats.filter((m) => m.active));
        if (item) {
          setName(item.name);
          setPrice(item.price.toString());
          setCategoryId(item.categoryId ?? '');
          setBarcode(item.barcode ?? '');
          setDescription(item.description ?? '');
          setRecipe(item.recipe.map((r) => ({ rawMaterialId: r.rawMaterialId, quantity: r.quantity.toString(), unit: r.unit })));
        }
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const addLine = () => setRecipe((r) => [...r, { rawMaterialId: '', quantity: '', unit: '' }]);
  const removeLine = (i: number) => setRecipe((r) => r.filter((_, idx) => idx !== i));
  const updateLine = (i: number, patch: Partial<LineState>) =>
    setRecipe((r) => r.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));

  // BR-73: a recipe line's unit must equal the material's master unit — auto-fill on pick.
  const pickMaterial = (i: number, rawMaterialId: string) => {
    const mat = materials.find((m) => m.id === rawMaterialId);
    updateLine(i, { rawMaterialId, unit: mat?.unit ?? '' });
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    const lines = recipe.filter((l) => l.rawMaterialId && l.quantity.trim() !== '');
    const input: MenuItemInput = {
      name,
      price: Number(price),
      description: description || undefined,
      categoryId: categoryId || null,
      barcode: barcode || undefined,
      recipe: lines.map((l) => ({ rawMaterialId: l.rawMaterialId, quantity: Number(l.quantity), unit: l.unit })),
    };
    setSubmitting(true);
    try {
      if (isEdit && id) await updateMenuItem(id, input);
      else await createMenuItem(input);
      navigate('/catalog');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="full-center">Đang tải…</div>;

  return (
    <div>
      <div className="page-head">
        <Link to="/catalog" className="back-link">← Thực đơn</Link>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Món' : 'Thêm Món Mới'}</h1>
      </div>

      <form className="form-card form-card--wide" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label">Tên món *</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="VD: Cà phê sữa" required />
        </div>
        <div className="form-row">
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Danh mục</label>
            <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">— Chưa phân loại</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Giá bán (VND) *</label>
            <input className="input" type="number" step="any" min="0" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="VD: 29000" required />
          </div>
        </div>
        <div className="field">
          <label className="label">Barcode</label>
          <input className="input" value={barcode} onChange={(e) => setBarcode(e.target.value)} placeholder="Mã vạch (tùy chọn)" />
        </div>
        <div className="field">
          <label className="label">Mô tả</label>
          <input className="input" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Mô tả ngắn (tùy chọn)" />
        </div>

        <div>
          <div className="recipe-head">
            <label className="label">Công thức (định lượng nguyên liệu)</label>
            <button type="button" className="btn btn--ghost btn--sm" onClick={addLine}>+ Thêm nguyên liệu</button>
          </div>
          {recipe.length === 0 && <p className="hint">Chưa có dòng công thức. Đơn vị tự khớp với nguyên liệu.</p>}
          {recipe.map((line, i) => (
            <div className="recipe-line" key={i}>
              <select className="input" value={line.rawMaterialId} onChange={(e) => pickMaterial(i, e.target.value)}>
                <option value="">— Chọn nguyên liệu</option>
                {materials.map((m) => <option key={m.id} value={m.id}>{m.name} ({m.unit})</option>)}
              </select>
              <input className="input recipe-line__qty" type="number" step="any" min="0" value={line.quantity}
                onChange={(e) => updateLine(i, { quantity: e.target.value })} placeholder="Số lượng" />
              <span className="recipe-line__unit">{line.unit || '—'}</span>
              <button type="button" className="link-action link-action--danger" onClick={() => removeLine(i)}>Xóa</button>
            </div>
          ))}
        </div>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>{submitting ? 'Đang lưu…' : 'Lưu Món'}</button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/catalog')}>Hủy bỏ</button>
        </div>
      </form>
    </div>
  );
}
