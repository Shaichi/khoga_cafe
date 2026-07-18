import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import {
  hqConsolidated, downloadCsv, formatVnd, formatNum,
  type HqConsolidatedReport, type DateRange,
} from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-28/29 — consolidated chain revenue dashboard + CSV export. */
export default function HqConsolidated() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<HqConsolidatedReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    hqConsolidated(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  const exportCsv = () => downloadCsv('/reports/hq-consolidated/export', { ...range }, 'hq-consolidated.csv').catch(() => {});

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Doanh thu hợp nhất toàn chuỗi</h1>
        <p className="page-subtitle">Tổng hợp doanh thu, so sánh chi nhánh & bán chạy.</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange}>
        <button type="button" className="btn btn--ghost" onClick={exportCsv} disabled={!data}>
          Xuất CSV
        </button>
      </DateRangeBar>

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          <div className="card-grid" style={{ marginBottom: '1.25rem' }}>
            <div className="info-panel"><span className="info-panel__label">Tổng doanh thu</span>
              <span className="info-panel__value">{formatVnd(data.totalRevenue)}</span></div>
            <div className="info-panel"><span className="info-panel__label">Tổng số đơn</span>
              <span className="info-panel__value">{formatNum(data.totalOrders)}</span></div>
            <div className="info-panel"><span className="info-panel__label">Giá trị đơn TB</span>
              <span className="info-panel__value">{formatVnd(data.avgTransactionValue)}</span></div>
            <div className="info-panel"><span className="info-panel__label">Tỉ lệ hủy</span>
              <span className="info-panel__value">{data.cancellationRate}%</span></div>
          </div>

          <h2 className="section-title">So sánh chi nhánh</h2>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Chi nhánh</th><th>Doanh thu</th><th>Số đơn</th></tr></thead>
              <tbody>
                {data.branches.length === 0 ? (
                  <tr><td colSpan={3} className="table__empty">Không có dữ liệu trong kỳ.</td></tr>
                ) : data.branches.map((b) => (
                  <tr key={b.storeId}>
                    <td style={{ fontWeight: 600 }}>{b.storeName}</td>
                    <td>{formatVnd(b.revenue)}</td>
                    <td>{formatNum(b.orders)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h2 className="section-title" style={{ marginTop: '1.5rem' }}>Bán chạy nhất</h2>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Món</th><th>Số lượng bán</th></tr></thead>
              <tbody>
                {data.bestSellers.length === 0 ? (
                  <tr><td colSpan={2} className="table__empty">Không có dữ liệu.</td></tr>
                ) : data.bestSellers.map((s) => (
                  <tr key={s.menuItemId}><td>{s.name}</td><td>{formatNum(s.quantitySold)}</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </div>
  );
}
