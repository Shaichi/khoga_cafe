import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { anomalyReport, downloadCsv, formatNum, type AnomalyReport as AnomalyReportDto, type DateRange } from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-82 — per-cashier void/refund anomaly with threshold flagging. */
export default function AnomalyReport() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<AnomalyReportDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    anomalyReport(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  const exportCsv = () => downloadCsv('/reports/anomaly/export', { ...range }, 'cashier-anomaly.csv').catch(() => {});

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Bất thường hủy / hoàn theo thu ngân</h1>
        <p className="page-subtitle">Phát hiện tỉ lệ hủy/hoàn vượt ngưỡng cảnh báo (UC-82, BR-79).</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange}>
        <button type="button" className="btn btn--ghost" onClick={exportCsv} disabled={!data}>Xuất CSV</button>
      </DateRangeBar>

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          <p className="hint">Ngưỡng cảnh báo: <strong>{data.thresholdPercent}%</strong></p>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Thu ngân</th><th>Đơn</th><th>Hủy</th><th>% Hủy</th><th>Hoàn</th><th>% Hoàn</th><th>Voucher</th><th>Comp</th><th>Cờ</th></tr></thead>
              <tbody>
                {data.cashiers.length === 0 ? (
                  <tr><td colSpan={9} className="table__empty">Không có dữ liệu trong kỳ.</td></tr>
                ) : data.cashiers.map((c) => (
                  <tr key={c.cashierId}>
                    <td style={{ fontWeight: 600 }}>{c.cashierName}</td>
                    <td>{formatNum(c.orders)}</td>
                    <td>{formatNum(c.cancellations)}</td>
                    <td>{c.cancelRate}%</td>
                    <td>{formatNum(c.refunds)}</td>
                    <td>{c.refundRate}%</td>
                    <td>{formatNum(c.vouchers)}</td>
                    <td>{formatNum(c.comps)}</td>
                    <td>{c.flagged && <span className="badge badge--inactive">⚠ Cao</span>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : null}
    </div>
  );
}
