import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { listUsers, setUserActive, type User } from '../../api/users';
import { listBranches, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';
import { ROLE_LABELS, type Role } from '../../api/types';

const ROLES = Object.keys(ROLE_LABELS) as Role[];

export default function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [role, setRole] = useState<Role | ''>('');
  const [busy, setBusy] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    Promise.all([listUsers(), listBranches().catch(() => [])])
      .then(([u, b]) => { setUsers(u); setBranches(b); })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const branchName = useMemo(() => {
    const map = new Map(branches.map((b) => [b.id, b.name]));
    return (id: string | null) => (id ? map.get(id) ?? id : '— (HQ)');
  }, [branches]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return users.filter((u) => {
      if (role && u.role !== role) return false;
      if (!q) return true;
      return [u.fullName, u.username, u.email].some((f) => f?.toLowerCase().includes(q));
    });
  }, [users, search, role]);

  const toggleActive = async (u: User) => {
    setError('');
    setBusy(u.id);
    try {
      await setUserActive(u.id, !u.active);
      load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(null);
    }
  };

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Danh Sách Tài Khoản Nhân Sự</h1>
          <p className="page-subtitle">Quản lý nhân sự & phân quyền (UC-10–14).</p>
        </div>
        <Link to="/users/new" className="btn btn--primary">+ Thêm Nhân Viên</Link>
      </div>

      <div className="toolbar">
        <input className="input toolbar__search" placeholder="Tìm theo tên / username / email…"
          value={search} onChange={(e) => setSearch(e.target.value)} />
        <select className="input toolbar__select" value={role} onChange={(e) => setRole(e.target.value as Role | '')}>
          <option value="">Tất cả vai trò</option>
          {ROLES.map((r) => <option key={r} value={r}>{ROLE_LABELS[r]}</option>)}
        </select>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Họ và Tên</th><th>Username</th><th>Vai trò</th><th>Chi nhánh</th><th>Trạng thái</th><th>Hành động</th></tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="table__empty">Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="table__empty">Không có nhân viên nào.</td></tr>
            ) : filtered.map((u) => (
              <tr key={u.id}>
                <td style={{ fontWeight: 600 }}>{u.fullName}</td>
                <td className="muted">{u.username}</td>
                <td>{ROLE_LABELS[u.role]}</td>
                <td>{branchName(u.storeId)}</td>
                <td><span className={`badge ${u.active ? 'badge--active' : 'badge--inactive'}`}>{u.active ? 'Hoạt động' : 'Vô hiệu hóa'}</span></td>
                <td>
                  <span className="actions-cell">
                    <Link to={`/users/${u.id}`} className="link-action">Chi tiết</Link>
                    <Link to={`/users/${u.id}/edit`} className="link-action">Sửa</Link>
                    <button className="link-action link-action--danger" disabled={busy === u.id} onClick={() => toggleActive(u)}>
                      {u.active ? 'Vô hiệu' : 'Kích hoạt'}
                    </button>
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
