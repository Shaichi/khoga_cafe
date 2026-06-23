import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { errorMessage } from '../api/client';
import CupIcon from '../components/CupIcon';

export default function Login() {
  const { user, loading, mustChangePassword, login } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Already signed in → bounce to the right place.
  if (!loading && user) {
    return <Navigate to={mustChangePassword ? '/force-password-change' : '/'} replace />;
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      await login(username.trim(), password);
      navigate('/', { replace: true });
    } catch (err) {
      setError(errorMessage(err, 'Đăng nhập thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth-split">
      <aside className="auth-brand">
        <div className="auth-brand__inner">
          <div className="auth-brand__badge">
            <CupIcon size={52} stroke="#ffffff" />
          </div>
          <h1 className="auth-brand__title">
            Khoga<span>Café</span>
          </h1>
          <p className="auth-brand__subtitle">
            Hệ thống quản lý chuỗi cửa hàng cà phê thông minh dành cho quản trị viên trung tâm.
          </p>
        </div>
      </aside>

      <main className="auth-form-side">
        <form className="auth-form" onSubmit={handleSubmit}>
          <h2 className="auth-form__title">Đăng Nhập Quản Trị</h2>
          <p className="auth-form__subtitle">Nhập tài khoản quản trị HQ để tiếp tục.</p>

          {error && <div className="alert alert--error">{error}</div>}

          <div className="field">
            <label className="label" htmlFor="username">Tên đăng nhập</label>
            <input
              id="username"
              className="input"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="vd: ssadmin"
              autoComplete="username"
              autoFocus
              required
            />
          </div>

          <div className="field">
            <label className="label" htmlFor="password">Mật khẩu</label>
            <input
              id="password"
              type="password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nhập mật khẩu"
              autoComplete="current-password"
              required
            />
          </div>

          <button type="submit" className="btn btn--primary btn--block" disabled={submitting}>
            {submitting ? 'ĐANG XỬ LÝ…' : 'ĐĂNG NHẬP'}
          </button>

          <button type="button" className="link-button" disabled>
            Quên mật khẩu quản trị?
          </button>
        </form>
      </main>
    </div>
  );
}
