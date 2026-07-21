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
  let navItems = user ? navForRole(user.role) : [];
  if (user?.role === 'CEOVIEWER') {
    navItems = [
      { to: '/reports/hq-consolidated', label: 'Báo cáo doanh thu' },
      { to: '/reports/cogs', label: 'Báo cáo COGS & Hao hụt' },
      { to: '/reports/change-history', label: 'Lịch sử giá & Voucher' },
      { to: '/reports/loyalty-liability', label: 'Báo cáo tích điểm loyalty' },
      { to: '/reports/labour', label: 'Năng suất lao động' },
      { to: '/reports/anomaly', label: 'Bất thường thu ngân' },
      { to: '/reports/z-report', label: 'Daily Z-Report' },
    ];
  }
  const roleLabel = user ? ROLE_LABELS[user.role] : '';

  const isHome = location.pathname === '/';

  return (
    <div className="layout">
      <aside className="sidebar">
        {user?.role === 'CEOVIEWER' ? (
          <div className="sidebar__brand" style={{ flexDirection: 'column', alignItems: 'center', gap: '6px', padding: '41px 15px 22px' }}>
            <span style={{ fontSize: '20px', fontWeight: 700, color: '#C89D7C', fontFamily: 'Roboto, sans-serif', textAlign: 'center', width: '100%' }}>
              Khoga Café HQ
            </span>
            <span style={{ fontSize: '12px', fontWeight: 400, color: '#9C8579', fontFamily: 'Roboto, sans-serif', textAlign: 'center', width: '100%' }}>
              CEO Viewer
            </span>
          </div>
        ) : (
          <div className="sidebar__brand">
            <span className="sidebar__brand-mark">
              <CupIcon size={22} stroke="#c89d7c" />
            </span>
            <span className="sidebar__brand-text">
              Khoga<strong>Café</strong>
            </span>
          </div>
        )}
        <nav className="sidebar__nav">
          {navItems.map((item) => (
            <NavLink
              key={item.to + (item.label)}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-link${isActive ? ' nav-link--active' : ''}`}
              style={({ isActive }) => {
                if (user?.role === 'CEOVIEWER') {
                  return {
                    color: isActive ? '#FFFFFF' : '#D1C4B9',
                    backgroundColor: isActive ? '#5C3826' : 'transparent',
                    borderRadius: '8px',
                    fontFamily: 'Roboto, sans-serif',
                    fontWeight: 600,
                    fontSize: '14px',
                    padding: '12px 15px'
                  };
                }
                return {};
              }}
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
