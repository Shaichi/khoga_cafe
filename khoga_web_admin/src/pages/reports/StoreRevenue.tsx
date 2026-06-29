import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import {
  storeRevenue, downloadCsv, formatVnd, formatNum,
  type StoreRevenueReport, type DateRange,
} from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-40/41 — own-branch revenue summary + tender breakdown + drawer discrepancy. */
export default function StoreRevenue() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<StoreRevenueReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    storeRevenue(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  const exportCsv = () => downloadCsv('/reports/store-revenue/export', { ...range }, 'store-revenue.csv').catch(() => {});

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Doanh thu cửa hàng</h1>
        <p className="page-subtitle">Doanh thu thuần, đối soát quỹ & cơ cấu thanh toán chi nhánh (UC-40/41).</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange}>
        <button type="button" className="btn btn--ghost" onClick={exportCsv} disabled={!data}>Xuất CSV</button>
      </DateRangeBar>

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          <div className="card-grid" style={{ marginBottom: '1.25rem' }}>
            <div className="info-panel"><span className="info-panel__label">Doanh thu thuần</span>
              <span className="info-panel__value">{formatVnd(data.netRevenue)}</span></div>
            <div className="info-panel"><span className="info-panel__label">Đơn hoàn thành</span>
              <span className="info-panel__value">{formatNum(data.completedOrders)}</span></div>
            <div className="info-panel"><span className="info-panel__label">Chênh lệch quỹ</span>
              <span className="info-panel__value">{formatVnd(data.discrepancyTotal)}</span></div>
          </div>

          <h2 className="section-title">Cơ cấu thanh toán</h2>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Hình thức</th><th>Số tiền</th></tr></thead>
              <tbody>
                <tr><td>Tiền mặt</td><td>{formatVnd(data.payments.cash)}</td></tr>
                <tr><td>Thẻ</td><td>{formatVnd(data.payments.card)}</td></tr>
                <tr><td>VietQR</td><td>{formatVnd(data.payments.vietqr)}</td></tr>
                <tr style={{ fontWeight: 700 }}>
                  <td>Tổng thu</td>
                  <td>{formatVnd(data.payments.cash + data.payments.card + data.payments.vietqr)}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </div>
  );
}
