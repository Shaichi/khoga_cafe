import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { REPORTS, canAccess } from '../../api/reports';

/** Landing page for the P3 reporting suite — shows the reports the current role may open. */
export default function ReportsHome() {
  const { user } = useAuth();
  const visible = REPORTS.filter((r) => canAccess(r, user?.role));

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Báo cáo & Phân tích</h1>
        <p className="page-subtitle">Báo cáo vận hành & kinh doanh.</p>
      </div>
      {visible.length === 0 ? (
        <div className="empty-state">Vai trò của bạn chưa có báo cáo nào.</div>
      ) : (
        <div className="card-grid">
          {visible.map((r) => (
            <Link key={r.path} to={r.path} className="module-card">
              <h3>{r.title}</h3>
              <p>{r.desc}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
