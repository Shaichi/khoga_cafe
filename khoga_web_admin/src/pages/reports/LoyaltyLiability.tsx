import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { loyaltyLiability, formatPoints, type LoyaltyLiabilityReport, type DateRange } from '../../api/reports';
import DateRangeBar, { defaultRange } from '../../components/DateRangeBar';

/** UC-78 — outstanding loyalty points + period movement reconciliation (in points). */
export default function LoyaltyLiability() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<LoyaltyLiabilityReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');
    loyaltyLiability(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Nợ điểm thưởng & Biến động</h1>
        <p className="page-subtitle">Điểm tồn toàn chuỗi + biến động phát hành/đổi/hết hạn.</p>
      </div>

      <DateRangeBar initial={range} onApply={setRange} />

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          <div className="info-panel" style={{ marginBottom: '1.25rem' }}>
            <span className="info-panel__label">Điểm tồn (cuối kỳ, toàn chuỗi)</span>
            <span className="info-panel__value">{formatPoints(data.outstandingPoints)}</span>
          </div>

          <h2 className="section-title">Biến động trong kỳ</h2>
          <div className="table-wrap">
            <table className="table">
              <tbody>
                <tr><td>Số dư đầu kỳ</td><td>{formatPoints(data.movement.opening)}</td></tr>
                <tr><td>(+) Điểm phát hành</td><td>{formatPoints(data.movement.issued)}</td></tr>
                <tr><td>(−) Điểm đã đổi</td><td>{formatPoints(data.movement.redeemed)}</td></tr>
                <tr><td>(−) Điểm hết hạn</td><td>{formatPoints(data.movement.expired)}</td></tr>
                <tr style={{ fontWeight: 700 }}><td>= Số dư cuối kỳ</td><td>{formatPoints(data.movement.closing)}</td></tr>
              </tbody>
            </table>
          </div>
          {data.note && <p className="hint" style={{ marginTop: '0.75rem' }}>{data.note}</p>}
        </>
      ) : null}
    </div>
  );
}
