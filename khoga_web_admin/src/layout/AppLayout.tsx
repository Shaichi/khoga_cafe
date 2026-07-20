import { useState } from 'react';

import {
  Link,
  NavLink,
  Outlet,
  useLocation,
  useNavigate,
} from 'react-router-dom';

import { useAuth } from '../auth/AuthContext';
import { ROLE_LABELS } from '../api/types';
import CupIcon from '../components/CupIcon';
import { navForRole } from '../auth/rbac';

export default function AppLayout() {
  const { user, logout } = useAuth();

  const navigate = useNavigate();
  const location = useLocation();

  const [
    catalogAccountOpen,
    setCatalogAccountOpen,
  ] = useState(false);

  /*
   * Catalog và Voucher cùng sử dụng giao diện tham chiếu:
   * - Sidebar nâu theo mockup
   * - Không hiển thị topbar
   * - Không có nút quay lại
   */
  const isReferenceManagement =
    location.pathname.startsWith('/catalog') ||
    location.pathname.startsWith('/vouchers');

  const handleLogout = async () => {
    await logout();

    navigate('/login', {
      replace: true,
    });
  };

  const initials = (
    user?.fullName ||
    user?.username ||
    '?'
  )
    .split(' ')
    .filter(Boolean)
    .map((word) => word[0])
    .slice(-2)
    .join('')
    .toUpperCase();

  const navItems = user
    ? navForRole(user.role)
    : [];

  const roleLabel = user
    ? ROLE_LABELS[user.role]
    : '';

  const displayNavLabel = (
    to: string,
    label: string,
  ) => {
    if (!isReferenceManagement) {
      return label;
    }

    if (to === '/') {
      return 'Trang chủ';
    }

    if (to === '/catalog') {
      return 'Thực đơn';
    }

    if (to === '/vouchers') {
      return 'Vouchers';
    }

    if (to === '/customers') {
      return 'Khách hàng';
    }

    if (to === '/reports') {
      return 'Báo cáo';
    }

    if (to === '/settings') {
      return 'Cấu hình';
    }

    return label;
  };

  const closeAccountMenu = () => {
    setCatalogAccountOpen(false);
  };

  return (
    <div
      className={`layout${isReferenceManagement
          ? ' layout--catalog-reference'
          : ''
        }`}
    >
      <aside className="sidebar">
        <div className="sidebar__brand">
          {isReferenceManagement ? (
            <>
              <button
                type="button"
                className="sidebar__catalog-brand"
                aria-expanded={catalogAccountOpen}
                onClick={() =>
                  setCatalogAccountOpen(
                    (open) => !open,
                  )
                }
              >
                Khoga Café Admin
              </button>

              {catalogAccountOpen && (
                <div className="sidebar__catalog-account-menu">
                  <Link
                    to="/profile"
                    onClick={closeAccountMenu}
                  >
                    Hồ sơ cá nhân
                  </Link>

                  <button
                    type="button"
                    onClick={() => {
                      closeAccountMenu();
                      void handleLogout();
                    }}
                  >
                    Đăng xuất
                  </button>
                </div>
              )}
            </>
          ) : (
            <>
              <span className="sidebar__brand-mark">
                <CupIcon
                  size={22}
                  stroke="#c89d7c"
                />
              </span>

              <span className="sidebar__brand-text">
                Khoga<strong>Café</strong>
              </span>
            </>
          )}
        </div>

        <nav className="sidebar__nav">
          {navItems.map((item) => (
            <NavLink
              key={`${item.to}-${item.label}`}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `nav-link${isActive
                  ? ' nav-link--active'
                  : ''
                }`
              }
              onClick={closeAccountMenu}
            >
              {displayNavLabel(
                item.to,
                item.label,
              )}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar__footer">
          {roleLabel} · Khoga Café
        </div>
      </aside>

      <div className="main">
        {/*
         * Topbar chỉ xuất hiện ở những màn sử dụng
         * giao diện quản trị cũ.
         *
         * Catalog và Voucher không có topbar
         * để bám đúng mockup.
         */}
        {!isReferenceManagement && (
          <header className="topbar">
            <div className="topbar__spacer" />

            <div className="topbar__user">
              <Link
                to="/profile"
                className="topbar__user-link"
                title="Thông tin cá nhân"
              >
                <div className="topbar__user-meta">
                  <span className="topbar__user-name">
                    {user?.fullName ||
                      user?.username}
                  </span>

                  <span className="topbar__user-role">
                    {roleLabel}
                  </span>
                </div>

                <div className="avatar">
                  {initials}
                </div>
              </Link>

              <button
                type="button"
                className="btn btn--ghost btn--sm"
                onClick={() =>
                  void handleLogout()
                }
              >
                Đăng xuất
              </button>
            </div>
          </header>
        )}

        <main
          className={`content${isReferenceManagement
              ? ' content--catalog-reference'
              : ''
            }`}
        >
          <Outlet />
        </main>
      </div>
    </div>
  );
}