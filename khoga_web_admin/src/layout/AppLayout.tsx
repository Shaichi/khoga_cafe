import { Link, NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { ROLE_LABELS } from '../api/types';
import CupIcon from '../components/CupIcon';
import { navForRole } from '../auth/rbac';

export default function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

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

  // Lọc nav theo role hiện tại
  const navItems = user ? navForRole(user.role) : [];
  const roleLabel = user ? ROLE_LABELS[user.role] : '';

  const isHome = location.pathname === '/';

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
          {navItems.map((item) => (
            <NavLink
              key={item.to + (item.label)}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-link${isActive ? ' nav-link--active' : ''}`}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar__footer">{roleLabel} · Khoga Café</div>
      </aside>

      <div className="main">
        <header className="topbar">
          {!isHome && (
            <button
              type="button"
              className="btn btn--ghost btn--sm"
              onClick={() => navigate(-1)}
              style={{ display: 'flex', alignItems: 'center', gap: '6px', marginRight: '14px', fontWeight: 600 }}
            >
              ← Quay lại
            </button>
          )}
          <div className="topbar__spacer" />
          <div className="topbar__user">
            <Link to="/profile" className="topbar__user-link" title="Thông tin cá nhân">
              <div className="topbar__user-meta">
                <span className="topbar__user-name">{user?.fullName || user?.username}</span>
                <span className="topbar__user-role">{roleLabel}</span>
              </div>
              <div className="avatar">{initials}</div>
            </Link>
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
