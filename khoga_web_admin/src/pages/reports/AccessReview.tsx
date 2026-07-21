import { useEffect, useMemo, useState } from 'react';
import { errorMessage } from '../../api/client';
import { accessReview, type AuditChangeRow, type DateRange } from '../../api/reports';
import type { PageResponse } from '../../api/types';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';
import { actionLabel, formatTs } from './auditLabels';

/* ── styles ── */
const pageStyle: React.CSSProperties = {
  display: 'flex', flexDirection: 'column', gap: '22px',
  fontFamily: 'Inter, sans-serif',
};
const card: React.CSSProperties = {
  background: '#FFFFFF',
  border: '1px solid #E5DED6',
  borderRadius: '14px',
  boxShadow: '0px 2px 8px 0px rgba(26,18,13,0.06)',
};
const TH: React.CSSProperties = {
  padding: '11px 16px', textAlign: 'left',
  fontSize: '12px', fontWeight: 600, color: '#756E69',
  background: '#F7F2ED', borderBottom: '1px solid #E5DED6',
};
const TD: React.CSSProperties = {
  padding: '12px 16px', fontSize: '13px', color: '#2B1A11',
  borderBottom: '1px solid #F0E8E0',
};

/* ── stat card ── */
function StatCard({ label, value, color }: { label: string; value: number; color?: string }) {
  return (
    <div style={{ ...card, padding: '16px 18px', flex: 1, display: 'flex', flexDirection: 'column', gap: '4px' }}>
      <span style={{ fontSize: '12px', color: '#756E69', fontWeight: 500 }}>{label}</span>
      <span style={{ fontSize: '24px', fontWeight: 700, color: color ?? '#3D2314' }}>{value}</span>
    </div>
  );
}

/** UC-83 — read-only access review: every account change in the period. */
export default function AccessReview() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [page, setPage] = useState(0);
  const [data, setData] = useState<PageResponse<AuditChangeRow> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    accessReview(range, { page })
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, page]);

  /* derive stats from current page data */
  const rows: AuditChangeRow[] = data?.content ?? [];
  const stats = useMemo(() => ({
    active: rows.filter((r) => r.action === 'CREATE').length,
    changes: rows.length,
    resets: rows.filter((r) => r.action === 'RESET_PASSWORD').length,
    disabled: rows.filter((r) => r.action === 'DISABLE').length,
  }), [rows]);

  return (
    <div style={pageStyle}>

      {/* ── Header ── */}
      <div style={{ borderBottom: '1px solid #EADDD3', paddingBottom: '14px' }}>
        <p style={{ margin: '0 0 4px', fontSize: '12px', color: '#756E69', fontWeight: 500 }}>
          Báo cáo › Rà soát tài khoản &amp; truy cập
        </p>
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2B1A11' }}>
          Thay Đổi Tài Khoản &amp; Rà Soát Truy Cập
        </h1>
      </div>

      {/* ── Filter bar ── */}
      <DateRangeBar initial={range} onApply={(r) => { setPage(0); setRange(r); }} />

      {/* ── Stat cards ── */}
      <div style={{ display: 'flex', gap: '16px' }}>
        <StatCard label="Tài khoản HQ đang hoạt động" value={stats.active} color="#3D2314" />
        <StatCard label="Thay đổi trong kỳ"           value={stats.changes} />
        <StatCard label="Cấp lại mật khẩu"            value={stats.resets} />
        <StatCard label="Tài khoản bị vô hiệu"         value={stats.disabled} color="#D42E26" />
      </div>

      {/* ── Audit table card ── */}
      <div style={{ ...card, padding: '18px 18px 14px' }}>
        <h2 style={{ margin: '0 0 12px', fontSize: '16px', fontWeight: 700, color: '#2B1A11' }}>
          Nhật ký thay đổi tài khoản (AUDIT_LOG — BR-81)
        </h2>

        {error && <div className="alert alert--error" style={{ marginBottom: '12px' }}>{error}</div>}

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th style={{ ...TH, width: '150px' }}>Thời điểm</th>
                <th style={{ ...TH, width: '130px' }}>Người thực hiện</th>
                <th style={{ ...TH, width: '150px' }}>Hành động</th>
                <th style={TH}>Tài khoản đích</th>
                <th style={TH}>Chi tiết</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} style={{ ...TD, textAlign: 'center', color: '#8C766C' }}>Đang tải…</td></tr>
              ) : rows.length === 0 ? (
                <tr><td colSpan={5} style={{ ...TD, textAlign: 'center', color: '#8C766C' }}>Không có thay đổi tài khoản trong kỳ.</td></tr>
              ) : rows.map((r, i) => (
                <tr key={r.id} style={{ background: i % 2 === 0 ? '#FFFFFF' : '#FBF9F7' }}>
                  <td style={{ ...TD, fontWeight: 600, fontSize: '13px' }}>{formatTs(r.timestamp)}</td>
                  <td style={TD}>{r.actor}</td>
                  <td style={TD}>{actionLabel(r.action)}</td>
                  <td style={TD}>{r.entity || '—'}</td>
                  <td style={{ ...TD, color: '#756E69' }}>{r.newValue ?? r.oldValue ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {data && data.totalPages > 1 && (
          <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '8px', marginTop: '12px' }}>
            <button
              type="button"
              className="btn btn--ghost btn--sm"
              disabled={page <= 0}
              onClick={() => setPage((p) => p - 1)}
            >
              Trước
            </button>
            <span style={{ fontSize: '13px', color: '#756E69' }}>
              Trang {(data.page ?? page) + 1}/{data.totalPages}
            </span>
            <button
              type="button"
              className="btn btn--ghost btn--sm"
              disabled={page >= data.totalPages - 1}
              onClick={() => setPage((p) => p + 1)}
            >
              Sau
            </button>
          </div>
        )}

        <p style={{ margin: '14px 0 0', fontSize: '11px', color: '#756E69' }}>
          Phục vụ rà soát định kỳ (attestation) tách biệt nhiệm vụ (SoD) — chỉ đọc (BR-81).
        </p>
      </div>

    </div>
  );
}
