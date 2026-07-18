import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  createRawMaterial,
  getRawMaterial,
  updateRawMaterial,
  type CreateRawMaterialInput,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

const numOrNull = (s: string): number | null => (s.trim() === '' ? null : Number(s));

export default function RawMaterialForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [unit, setUnit] = useState('');
  const [threshold, setThreshold] = useState('');
  const [cost, setCost] = useState('');
  const [category, setCategory] = useState('');
  const [active, setActive] = useState(true);
  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    getRawMaterial(id)
      .then((m) => {
        setCode(m.code);
        setName(m.name);
        setUnit(m.unit);
        setThreshold(m.suggestedMinThreshold?.toString() ?? '');
        setCost(m.standardCost?.toString() ?? '');
        setCategory(m.category ?? '');
        setActive(m.active);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      if (isEdit && id) {
        await updateRawMaterial(id, {
          name, unit, suggestedMinThreshold: numOrNull(threshold), standardCost: numOrNull(cost), category, active,
        });
      } else {
        const input: CreateRawMaterialInput = {
          code, name, unit, suggestedMinThreshold: numOrNull(threshold), standardCost: numOrNull(cost), category,
        };
        await createRawMaterial(input);
      }
      navigate('/raw-materials');
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
        <Link to="/raw-materials" className="back-link">← Nguyên liệu</Link>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Nguyên Liệu' : 'Thêm Nguyên Liệu'}</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label">Mã nguyên liệu *</label>
          <input className="input" value={code} onChange={(e) => setCode(e.target.value)} placeholder="VD: RM-MILK" required disabled={isEdit} />
          {isEdit && <p className="hint">Mã nguyên liệu là bất biến.</p>}
        </div>
        <div className="field">
          <label className="label">Tên nguyên liệu *</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="VD: Sữa tươi" required />
        </div>
        <div className="field">
          <label className="label">Đơn vị *</label>
          <input className="input" value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="VD: ml, g, cái" required />
          <p className="hint">Đơn vị bị khóa khi nguyên liệu đã có giao dịch/công thức.</p>
        </div>
        <div className="field">
          <label className="label">Định mức tồn tối thiểu</label>
          <input className="input" type="number" step="any" min="0" value={threshold} onChange={(e) => setThreshold(e.target.value)} placeholder="VD: 1000" />
        </div>
        <div className="field">
          <label className="label">Chi phí chuẩn (VND/đơn vị)</label>
          <input className="input" type="number" step="any" min="0" value={cost} onChange={(e) => setCost(e.target.value)} placeholder="VD: 25" />
        </div>
        <div className="field">
          <label className="label">Nhóm</label>
          <input className="input" value={category} onChange={(e) => setCategory(e.target.value)} placeholder="VD: Sữa & kem" />
        </div>
        {isEdit && (
          <label className="checkbox-row">
            <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} />
            <span>Đang sử dụng</span>
          </label>
        )}

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>{submitting ? 'Đang lưu…' : 'Lưu Nguyên Liệu'}</button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/raw-materials')}>Hủy bỏ</button>
        </div>
      </form>
    </div>
  );
}
