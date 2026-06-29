import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { cogsReport, formatVnd, formatNum, type CogsReport as CogsReportDto, type DateRange } from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-76 — per-item standard-cost margin + ingredient shrinkage. */
export default function CogsReport() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<CogsReportDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    cogsReport(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Giá vốn / Biên lợi nhuận & Hao hụt</h1>
        <p className="page-subtitle">Biên lợi nhuận theo món (giá vốn chuẩn) + hao hụt nguyên liệu (UC-76).</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange} />

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          <h2 className="section-title">Biên lợi nhuận theo món</h2>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Mặt hàng</th><th>Loại</th><th>Giá bán</th><th>Giá vốn</th><th>Lợi nhuận</th><th>Biên %</th></tr></thead>
              <tbody>
                {data.margins.length === 0 ? (
                  <tr><td colSpan={6} className="table__empty">Chưa có món nào.</td></tr>
                ) : data.margins.map((m) => (
                  <tr key={m.itemId}>
                    <td style={{ fontWeight: 600 }}>{m.name}</td>
                    <td className="muted">{m.kind === 'TOPPING' ? 'Topping' : 'Món'}</td>
                    <td>{formatVnd(m.price)}</td>
                    <td>{formatVnd(m.cogs)}</td>
                    <td>{formatVnd(m.margin)}</td>
                    <td>{m.marginPercent}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h2 className="section-title" style={{ marginTop: '1.5rem' }}>Hao hụt nguyên liệu</h2>
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>Nguyên liệu</th><th>Lý thuyết</th><th>Thực tế</th><th>Chênh lệch</th><th>Giá trị mất</th><th></th></tr></thead>
              <tbody>
                {data.shrinkage.length === 0 ? (
                  <tr><td colSpan={6} className="table__empty">Không có biến động kho trong kỳ.</td></tr>
                ) : data.shrinkage.map((s) => (
                  <tr key={s.rawMaterialId}>
                    <td style={{ fontWeight: 600 }}>{s.name} <span className="muted">({s.unit})</span></td>
                    <td>{formatNum(s.theoretical)}</td>
                    <td>{formatNum(s.actualUsage)}</td>
                    <td>{formatNum(s.variance)}</td>
                    <td>{formatVnd(s.lossValue)}</td>
                    <td>{s.flagged && <span className="badge badge--inactive">⚠ Bất thường</span>}</td>
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
