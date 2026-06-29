import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { labourReport, formatVnd, formatNum, type LabourReport as LabourReportDto, type LabourRow, type DateRange } from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-79 — labour hours vs revenue (non-monetary labour KPI). */
export default function LabourReport() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<LabourReportDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    labourReport(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  const row = (r: LabourRow, total = false) => (
    <tr key={r.storeId ?? 'total'} style={total ? { fontWeight: 700 } : undefined}>
      <td>{r.storeName}</td>
      <td>{formatNum(r.labourHours)}</td>
      <td>{formatVnd(r.netSales)}</td>
      <td>{formatNum(r.hoursPerMillion)}</td>
      <td>{formatVnd(r.vndPerHour)}</td>
    </tr>
  );

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Năng suất lao động vs Doanh thu</h1>
        <p className="page-subtitle">Giờ công / 1 triệu VND và VND / giờ theo chi nhánh (UC-79).</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange} />

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>Chi nhánh</th><th>Giờ công</th><th>Doanh thu thuần</th><th>Giờ / 1tr VND</th><th>VND / giờ</th></tr></thead>
            <tbody>
              {data.branches.length === 0 ? (
                <tr><td colSpan={5} className="table__empty">Không có dữ liệu trong kỳ.</td></tr>
              ) : data.branches.map((r) => row(r))}
              {data.chainTotal && row(data.chainTotal, true)}
            </tbody>
          </table>
        </div>
      ) : null}
      <p className="hint" style={{ marginTop: '0.75rem' }}>
        Chỉ số năng suất — không quy đổi ra lương (BR-76; tiền lương do kế toán ngoài hệ thống).
      </p>
    </div>
  );
}
