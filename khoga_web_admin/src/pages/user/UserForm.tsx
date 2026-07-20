import { useEffect, useState, type FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { createUser, getUser, updateUser } from '../../api/users';
import { listBranches, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';
import { ROLE_LABELS, type Role } from '../../api/types';

const ROLES = Object.keys(ROLE_LABELS) as Role[];
const DEFAULT_PASSWORD = '12345678';

/** Auto-generate username from full name (Vietnamese slug). */
function generateUsername(fullName: string): string {
  if (!fullName.trim()) return '';
  const parts = fullName.trim().toLowerCase().split(/\s+/);
  // Last word as base, initials from preceding words
  const last = parts[parts.length - 1];
  const initials = parts.slice(0, -1).map((w) => w.charAt(0)).join('');
  return (last + initials)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]/g, '');
}

const fieldInput = {
  width: '100%',
  height: '42px',
  padding: '10px 14px',
  background: '#FFFFFF',
  border: '1px solid #E5DBCF',
  borderRadius: '8px',
  fontSize: '15px',
  color: '#000000',
  fontFamily: 'Inter, sans-serif',
  outline: 'none',
} as const;

const fieldDisabled = {
  ...fieldInput,
  background: '#F7F7F7',
  color: '#555555',
  cursor: 'not-allowed',
} as const;

const labelStyle = {
  fontSize: '16px',
  fontWeight: 600,
  color: '#5C3826',
  fontFamily: 'Roboto, sans-serif',
  marginBottom: '7px',
  display: 'block',
} as const;

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

  // Auto-generate username when fullName changes (create mode only)
  const handleFullNameChange = (val: string) => {
    setFullName(val);
    if (!isEdit) setUsername(generateUsername(val));
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!role) { setError('Vui lòng chọn vai trò.'); return; }
    setSubmitting(true);
    try {
      if (isEdit && id) {
        await updateUser(id, { fullName, role, storeId: storeId || null, email, phone });
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

  if (loading) return <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C' }}>Đang tải…</div>;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header */}
      <div style={{ borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#2C1A11', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
          {isEdit ? 'Chỉnh Sửa Tài Khoản' : 'Thêm Tài Khoản Nhân Viên'}
        </h1>
      </div>

      {error && <div className="alert alert--error" style={{ maxWidth: '662px' }}>{error}</div>}

      {/* Form Card */}
      <form
        onSubmit={handleSubmit}
        style={{
          width: '662px',
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '31px',
          boxShadow: '0px 4px 6px 0px rgba(0, 0, 0, 0.02)',
          display: 'flex',
          flexDirection: 'column',
          gap: '20px',
        }}
      >
        {/* Full Name */}
        <div>
          <label style={labelStyle}>Họ và tên</label>
          <input
            aria-label="Họ và tên"
            style={fieldInput}
            value={fullName}
            onChange={(e) => handleFullNameChange(e.target.value)}
            placeholder="Nhập họ và tên"
            required
          />
        </div>

        {/* Username — auto-generated (always show) */}
        <div>
          <label style={labelStyle}>Tên đăng nhập (Tự động tạo)</label>
          <input
            aria-label="Tên đăng nhập"
            style={fieldDisabled}
            value={username || (isEdit ? '' : 'Tự động tạo từ họ tên...')}
            readOnly
            tabIndex={-1}
          />
        </div>

        {/* Temp Password — fixed, read-only on create */}
        {!isEdit && (
          <div>
            <label style={labelStyle}>Mật khẩu</label>
            <input
              aria-label="Mật khẩu tạm thời"
              style={fieldDisabled}
              value={DEFAULT_PASSWORD}
              readOnly
              tabIndex={-1}
            />
          </div>
        )}

        {/* Email */}
        <div>
          <label style={labelStyle}>Email liên hệ</label>
          <input
            aria-label="Email liên hệ"
            type="email"
            style={fieldInput}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="example@khogacafe.com"
            required={!isEdit}
          />
        </div>

        {/* Phone */}
        <div>
          <label style={labelStyle}>Số điện thoại</label>
          <input
            aria-label="Số điện thoại"
            style={fieldInput}
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="Nhập số điện thoại"
          />
        </div>

        {/* Role */}
        <div>
          <label style={labelStyle}>Vai trò</label>
          <select
            aria-label="Vai trò"
            style={{ ...fieldInput, background: '#EFEFEF', cursor: 'pointer' }}
            value={role}
            onChange={(e) => setRole(e.target.value as Role)}
            required
          >
            <option value="">-- Chọn vai trò --</option>
            {ROLES.map((r) => <option key={r} value={r}>{ROLE_LABELS[r]}</option>)}
          </select>
        </div>

        {/* Branch */}
        <div>
          <label style={labelStyle}>Chi nhánh</label>
          <select
            aria-label="Chi nhánh"
            style={{ ...fieldInput, background: '#EFEFEF', cursor: 'pointer' }}
            value={storeId}
            onChange={(e) => setStoreId(e.target.value)}
          >
            <option value="">— Không (HQ) —</option>
            {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>

        {/* Actions */}
        <div style={{ display: 'flex', gap: '12px', marginTop: '10px' }}>
          <button
            type="submit"
            disabled={submitting}
            style={{
              width: '153.89px',
              height: '41px',
              background: '#3D2314',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 700,
              fontFamily: 'Inter, sans-serif',
              letterSpacing: '0.5px',
              cursor: submitting ? 'not-allowed' : 'pointer',
              opacity: submitting ? 0.7 : 1,
            }}
          >
            {submitting ? 'ĐANG LƯU…' : (isEdit ? 'LƯU THAY ĐỔI' : 'TẠO TÀI KHOẢN')}
          </button>
          <button
            type="button"
            onClick={() => navigate('/users')}
            style={{
              width: '101.61px',
              height: '41px',
              background: 'transparent',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              color: '#8C766C',
              fontSize: '13px',
              fontFamily: 'Inter, sans-serif',
              cursor: 'pointer',
            }}
          >
            HỦY BỎ
          </button>
        </div>
      </form>
    </div>
  );
}
