import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext';
import type { Role } from '../api/types';

/** Chỉ 3 role này được vào web admin portal. */
const ADMIN_ROLES: Role[] = ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN'];

/** Gate for authenticated areas. Also enforces admin-only portal access (BR-XX) and first-login password change (BR-12). */
export default function ProtectedRoute() {
  const { user, loading, mustChangePassword, logout } = useAuth();
  const location = useLocation();

  if (loading) {
    return <div className="full-center">Đang tải…</div>;
  }

  if (!user) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  // Chặn CASHIER / BARISTA / STORE_MANAGER — không có quyền dùng web admin
  if (!ADMIN_ROLES.includes(user.role)) {
    return (
      <div className="full-center" style={{ flexDirection: 'column', gap: '12px', fontFamily: 'Inter, sans-serif' }}>
        <div style={{
          background: '#FDE8E8', border: '1px solid #F5C6C6', borderRadius: '10px',
          padding: '28px 36px', textAlign: 'center', maxWidth: '420px',
        }}>
          <div style={{ fontSize: '32px', marginBottom: '8px' }}>🚫</div>
          <h2 style={{ margin: '0 0 8px', fontSize: '18px', fontWeight: 700, color: '#2C1A11' }}>
            Không có quyền truy cập
          </h2>
          <p style={{ margin: '0 0 16px', fontSize: '14px', color: '#756E69' }}>
            Tài khoản <strong>{user.username}</strong> ({user.role}) không được phép dùng Admin Portal.<br />
            Vui lòng liên hệ quản trị viên.
          </p>
          <button
            type="button"
            onClick={() => { logout().then(() => { window.location.replace('/login'); }); }}
            style={{
              padding: '8px 20px', background: '#3D2314', color: '#fff',
              border: 'none', borderRadius: '8px', fontSize: '13px',
              fontWeight: 700, cursor: 'pointer',
            }}
          >
            Đăng xuất
          </button>
        </div>
      </div>
    );
  }

  if (mustChangePassword && location.pathname !== '/force-password-change') {
    return <Navigate to="/force-password-change" replace />;
  }

  return <Outlet />;
}
