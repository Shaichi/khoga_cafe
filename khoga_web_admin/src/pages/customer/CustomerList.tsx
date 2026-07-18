import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { listCustomers, tierFromPoints, type Customer, type Tier } from '../../api/customers';
import { errorMessage } from '../../api/client';

export const tierBadgeClass = (t: Tier) =>
  t === 'GOLD' ? 'badge--gold' : t === 'SILVER' ? 'badge--silver' : 'badge--bronze';

export default function CustomerList() {
  const [items, setItems] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  // Server-side search (phone / name contains) — debounced. Runs on mount with empty search too.
  useEffect(() => {
    const t = setTimeout(() => {
      setLoading(true);
      listCustomers(search)
        .then(setItems)
        .catch((e) => setError(errorMessage(e)))
        .finally(() => setLoading(false));
    }, 300);
    return () => clearTimeout(t);
  }, [search]);

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Đăng Ký Thành Viên & Khách Hàng</h1>
          <p className="page-subtitle">Hồ sơ khách hàng & điểm tích lũy.</p>
        </div>
        <Link to="/customers/new" className="btn btn--primary">+ Thêm Khách Hàng</Link>
      </div>

      <div className="toolbar">
        <input className="input toolbar__search" style={{ maxWidth: 'none', flex: 1 }}
          placeholder="Tìm theo tên hoặc số điện thoại…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Họ và Tên</th><th>Số Điện Thoại</th><th>Email</th><th>Điểm Tích Lũy</th><th>Hạng Thành Viên</th><th>Hành Động</th></tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="table__empty">Đang tải…</td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan={6} className="table__empty">Không tìm thấy khách hàng.</td></tr>
            ) : items.map((c) => {
              const tier = tierFromPoints(c.points);
              return (
                <tr key={c.id}>
                  <td style={{ fontWeight: 600 }}>{c.fullName}</td>
                  <td>{c.phone}</td>
                  <td className="muted">{c.email || '—'}</td>
                  <td>{(c.points ?? 0).toLocaleString('vi-VN')} điểm</td>
                  <td><span className={`badge ${tierBadgeClass(tier)}`}>{tier}</span></td>
                  <td>
                    <span className="actions-cell">
                      <Link to={`/customers/${c.id}/edit`} className="link-action">Sửa</Link>
                      <Link to={`/customers/${c.id}/history`} className="link-action">Lịch sử</Link>
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
