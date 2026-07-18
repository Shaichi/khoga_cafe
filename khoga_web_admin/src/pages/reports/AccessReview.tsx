import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { accessReview, type AuditChangeRow, type DateRange } from '../../api/reports';
import type { PageResponse } from '../../api/types';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';
import { actionLabel, formatTs } from './auditLabels';

/** UC-83 — read-only access review: every account (user) change in the period. */
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

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Rà soát truy cập</h1>
        <p className="page-subtitle">Nhật ký bất biến mọi thay đổi tài khoản.</p>
      </div>

      <DateRangeBar initial={range} onApply={(r) => { setPage(0); setRange(r); }} />

      {error && <div className="alert alert--error">{error}</div>}
      <div className="table-wrap">
        <table className="table">
          <thead><tr><th>Thời điểm</th><th>Người thực hiện</th><th>Hành động</th><th>Chi tiết</th></tr></thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} className="table__empty">Đang tải…</td></tr>
            ) : !data || data.content.length === 0 ? (
              <tr><td colSpan={4} className="table__empty">Không có thay đổi tài khoản trong kỳ.</td></tr>
            ) : data.content.map((r) => (
              <tr key={r.id}>
                <td>{formatTs(r.timestamp)}</td>
                <td>{r.actor}</td>
                <td>{actionLabel(r.action)}</td>
                <td className="muted">{r.newValue ?? r.oldValue ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {data && data.totalPages > 1 && (
        <div className="toolbar" style={{ justifyContent: 'flex-end', gap: '0.5rem' }}>
          <button type="button" className="btn btn--ghost btn--sm" disabled={page <= 0} onClick={() => setPage((p) => p - 1)}>Trước</button>
          <span className="toolbar__meta">Trang {data.page + 1}/{data.totalPages}</span>
          <button type="button" className="btn btn--ghost btn--sm" disabled={page >= data.totalPages - 1} onClick={() => setPage((p) => p + 1)}>Sau</button>
        </div>
      )}
    </div>
  );
}
