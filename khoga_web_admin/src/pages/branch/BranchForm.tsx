import { useEffect, useState, type ChangeEvent, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  createBranch,
  getBranch,
  updateBranch,
  deactivateBranch,
  type BranchInput,
} from '../../api/branches';
import { errorMessage } from '../../api/client';

const PHONE_RE = /^[0-9]{10,12}$/;

export default function BranchForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [form, setForm] = useState<BranchInput>({ name: '', address: '', phone: '' });
  const [active, setActive] = useState(true);
  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    getBranch(id)
      .then((b) => {
        setForm({ name: b.name, address: b.address, phone: b.phone });
        setActive(b.active);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const set = (key: keyof BranchInput) => (e: ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [key]: e.target.value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!PHONE_RE.test(form.phone)) {
      setError('Số điện thoại phải có 10–12 chữ số.');
      return;
    }
    setSubmitting(true);
    try {
      if (isEdit && id) await updateBranch(id, form);
      else await createBranch(form);
      navigate('/branches');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeactivate = async () => {
    if (!id) return;
    if (!window.confirm('Vô hiệu hóa chi nhánh này? Tài khoản nhân sự của chi nhánh sẽ bị khóa và lịch làm việc tương lai bị xóa.')) {
      return;
    }
    setError('');
    try {
      await deactivateBranch(id);
      navigate('/branches');
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  if (loading) return <div className="full-center">Đang tải…</div>;

  return (
    <div>
      <div className="page-head">
        <Link to="/branches" className="back-link">← Danh sách chi nhánh</Link>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Chi Nhánh' : 'Thêm Chi Nhánh Mới'}</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label">Tên Chi Nhánh *</label>
          <input className="input" value={form.name} onChange={set('name')} placeholder="Ví dụ: Khoga Café - Bình Thạnh" required />
        </div>
        <div className="field">
          <label className="label">Địa Chỉ *</label>
          <input className="input" value={form.address} onChange={set('address')} placeholder="Ví dụ: 200 Điện Biên Phủ, P.17, Q. Bình Thạnh" required />
        </div>
        <div className="field">
          <label className="label">Số Điện Thoại Liên Hệ *</label>
          <input className="input" value={form.phone} onChange={set('phone')} placeholder="Ví dụ: 0283930005 (10–12 số)" required />
        </div>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : 'Lưu Chi Nhánh'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/branches')}>
            Hủy bỏ
          </button>
          {isEdit && (
            <Link to={`/branches/${id}/settings`} className="btn btn--ghost">
              Cấu hình vận hành
            </Link>
          )}
          {isEdit && active && (
            <button type="button" className="btn btn--danger" style={{ marginLeft: 'auto' }} onClick={handleDeactivate}>
              Vô hiệu hóa
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
