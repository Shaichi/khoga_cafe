import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { listBranches, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';

type StatusFilter = 'all' | 'active' | 'inactive';

export default function BranchList() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');

  useEffect(() => {
    listBranches()
      .then(setBranches)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const activeCount = useMemo(() => branches.filter((b) => b.active).length, [branches]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return branches.filter((b) => {
      if (status === 'active' && !b.active) return false;
      if (status === 'inactive' && b.active) return false;
      if (!q) return true;
      return [b.name, b.address, b.phone].some((f) => f?.toLowerCase().includes(q));
    });
  }, [branches, search, status]);

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Quản Lý Chi Nhánh</h1>
          <p className="page-subtitle">Danh sách chi nhánh trong chuỗi.</p>
        </div>
        <Link to="/branches/new" className="btn btn--primary">+ Thêm Chi Nhánh</Link>
      </div>

      <div className="toolbar">
        <input
          className="input toolbar__search"
          placeholder="Tìm kiếm chi nhánh…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="input toolbar__select"
          value={status}
          onChange={(e) => setStatus(e.target.value as StatusFilter)}
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Hoạt động</option>
          <option value="inactive">Tạm đóng</option>
        </select>
        <span className="toolbar__meta">
          Đang hoạt động: <strong>{activeCount}</strong>
        </span>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Mã CN</th>
              <th>Tên Chi Nhánh</th>
              <th>Địa Chỉ</th>
              <th>Số Điện Thoại</th>
              <th>Trạng Thái</th>
              <th>Hành Động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="table__empty">Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="table__empty">Không có chi nhánh nào.</td></tr>
            ) : (
              filtered.map((b, i) => (
                <tr key={b.id}>
                  <td className="muted">STR-{String(i + 1).padStart(3, '0')}</td>
                  <td style={{ fontWeight: 600 }}>{b.name}</td>
                  <td>{b.address}</td>
                  <td>{b.phone}</td>
                  <td>
                    <span className={`badge ${b.active ? 'badge--active' : 'badge--inactive'}`}>
                      {b.active ? 'Hoạt động' : 'Tạm đóng'}
                    </span>
                  </td>
                  <td>
                    <Link to={`/branches/${b.id}`} className="link-action">Chỉnh sửa</Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
