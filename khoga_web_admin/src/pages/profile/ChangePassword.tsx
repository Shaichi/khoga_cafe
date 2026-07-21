import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { changePassword } from '../../api/auth';
import { errorMessage } from '../../api/client';

const POLICY = 'Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, chữ số và ký tự đặc biệt.';

/**
 * Screen 08 — "Đổi Mật Khẩu" (UC-09). Logged-in self-service change. The new
 * password must match its confirmation before we call the backend, which also
 * re-validates the current password and the strength policy (BR).
 */
export default function ChangePassword() {
  const navigate = useNavigate();
  const [current, setCurrent] = useState('');
  const [next, setNext] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (next !== confirm) {
      setError('Mật khẩu xác nhận không khớp.');
      return;
    }
    setSubmitting(true);
    try {
      await changePassword(current, next);
      navigate('/profile');
    } catch (err) {
      setError(errorMessage(err, 'Đổi mật khẩu thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Đổi mật khẩu</h1>
        <p className="page-subtitle">Thay đổi mật khẩu tài khoản đang hoạt động của bạn.</p>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label" htmlFor="current">Mật khẩu hiện tại</label>
          <input
            id="current"
            type="password"
            className="input"
            value={current}
            onChange={(e) => setCurrent(e.target.value)}
            autoComplete="current-password"
            required
          />
        </div>
        <div className="field">
          <label className="label" htmlFor="new">Mật khẩu mới</label>
          <input
            id="new"
            type="password"
            className="input"
            value={next}
            onChange={(e) => setNext(e.target.value)}
            autoComplete="new-password"
            required
          />
        </div>
        <div className="field">
          <label className="label" htmlFor="confirm">Xác nhận mật khẩu mới</label>
          <input
            id="confirm"
            type="password"
            className="input"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            autoComplete="new-password"
            required
          />
        </div>

        <p className="hint">{POLICY}</p>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : 'Cập nhật mật khẩu'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/profile')}>
            Hủy bỏ
          </button>
        </div>
      </form>
    </div>
  );
}
