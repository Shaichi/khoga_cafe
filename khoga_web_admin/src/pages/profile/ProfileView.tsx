import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { ROLE_LABELS } from '../../api/types';
import { listBranches } from '../../api/branches';

/**
 * Screen 06 — "Thông Tin Cá Nhân". Read-only view of the signed-in user, with
 * actions to edit contact info (07), change password (08), or log out. The user
 * comes from AuthContext (already fetched on app load); the branch name is
 * resolved lazily only for branch-scoped staff.
 */
export default function ProfileView() {
  const { user, loading, logout } = useAuth();
  const navigate = useNavigate();
  const [branchName, setBranchName] = useState('');

  useEffect(() => {
    const storeId = user?.storeId;
    if (!storeId) return;
    let cancelled = false;
    listBranches()
      .then((bs) => !cancelled && setBranchName(bs.find((b) => b.id === storeId)?.name ?? storeId))
      .catch(() => !cancelled && setBranchName(storeId));
    return () => {
      cancelled = true;
    };
  }, [user?.storeId]);

  if (loading) return <div className="full-center">Đang tải…</div>;
  if (!user) return null;

  const initials = (user.fullName || user.username || '?')
    .split(' ')
    .map((w) => w[0])
    .slice(-2)
    .join('')
    .toUpperCase();

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Thông tin cá nhân</h1>
        <p className="page-subtitle">Xem và quản lý thông tin tài khoản của bạn.</p>
      </div>

      <div className="detail-card">
        <div className="profile-head">
          <div className="avatar avatar--lg">{initials}</div>
        </div>

        <div className="detail-grid">
          <div><span className="detail-label">Họ và tên</span><span>{user.fullName}</span></div>
          <div><span className="detail-label">Tên đăng nhập</span><span>{user.username}</span></div>
          <div><span className="detail-label">Vai trò</span><span>{ROLE_LABELS[user.role]}</span></div>
          <div><span className="detail-label">Chi nhánh</span><span>{user.storeId ? (branchName || '…') : '— (HQ)'}</span></div>
          <div><span className="detail-label">Email</span><span>{user.email || '—'}</span></div>
          <div><span className="detail-label">Số điện thoại</span><span>{user.phone || '—'}</span></div>
        </div>

        <div className="form-actions">
          <Link to="/profile/edit" className="btn btn--ghost">Chỉnh sửa thông tin</Link>
          <Link to="/profile/password" className="btn btn--ghost">Đổi mật khẩu</Link>
          <button type="button" className="btn btn--danger" style={{ marginLeft: 'auto' }} onClick={handleLogout}>
            Đăng xuất
          </button>
        </div>
      </div>
    </div>
  );
}
