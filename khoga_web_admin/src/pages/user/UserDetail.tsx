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

  if (loading) return <div style={{ padding: '40px', color: '#8C766C' }}>Đang tải…</div>;
  if (error) return <div className="alert alert--error">{error}</div>;
  if (!user) return null;

  const branchName = user.storeId
    ? branches.find((b) => b.id === user.storeId)?.name ?? user.storeId
    : '—';

  /* ── shared styles ── */
  const card: React.CSSProperties = {
    background: '#FFFFFF',
    border: '1px solid #E0D5CC',
    borderRadius: '10px',
    padding: '24px 28px',
    marginBottom: '20px',
  };
  const lbl: React.CSSProperties = {
    fontSize: '12px', fontWeight: 600, color: '#8C766C',
    textTransform: 'uppercase', letterSpacing: '0.5px',
    fontFamily: 'Segoe UI, sans-serif', marginBottom: '4px',
  };
  const val: React.CSSProperties = {
    fontSize: '15px', fontWeight: 700, color: '#2C1A11',
    fontFamily: 'Segoe UI, sans-serif',
  };
  const TH: React.CSSProperties = {
    padding: '10px 0', textAlign: 'left',
    fontSize: '13px', fontWeight: 700, color: '#8C5A3A',
    borderBottom: '1px solid #EADDD3', fontFamily: 'Segoe UI, sans-serif',
    paddingRight: '32px',
  };
  const TD: React.CSSProperties = {
    padding: '10px 0', fontSize: '14px', color: '#2C1A11',
    borderBottom: '1px solid #F5EDE5', fontFamily: 'Segoe UI, sans-serif',
    paddingRight: '32px',
  };

  return (
    <div>
      {/* ── Header ── */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: '24px', paddingBottom: '16px', borderBottom: '1px solid #EADDD3',
      }}>
        <h1 style={{ margin: 0, fontSize: '22px', fontWeight: 700, color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif' }}>
          Chi Tiết Tài Khoản Nhân Viên
        </h1>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <Link to="/users" style={{
            height: '38px', padding: '0 16px', border: '1px solid #D1C4B9',
            borderRadius: '8px', color: '#5C3826', background: 'transparent',
            fontSize: '13px', fontFamily: 'Segoe UI, sans-serif',
            textDecoration: 'none', display: 'flex', alignItems: 'center',
          }}>
            Quay lại danh sách
          </Link>
          <Link to={`/users/${user.id}/edit`} style={{
            height: '38px', padding: '0 18px', background: '#3D2314',
            borderRadius: '8px', color: '#FFFFFF',
            fontSize: '13px', fontWeight: 700, fontFamily: 'Segoe UI, sans-serif',
            textDecoration: 'none', display: 'flex', alignItems: 'center',
          }}>
            Chỉnh sửa
          </Link>
        </div>
      </div>

      {/* ── Info card ── */}
      <div style={card}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px 40px' }}>
          <div>
            <div style={lbl}>Họ và tên</div>
            <div style={val}>{user.fullName}</div>
          </div>
          <div>
            <div style={lbl}>Tên đăng nhập</div>
            <div style={val}>{user.username}</div>
          </div>
          <div>
            <div style={lbl}>Email liên lạc</div>
            <div style={val}>{user.email || '—'}</div>
          </div>
          <div>
            <div style={lbl}>Số điện thoại</div>
            <div style={val}>{user.phone || '—'}</div>
          </div>
          <div>
            <div style={lbl}>Vai trò</div>
            <div style={val}>{ROLE_LABELS[user.role]}</div>
          </div>
          <div>
            <div style={lbl}>Chi nhánh</div>
            <div style={val}>{branchName}</div>
          </div>
        </div>
      </div>

      {/* ── Audit log card ── */}
      <div style={card}>
        <h2 style={{ margin: '0 0 16px', fontSize: '16px', fontWeight: 700, color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif' }}>
          Lịch sử hoạt động gần đây (Audit Logs)
        </h2>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th style={TH}>Thời gian</th>
              <th style={TH}>Hành động</th>
              <th style={{ ...TH, paddingRight: 0 }}>Đối tượng</th>
            </tr>
          </thead>
          <tbody>
            {user.recentActivity.length === 0 ? (
              <tr>
                <td colSpan={3} style={{ ...TD, textAlign: 'center', color: '#8C766C' }}>
                  Chưa có hoạt động nào.
                </td>
              </tr>
            ) : user.recentActivity.map((a, i) => (
              <tr key={i}>
                <td style={TD}>{fmt(a.at)}</td>
                <td style={TD}>{a.actionType}</td>
                <td style={{ ...TD, paddingRight: 0, color: '#8C766C' }}>{a.entityAffected}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
