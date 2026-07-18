import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { errorMessage } from '../api/client';
import { forgotPassword, verifyOtp, resetPassword } from '../api/auth';
import CupIcon from '../components/CupIcon';

type AuthStep = 'login' | 'forgot' | 'verify' | 'reset';

export default function Login() {
  const { user, loading, mustChangePassword, login } = useAuth();
  const navigate = useNavigate();

  // Form states
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // UI state
  const [step, setStep] = useState<AuthStep>('login');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Already signed in → bounce to the right place.
  if (!loading && user) {
    return <Navigate to={mustChangePassword ? '/force-password-change' : '/'} replace />;
  }

  const handleLoginSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
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

  const handleForgotSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      await forgotPassword(email.trim());
      setSuccess('Mã OTP khôi phục mật khẩu đã được gửi đến email của bạn.');
      setStep('verify');
    } catch (err) {
      setError(errorMessage(err, 'Không thể gửi yêu cầu đặt lại mật khẩu'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleVerifyOtpSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      await verifyOtp(email.trim(), otp.trim());
      setSuccess('Mã OTP hợp lệ. Vui lòng nhập mật khẩu mới.');
      setStep('reset');
    } catch (err) {
      setError(errorMessage(err, 'Xác thực OTP thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleResetPasswordSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    if (newPassword !== confirmPassword) {
      setError('Mật khẩu xác nhận không khớp');
      return;
    }
    setSubmitting(true);
    try {
      await resetPassword(email.trim(), otp.trim(), newPassword);
      setSuccess('Đặt lại mật khẩu thành công. Vui lòng đăng nhập với mật khẩu mới.');
      setStep('login');
      // Clear sensitive states
      setPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setOtp('');
    } catch (err) {
      setError(errorMessage(err, 'Đổi mật khẩu thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  const resetFlow = () => {
    setStep('login');
    setError('');
    setSuccess('');
    setSubmitting(false);
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
        {step === 'login' && (
          <form className="auth-form" onSubmit={handleLoginSubmit}>
            <h2 className="auth-form__title">Đăng Nhập Quản Trị</h2>
            <p className="auth-form__subtitle">Nhập tài khoản quản trị HQ để tiếp tục.</p>

            {error && <div className="alert alert--error">{error}</div>}
            {success && <div className="alert alert--success">{success}</div>}

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

            <button type="button" className="link-button" onClick={() => { setStep('forgot'); setError(''); setSuccess(''); }}>
              Quên mật khẩu quản trị?
            </button>
          </form>
        )}

        {step === 'forgot' && (
          <form className="auth-form" onSubmit={handleForgotSubmit}>
            <h2 className="auth-form__title">Quên Mật Khẩu</h2>
            <p className="auth-form__subtitle">Nhập email đã đăng ký để nhận mã xác thực OTP.</p>

            {error && <div className="alert alert--error">{error}</div>}

            <div className="field">
              <label className="label" htmlFor="email">Email đăng ký</label>
              <input
                id="email"
                type="email"
                className="input"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Nhập email của bạn"
                autoComplete="email"
                autoFocus
                required
              />
            </div>

            <button type="submit" className="btn btn--primary btn--block" disabled={submitting}>
              {submitting ? 'ĐANG GỬI…' : 'GỬI MÃ OTP'}
            </button>

            <button type="button" className="btn btn--ghost btn--block" style={{ marginTop: '1rem' }} onClick={resetFlow}>
              Quay lại Đăng nhập
            </button>
          </form>
        )}

        {step === 'verify' && (
          <form className="auth-form" onSubmit={handleVerifyOtpSubmit}>
            <h2 className="auth-form__title">Xác Thực OTP</h2>
            <p className="auth-form__subtitle">Mã xác thực đã được gửi qua email. Vui lòng nhập mã tại đây.</p>

            {error && <div className="alert alert--error">{error}</div>}
            {success && <div className="alert alert--success">{success}</div>}

            <div className="field">
              <label className="label" htmlFor="otp">Mã OTP</label>
              <input
                id="otp"
                className="input"
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                placeholder="Nhập mã OTP"
                autoFocus
                required
              />
            </div>

            <button type="submit" className="btn btn--primary btn--block" disabled={submitting}>
              {submitting ? 'ĐANG XÁC THỰC…' : 'XÁC THỰC MÃ OTP'}
            </button>

            <button type="button" className="btn btn--ghost btn--block" style={{ marginTop: '1rem' }} onClick={resetFlow}>
              Quay lại Đăng nhập
            </button>
          </form>
        )}

        {step === 'reset' && (
          <form className="auth-form" onSubmit={handleResetPasswordSubmit}>
            <h2 className="auth-form__title">Đặt Lại Mật Khẩu</h2>
            <p className="auth-form__subtitle">Thiết lập mật khẩu mới đáp ứng các yêu cầu bảo mật của hệ thống.</p>

            {error && <div className="alert alert--error">{error}</div>}
            {success && <div className="alert alert--success">{success}</div>}

            <div className="field">
              <label className="label" htmlFor="newPassword">Mật khẩu mới</label>
              <input
                id="newPassword"
                type="password"
                className="input"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Nhập mật khẩu mới"
                autoFocus
                required
              />
              {newPassword.length > 0 && (
                <ul style={{ fontSize: '0.85rem', marginTop: '0.5rem', listStyle: 'none', paddingLeft: 0, lineHeight: 1.5 }}>
                  <li style={{ color: newPassword.length >= 8 ? 'green' : '#666' }}>
                    {newPassword.length >= 8 ? '✓' : '○'} Dài ít nhất 8 ký tự
                  </li>
                  <li style={{ color: /[A-Z]/.test(newPassword) ? 'green' : '#666' }}>
                    {/[A-Z]/.test(newPassword) ? '✓' : '○'} Có ít nhất một chữ hoa (A-Z)
                  </li>
                  <li style={{ color: /[a-z]/.test(newPassword) ? 'green' : '#666' }}>
                    {/[a-z]/.test(newPassword) ? '✓' : '○'} Có ít nhất một chữ thường (a-z)
                  </li>
                  <li style={{ color: /[0-9]/.test(newPassword) ? 'green' : '#666' }}>
                    {/[0-9]/.test(newPassword) ? '✓' : '○'} Có ít nhất một số (0-9)
                  </li>
                  <li style={{ color: /[^A-Za-z0-9]/.test(newPassword) ? 'green' : '#666' }}>
                    {/[^A-Za-z0-9]/.test(newPassword) ? '✓' : '○'} Có ít nhất một ký tự đặc biệt
                  </li>
                </ul>
              )}
            </div>

            <div className="field">
              <label className="label" htmlFor="confirmPassword">Xác nhận mật khẩu mới</label>
              <input
                id="confirmPassword"
                type="password"
                className="input"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Xác nhận mật khẩu mới"
                required
              />
            </div>

            <button type="submit" className="btn btn--primary btn--block" disabled={submitting}>
              {submitting ? 'ĐANG ĐỔI MẬT KHẨU…' : 'LƯU MẬT KHẨU MỚI'}
            </button>

            <button type="button" className="btn btn--ghost btn--block" style={{ marginTop: '1rem' }} onClick={resetFlow}>
              Quay lại Đăng nhập
            </button>
          </form>
        )}
      </main>
    </div>
  );
}

