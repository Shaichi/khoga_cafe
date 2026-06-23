import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { forcePasswordChange } from '../api/auth';
import { errorMessage } from '../api/client';
import CupIcon from '../components/CupIcon';

const POLICY = 'Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, chữ số và ký tự đặc biệt.';

export default function ForcePasswordChange() {
  const { completePasswordChange, logout } = useAuth();
  const navigate = useNavigate();
  const [newPassword, setNewPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (newPassword !== confirm) {
      setError('Mật khẩu xác nhận không khớp.');
      return;
    }
    setSubmitting(true);
    try {
      await forcePasswordChange(newPassword);
      completePasswordChange();
      navigate('/', { replace: true });
    } catch (err) {
      setError(errorMessage(err, 'Đổi mật khẩu thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth-form-side auth-form-side--center">
      <form className="auth-form auth-form--card" onSubmit={handleSubmit}>
        <div className="auth-form__mark">
          <CupIcon size={34} stroke="#3d2314" />
        </div>
        <h2 className="auth-form__title">Đổi mật khẩu lần đầu</h2>
        <p className="auth-form__subtitle">
          Vì lý do bảo mật, bạn phải đặt mật khẩu mới trước khi sử dụng hệ thống.
        </p>

        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label" htmlFor="newPassword">Mật khẩu mới</label>
          <input
            id="newPassword"
            type="password"
            className="input"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            autoComplete="new-password"
            autoFocus
            required
          />
        </div>

        <div className="field">
          <label className="label" htmlFor="confirm">Xác nhận mật khẩu</label>
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

        <button type="submit" className="btn btn--primary btn--block" disabled={submitting}>
          {submitting ? 'ĐANG LƯU…' : 'LƯU MẬT KHẨU'}
        </button>
        <button type="button" className="link-button" onClick={() => logout()}>
          Đăng xuất
        </button>
      </form>
    </div>
  );
}
