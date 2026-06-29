import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { dailyZReport, formatVnd, formatNum, type DailyZReport } from '../../api/reports';
import { listBranches, type Branch } from '../../api/branches';
import { useAuth } from '../../auth/AuthContext';
import { defaultRange } from '../../components/DateRangeBar';

const HQ_ROLES = ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN'];

/** UC-81 — end-of-day branch Z-report. HQ picks a branch; a Store Manager gets their own. */
export default function ZReport() {
  const { user } = useAuth();
  const isHq = user ? HQ_ROLES.includes(user.role) : false;

  const [day, setDay] = useState<string>(() => defaultRange().to);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [branchId, setBranchId] = useState<string>('');
  const [data, setData] = useState<DailyZReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isHq) listBranches(true).then(setBranches).catch(() => {});
  }, [isHq]);

  const load = () => {
    if (isHq && !branchId) {
      setError('Vui lòng chọn chi nhánh');
      return;
    }
    setLoading(true);
    setError('');
    dailyZReport(day, branchId || undefined)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Z-Report cuối ngày</h1>
        <p className="page-subtitle">Tổng kết toàn bộ ca của một chi nhánh trong một ngày (UC-81).</p>
      </div>

      <div className="toolbar" style={{ alignItems: 'flex-end', gap: '0.75rem', flexWrap: 'wrap' }}>
        <label className="field" style={{ margin: 0 }}>
          <span className="label">Ngày</span>
          <input className="input" type="date" aria-label="Ngày" value={day} onChange={(e) => setDay(e.target.value)} />
        </label>
        {isHq && (
          <label className="field" style={{ margin: 0 }}>
            <span className="label">Chi nhánh</span>
            <select className="input" aria-label="Chi nhánh" value={branchId} onChange={(e) => setBranchId(e.target.value)}>
              <option value="">— Chọn —</option>
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
          </label>
        )}
        <button type="button" className="btn btn--primary" onClick={load}>Xem</button>
      </div>

      {error && <div className="alert alert--error">{error}</div>}
      {loading ? (
        <div className="empty-state">Đang tải…</div>
      ) : data ? (
        <>
          {data.provisional && (
            <div className="alert alert--error" style={{ background: '#fff7e6', color: '#8a5a00' }}>
              Tạm tính — còn ca chưa đóng. Số liệu chốt khi tất cả ca đã đóng.
            </div>
          )}
          <div className="settings-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
            <div>
              <h2 className="section-title">Doanh số</h2>
              <div className="table-wrap"><table className="table"><tbody>
                <tr><td>Doanh số gộp</td><td>{formatVnd(data.grossSales)}</td></tr>
                <tr><td>(−) Giảm giá voucher</td><td>{formatVnd(data.voucherDiscount)}</td></tr>
                <tr><td>(−) Đổi điểm</td><td>{formatVnd(data.pointDiscount)}</td></tr>
                <tr style={{ fontWeight: 700 }}><td>= Doanh số thuần</td><td>{formatVnd(data.netSales)}</td></tr>
                <tr><td>VAT (gồm trong giá)</td><td>{formatVnd(data.vat)}</td></tr>
                <tr><td>(−) Hoàn tiền</td><td>{formatVnd(data.refunds)}</td></tr>
              </tbody></table></div>
            </div>
            <div>
              <h2 className="section-title">Thu theo hình thức</h2>
              <div className="table-wrap"><table className="table"><tbody>
                <tr><td>Tiền mặt</td><td>{formatVnd(data.tender.cash)}</td></tr>
                <tr><td>Thẻ</td><td>{formatVnd(data.tender.card)}</td></tr>
                <tr><td>VietQR</td><td>{formatVnd(data.tender.vietqr)}</td></tr>
                <tr style={{ fontWeight: 700 }}>
                  <td>Tổng thu</td>
                  <td>{formatVnd(data.tender.cash + data.tender.card + data.tender.vietqr)}</td>
                </tr>
              </tbody></table></div>
              <div className="info-note" style={{ marginTop: '0.75rem' }}>
                Đơn hoàn thành: <strong>{formatNum(data.ordersCompleted)}</strong> · Hoàn tiền: <strong>{formatNum(data.refundCount)}</strong>
                {' '}· Hủy (PENDING): <strong>{formatNum(data.pendingCancellations)}</strong> · Số ca: <strong>{data.shiftsInDay}</strong>
              </div>
            </div>
          </div>
        </>
      ) : (
        <div className="empty-state">Chọn ngày{isHq ? ' và chi nhánh' : ''} rồi bấm “Xem”.</div>
      )}
    </div>
  );
}
