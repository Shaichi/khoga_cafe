import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { dailyZReport, formatVnd, formatNum, type DailyZReport } from '../../api/reports';
import { listBranches, type Branch } from '../../api/branches';
import { useAuth } from '../../auth/AuthContext';

const defaultDate = (): string => {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
};

/** UC-81 — end-of-day branch Z-report. HQ picks a branch; a Store Manager gets their own. */
export default function ZReport() {
  const { user } = useAuth();
  const isHqUser = user && ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN'].includes(user.role);

  const [day, setDay] = useState<string>(defaultDate);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [branchId, setBranchId] = useState<string>('');
  const [data, setData] = useState<DailyZReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [simulateProvisional, setSimulateProvisional] = useState(false);

  // Load branches
  useEffect(() => {
    listBranches(true)
      .then((res) => {
        setBranches(res);
        if (user && !isHqUser && user.storeId) {
          setBranchId(user.storeId);
        }
      })
      .catch(() => {});
  }, [user, isHqUser]);

  // Load Z-report automatically when date or branch changes
  useEffect(() => {
    if (isHqUser && !branchId) {
      setData(null);
      return;
    }
    setLoading(true);
    setError('');
    dailyZReport(day, branchId || undefined)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [day, branchId, isHqUser]);

  const activeBranchName = branchId
    ? branches.find(b => b.id === branchId)?.name || 'Chi nhánh'
    : 'Nguyễn Du';

  const handlePrint = () => {
    window.print();
  };

  const isProvisional = data?.provisional || simulateProvisional;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header Area */}
      <div>
        <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontFamily: 'Roboto, sans-serif' }}>
          {isHqUser ? 'HQ Admin Portal' : 'Store Manager Portal'} &rsaquo; Báo cáo &rsaquo; Daily Z-Report
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Báo Cáo Doanh Thu Ngày (Daily Z-Report)
          </h1>
          <button
            type="button"
            onClick={handlePrint}
            disabled={!data}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 18px',
              background: '#5C3826',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 600,
              cursor: !data ? 'not-allowed' : 'pointer',
              opacity: !data ? 0.6 : 1,
              fontFamily: 'Inter, sans-serif'
            }}
          >
            In / Xuất PDF
          </button>
        </div>
      </div>

      {/* Provisional Warnings Banner */}
      {isProvisional && (
        <div style={{
          background: '#FFF3E0',
          border: '1px solid #FFE0B2',
          borderRadius: '8px',
          padding: '12px 17px',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          opacity: 0.9
        }}>
          <span style={{ color: '#E65100', fontWeight: 700, fontSize: '15px' }}>&#9888;</span>
          <span style={{ fontSize: '13px', color: '#E65100', fontFamily: 'Roboto, sans-serif' }}>
            Dữ liệu tạm tính — {data?.shiftsInDay || 1} ca đang mở. Số liệu chỉ chốt chính thức sau khi toàn bộ ca trực trong ngày đóng (BR-78).
          </span>
        </div>
      )}

      {/* Filter Bar */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        background: '#FFFFFF',
        border: '1px solid #EADDD3',
        borderRadius: '12px',
        padding: '16px 21px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Ngày kinh doanh:</span>
            <input
              type="date"
              aria-label="Ngày kinh doanh"
              value={day}
              onChange={(e) => setDay(e.target.value)}
              style={{
                padding: '6px 12px',
                border: '1px solid #E5DBCF',
                borderRadius: '6px',
                fontSize: '13px',
                color: '#2C1A11',
                outline: 'none',
                fontFamily: 'Inter, sans-serif',
                cursor: 'pointer'
              }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Chi nhánh:</span>
            {isHqUser ? (
              <select
                aria-label="Chi nhánh"
                value={branchId}
                onChange={(e) => setBranchId(e.target.value)}
                style={{
                  padding: '6px 12px',
                  border: '1px solid #E5DBCF',
                  borderRadius: '6px',
                  fontSize: '13px',
                  color: '#2C1A11',
                  outline: 'none',
                  fontFamily: 'Roboto, sans-serif',
                  cursor: 'pointer',
                  width: '180px'
                }}
              >
                <option value="">— Chọn chi nhánh —</option>
                {branches.map(b => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
            ) : (
              <span style={{ fontSize: '14px', fontWeight: 700, color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                {activeBranchName}
              </span>
            )}
          </div>
        </div>

        {/* Provisional Simulator Checkbox */}
        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
          <input
            type="checkbox"
            checked={simulateProvisional}
            onChange={(e) => setSimulateProvisional(e.target.checked)}
            style={{ cursor: 'pointer' }}
          />
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>
            Mô phỏng ca làm việc còn đang mở
          </span>
        </label>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C', background: '#FFFFFF', borderRadius: '12px', border: '1px solid #EADDD3' }}>
          Đang tải…
        </div>
      ) : data ? (
        /* Split view columns */
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
          {/* Left Column: Doanh Số Chi Tiết (Sales Summary) */}
          <div style={{
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '26px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            display: 'flex',
            flexDirection: 'column',
            gap: '15px'
          }}>
            <div style={{
              fontSize: '18px',
              fontWeight: 700,
              color: '#3D2314',
              paddingBottom: '15px',
              borderBottom: '1px solid #F9F6F3',
              fontFamily: 'Roboto, sans-serif'
            }}>
              Doanh Số Chi Tiết (Sales Summary)
            </div>

            {/* Gross sales */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>Doanh thu gộp (Gross Sales)</span>
              <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2C1A11' }}>{formatVnd(data.grossSales)}</span>
            </div>

            {/* Voucher Discount */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>(&minus;) Giảm giá Voucher (Voucher Discounts)</span>
              <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#C62828', fontWeight: 600 }}>({formatVnd(data.voucherDiscount)})</span>
            </div>

            {/* Point redemption */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>(&minus;) Khấu trừ tích điểm (Point Redemptions)</span>
              <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#E65100', fontWeight: 600 }}>({formatVnd(data.pointDiscount)})</span>
            </div>

            {/* Net sales */}
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              height: '51px',
              background: '#FDFAF7',
              borderTop: '2px solid #3D2314',
              borderBottom: '2px solid #3D2314',
              padding: '0 10px',
              margin: '5px 0'
            }}>
              <span style={{ fontSize: '16px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>Doanh thu thuần (Net Sales - BR-78)</span>
              <span style={{ fontSize: '16px', fontFamily: 'Inter, sans-serif', color: '#3D2314', fontWeight: 700 }}>{formatVnd(data.netSales)}</span>
            </div>

            {/* VAT */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>VAT Thuế GTGT tích lũy (VAT incl, 10/110)</span>
              <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2C1A11' }}>{formatVnd(data.vat)}</span>
            </div>

            {/* Refunds */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>(&minus;) Hoàn trả đơn hàng (Refunds - BR-67)</span>
              <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#C62828', fontWeight: 600 }}>({formatVnd(data.refunds)})</span>
            </div>
          </div>

          {/* Right Column: Hình Thức Thu Tiền (Tender Breakdown) & counters */}
          <div style={{
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '26px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            display: 'flex',
            flexDirection: 'column',
            gap: '20px'
          }}>
            {/* Tender breakdown */}
            <div>
              <div style={{
                fontSize: '18px',
                fontWeight: 700,
                color: '#3D2314',
                paddingBottom: '15px',
                borderBottom: '1px solid #F9F6F3',
                fontFamily: 'Roboto, sans-serif',
                marginBottom: '15px'
              }}>
                Hình Thức Thu Tiền (Tender Breakdown)
              </div>

              {/* Cash */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
                  <span style={{ width: '10px', height: '10px', background: '#4CAF50', borderRadius: '50%' }} />
                  Tiền mặt (Cash)
                </span>
                <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2C1A11' }}>{formatVnd(data.tender.cash)}</span>
              </div>

              {/* Card */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
                  <span style={{ width: '10px', height: '10px', background: '#2196F3', borderRadius: '50%' }} />
                  Thẻ ngân hàng (Card)
                </span>
                <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2C1A11' }}>{formatVnd(data.tender.card)}</span>
              </div>

              {/* VietQR */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderBottom: '1px solid #F5EEE8' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
                  <span style={{ width: '10px', height: '10px', background: '#FF9800', borderRadius: '50%' }} />
                  Chuyển khoản VietQR
                </span>
                <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2C1A11' }}>{formatVnd(data.tender.vietqr)}</span>
              </div>

              {/* Total collected */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '41px', borderTop: '1px solid #EADDD3', borderBottom: '1px solid #EADDD3', margin: '5px 0' }}>
                <span style={{ fontSize: '14px', fontWeight: 500, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>Tổng tiền thu về (Total Collected)</span>
                <span style={{ fontSize: '14px', fontFamily: 'Inter, sans-serif', color: '#2E7D32', fontWeight: 700 }}>
                  {formatVnd(data.tender.cash + data.tender.card + data.tender.vietqr)}
                </span>
              </div>
            </div>

            {/* Operational Counters */}
            <div>
              <div style={{
                fontSize: '16px',
                fontWeight: 700,
                color: '#3D2314',
                paddingBottom: '10px',
                borderBottom: '1px solid #F9F6F3',
                fontFamily: 'Roboto, sans-serif',
                marginBottom: '15px'
              }}>
                Bộ đếm vận hành (Operational Counters)
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
                {/* Completed */}
                <div style={{ background: '#EFEBE9', border: '1px solid #E5DBCF', borderRadius: '6px', padding: '11px 16px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif', textTransform: 'uppercase' }}>Hoàn thành</div>
                  <div style={{ fontSize: '18px', fontWeight: 700, color: '#3D2314', fontFamily: 'Roboto, sans-serif', marginTop: '4px' }}>
                    {formatNum(data.ordersCompleted)} đơn
                  </div>
                </div>

                {/* Refund */}
                <div style={{ background: '#EFEBE9', border: '1px solid #E5DBCF', borderRadius: '6px', padding: '11px 16px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif', textTransform: 'uppercase' }}>Hoàn trả</div>
                  <div style={{ fontSize: '18px', fontWeight: 700, color: '#C62828', fontFamily: 'Roboto, sans-serif', marginTop: '4px' }}>
                    {formatNum(data.refundCount)} đơn
                  </div>
                </div>
              </div>

              {/* Pending Cancel */}
              <div style={{ background: '#FFF3E0', border: '1px solid #FFE0B2', borderRadius: '6px', padding: '11px 16px', textAlign: 'center', marginBottom: '15px' }}>
                <div style={{ fontSize: '11px', fontWeight: 600, color: '#E65100', fontFamily: 'Roboto, sans-serif', textTransform: 'uppercase' }}>Chờ Hủy (PENDING)</div>
                <div style={{ fontSize: '18px', fontWeight: 700, color: '#E65100', fontFamily: 'Roboto, sans-serif', marginTop: '4px' }}>
                  {formatNum(data.pendingCancellations)} đơn
                </div>
              </div>

              {/* Shift info subtitle */}
              <div style={{ fontSize: '13px', fontWeight: 600, color: '#5C3826', textAlign: 'center', fontFamily: 'Roboto, sans-serif' }}>
                Số ca kíp trong ngày: {data.shiftsInDay} ca ({isProvisional ? `${data.shiftsInDay - 1} ca ĐÃ ĐÓNG, 1 ca ĐANG MỞ` : `${data.shiftsInDay} ca ĐÃ ĐÓNG`})
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C', background: '#FFFFFF', borderRadius: '12px', border: '1px solid #EADDD3' }}>
          Chọn ngày{isHqUser ? ' và chi nhánh' : ''} để xem Z-Report.
        </div>
      )}
    </div>
  );
}
