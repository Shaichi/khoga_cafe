import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { createUser, getUser, updateUser } from '../../api/users';
import { listBranches, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';
import { ROLE_LABELS, type Role } from '../../api/types';

const ROLES = Object.keys(ROLE_LABELS) as Role[];

export default function UserForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [role, setRole] = useState<Role | ''>('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [storeId, setStoreId] = useState('');
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    listBranches().then(setBranches).catch(() => setBranches([]));
  }, []);

  useEffect(() => {
    if (!id) return;
    getUser(id)
      .then((u) => {
        setFullName(u.fullName);
        setUsername(u.username);
        setRole(u.role);
        setEmail(u.email ?? '');
        setPhone(u.phone ?? '');
        setStoreId(u.storeId ?? '');
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!role) { setError('Vui lòng chọn vai trò.'); return; }
    setSubmitting(true);
    try {
      if (isEdit && id) {
        await updateUser(id, { role, storeId: storeId || null, email, phone });
      } else {
        await createUser({ fullName, role, email, phone: phone || undefined, storeId: storeId || null });
      }
      navigate('/users');
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
        <Link to="/users" className="back-link">← Danh sách nhân sự</Link>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Tài Khoản' : 'Thêm Tài Khoản Nhân Viên'}</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label">Họ và tên *</label>
          <input className="input" value={fullName} onChange={(e) => setFullName(e.target.value)}
            placeholder="Nhập họ và tên" required disabled={isEdit} />
        </div>

        {isEdit && (
          <div className="field">
            <label className="label">Tên đăng nhập</label>
            <input className="input" value={username} disabled />
          </div>
        )}

        <div className="field">
          <label className="label">Vai trò *</label>
          <select className="input" value={role} onChange={(e) => setRole(e.target.value as Role)} required>
            <option value="">-- Chọn vai trò --</option>
            {ROLES.map((r) => <option key={r} value={r}>{ROLE_LABELS[r]}</option>)}
          </select>
        </div>

        <div className="field">
          <label className="label">Chi nhánh</label>
          <select className="input" value={storeId} onChange={(e) => setStoreId(e.target.value)}>
            <option value="">— Không (HQ)</option>
            {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>

        <div className="field">
          <label className="label">Email liên hệ *</label>
          <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)}
            placeholder="example@khogacafe.com" required />
        </div>

        <div className="field">
          <label className="label">Số điện thoại</label>
          <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="10–12 số" />
        </div>

        {!isEdit && (
          <p className="info-note">
            Hệ thống sẽ tự sinh <strong>tên đăng nhập</strong> và <strong>mật khẩu tạm thời</strong>, gửi qua email cho nhân viên (đổi ở lần đăng nhập đầu).
          </p>
        )}

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : isEdit ? 'Lưu thay đổi' : 'Tạo tài khoản'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/users')}>Hủy bỏ</button>
        </div>
      </form>
    </div>
  );
}
