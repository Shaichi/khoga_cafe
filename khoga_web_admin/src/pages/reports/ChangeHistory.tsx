import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { priceHistory, type AuditChangeRow, type DateRange } from '../../api/reports';
import type { PageResponse } from '../../api/types';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';
import { actionLabel, entityLabel, formatTs } from './auditLabels';

/** UC-77 — read-only price & voucher change history from the audit log. */
export default function ChangeHistory() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [type, setType] = useState('ALL');
  const [page, setPage] = useState(0);
  const [data, setData] = useState<PageResponse<AuditChangeRow> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    priceHistory(range, { type, page })
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, type, page]);

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Lịch sử đổi giá & voucher</h1>
        <p className="page-subtitle">Nhật ký bất biến mọi thay đổi giá menu và voucher.</p>
      </div>

      <DateRangeBar initial={range} onApply={(r) => { setPage(0); setRange(r); }}>
        <label className="field" style={{ margin: 0 }}>
          <span className="label">Loại</span>
          <select className="input" aria-label="Loại" value={type} onChange={(e) => { setPage(0); setType(e.target.value); }}>
            <option value="ALL">Tất cả</option>
            <option value="PRICE">Giá menu</option>
            <option value="VOUCHER">Voucher</option>
          </select>
        </label>
      </DateRangeBar>

      {error && <div className="alert alert--error">{error}</div>}
      <div className="table-wrap">
        <table className="table">
          <thead><tr><th>Thời điểm</th><th>Người thực hiện</th><th>Đối tượng</th><th>Hành động</th><th>Cũ → Mới</th></tr></thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={5} className="table__empty">Đang tải…</td></tr>
            ) : !data || data.content.length === 0 ? (
              <tr><td colSpan={5} className="table__empty">Không có thay đổi trong kỳ.</td></tr>
            ) : data.content.map((r) => (
              <tr key={r.id}>
                <td>{formatTs(r.timestamp)}</td>
                <td>{r.actor}</td>
                <td>{entityLabel(r.entity)}</td>
                <td>{actionLabel(r.action)}</td>
                <td className="muted">{(r.oldValue ?? '∅')} → {(r.newValue ?? '∅')}</td>
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
