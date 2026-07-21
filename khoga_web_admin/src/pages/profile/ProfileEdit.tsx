import { useEffect, useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { updateProfile } from '../../api/auth';
import { errorMessage } from '../../api/client';

const PHONE_RE = /^[0-9]{10,12}$/;

/**
 * Screen 07 — "Chỉnh sửa thông tin". Per BR-19 only the contact fields (email,
 * phone) are editable; name/username/role/branch are fixed. On success the
 * AuthContext user is refreshed so the topbar/profile reflect the change.
 */
export default function ProfileEdit() {
  const { user, loading, refreshProfile } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (user) {
      setEmail(user.email ?? '');
      setPhone(user.phone ?? '');
    }
  }, [user]);

  if (loading) return <div className="full-center">Đang tải…</div>;
  if (!user) return null;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (phone && !PHONE_RE.test(phone)) {
      setError('Số điện thoại phải có 10–12 chữ số.');
      return;
    }
    setSubmitting(true);
    try {
      await updateProfile({ email, phone });
      await refreshProfile();
      navigate('/profile');
    } catch (err) {
      setError(errorMessage(err, 'Cập nhật hồ sơ thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Chỉnh Sửa Hồ Sơ Cá Nhân</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <p className="info-note">
          <strong>{user.fullName}</strong> · {user.username}. Bạn chỉ có thể cập nhật thông tin liên hệ.
        </p>

        <div className="field">
          <label className="label" htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            className="input"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="vd: ban@khoga.vn"
            autoComplete="email"
          />
        </div>
        <div className="field">
          <label className="label" htmlFor="phone">Số điện thoại</label>
          <input
            id="phone"
            type="tel"
            className="input"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="vd: 0901234567 (10–12 số)"
            autoComplete="tel"
          />
        </div>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : 'Lưu thay đổi'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/profile')}>
            Hủy bỏ
          </button>
        </div>
      </form>
    </div>
  );
}
