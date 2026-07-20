import { Link, Navigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { dashModulesForRole } from '../auth/rbac';
import { ROLE_LABELS } from '../api/types';

export default function Dashboard() {
  const { user } = useAuth();

  if (user?.role === 'CEOVIEWER') {
    return <Navigate to="/reports/hq-consolidated" replace />;
  }

  const modules = user ? dashModulesForRole(user.role) : [];
  const roleLabel = user ? ROLE_LABELS[user.role] : '';

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Xin chào, {user?.fullName || user?.username}</h1>
        <p className="page-subtitle">
          {roleLabel} · Bảng điều khiển Khoga Café.
        </p>
      </div>

      {modules.length > 0 ? (
        <div className="card-grid">
          {modules.map((m) => (
            <Link key={m.to} to={m.to} className="module-card">
              <h3>{m.title}</h3>
              <p>{m.desc}</p>
            </Link>
          ))}
        </div>
      ) : (
        <div style={{ marginTop: '2rem', color: 'var(--color-text-muted)' }}>
          <p>Bạn chưa được cấp quyền truy cập module nào trên web admin.</p>
          <p>Vui lòng liên hệ quản trị viên hệ thống nếu cần hỗ trợ.</p>
        </div>
      )}
    </div>
  );
}

