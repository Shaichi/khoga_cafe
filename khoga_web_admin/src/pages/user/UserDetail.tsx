import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { getUser, type UserDetail as UserDetailModel } from '../../api/users';
import { listBranches, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';
import { ROLE_LABELS } from '../../api/types';

function fmt(dt: string | null): string {
  if (!dt) return '—';
  const d = new Date(dt);
  return Number.isNaN(d.getTime()) ? dt : d.toLocaleString('vi-VN');
}

export default function UserDetail() {
  const { id } = useParams();
  const [user, setUser] = useState<UserDetailModel | null>(null);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!id) return;
    Promise.all([getUser(id), listBranches().catch(() => [])])
      .then(([u, b]) => { setUser(u); setBranches(b); })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="full-center">Đang tải…</div>;
  if (error) return <div className="alert alert--error">{error}</div>;
  if (!user) return null;

  const branchName = user.storeId
    ? branches.find((b) => b.id === user.storeId)?.name ?? user.storeId
    : '— (HQ)';

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <Link to="/users" className="back-link">← Danh sách nhân sự</Link>
          <h1 className="page-title">{user.fullName}</h1>
          <p className="page-subtitle">{user.employeeId} · {user.username}</p>
        </div>
        <Link to={`/users/${user.id}/edit`} className="btn btn--ghost">Chỉnh sửa</Link>
      </div>

      <div className="detail-card">
        <div className="detail-grid">
          <div><span className="detail-label">Vai trò</span><span>{ROLE_LABELS[user.role]}</span></div>
          <div><span className="detail-label">Chi nhánh</span><span>{branchName}</span></div>
          <div><span className="detail-label">Email</span><span>{user.email || '—'}</span></div>
          <div><span className="detail-label">Số điện thoại</span><span>{user.phone || '—'}</span></div>
          <div><span className="detail-label">Trạng thái</span><span className={`badge ${user.active ? 'badge--active' : 'badge--inactive'}`}>{user.active ? 'Hoạt động' : 'Vô hiệu hóa'}</span></div>
          <div><span className="detail-label">Đăng nhập gần nhất</span><span>{fmt(user.lastLoginAt)}</span></div>
        </div>
      </div>

      <h2 className="section-title">Nhật ký hoạt động gần đây</h2>
      <div className="table-wrap">
        <table className="table">
          <thead><tr><th>Hành động</th><th>Đối tượng</th><th>Thời gian</th></tr></thead>
          <tbody>
            {user.recentActivity.length === 0 ? (
              <tr><td colSpan={3} className="table__empty">Chưa có hoạt động.</td></tr>
            ) : user.recentActivity.map((a, i) => (
              <tr key={i}>
                <td>{a.actionType}</td>
                <td>{a.entityAffected}</td>
                <td className="muted">{fmt(a.at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
