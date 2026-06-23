import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { ROLE_LABELS } from '../api/types';
import CupIcon from '../components/CupIcon';

const NAV = [
  { to: '/', label: 'Tổng quan', end: true },
  { to: '/branches', label: 'Chi nhánh' },
  { to: '/users', label: 'Tài khoản' },
  { to: '/catalog', label: 'Thực đơn & Danh mục' },
  { to: '/raw-materials', label: 'Nguyên liệu' },
  { to: '/vouchers', label: 'Voucher' },
  { to: '/customers', label: 'Khách hàng' },
  { to: '/settings', label: 'Cấu hình hệ thống' },
];

export default function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  const initials = (user?.fullName || user?.username || '?')
    .split(' ')
    .map((w) => w[0])
    .slice(-2)
    .join('')
    .toUpperCase();

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar__brand">
          <span className="sidebar__brand-mark">
            <CupIcon size={22} stroke="#c89d7c" />
          </span>
          <span className="sidebar__brand-text">
            Khoga<strong>Café</strong>
          </span>
        </div>
        <nav className="sidebar__nav">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-link${isActive ? ' nav-link--active' : ''}`}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar__footer">HQ Admin · Khoga Café</div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="topbar__spacer" />
          <div className="topbar__user">
            <div className="topbar__user-meta">
              <span className="topbar__user-name">{user?.fullName || user?.username}</span>
              <span className="topbar__user-role">{user ? ROLE_LABELS[user.role] : ''}</span>
            </div>
            <div className="avatar">{initials}</div>
            <button type="button" className="btn btn--ghost btn--sm" onClick={handleLogout}>
              Đăng xuất
            </button>
          </div>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
