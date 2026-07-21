import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { loyaltyLiability, formatNum, type LoyaltyLiabilityReport, type DateRange } from '../../api/reports';
import { listBranches, type Branch } from '../../api/branches';

/** Default date range: first day of current month -> today */
const defaultRange = (): DateRange => {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
};

/** UC-78 — outstanding loyalty points + period movement reconciliation (in points). */
export default function LoyaltyLiability() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<LoyaltyLiabilityReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [branches, setBranches] = useState<Branch[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState('');

  // Load active branch list
  useEffect(() => {
    listBranches(true)
      .then(setBranches)
      .catch(() => {});
  }, []);

  // Load report data
  useEffect(() => {
    setLoading(true);
    setError('');
    loyaltyLiability(range, selectedBranchId || undefined)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, selectedBranchId]);

  const selectedBranchName = selectedBranchId 
    ? branches.find(b => b.id === selectedBranchId)?.name || 'Chi nhánh'
    : 'Tất cả chi nhánh';

  // Client-side CSV export
  const exportToCsv = () => {
    if (!data) return;
    const rows = [
      ['BÁO CÁO ĐIỂM THƯỞNG HỘI VIÊN (LOYALTY POINTS)'],
      [`Từ ngày: ${range.from}`, `Đến ngày: ${range.to}`, `Chi nhánh: ${selectedBranchName}`],
      [],
      ['TỔNG DƯ NỢ ĐIỂM TÍCH LŨY CHƯA QUY ĐỔI (Cuối kỳ)'],
      ['Số điểm (pts)', 'Giá trị quy đổi ước tính (VND)'],
      [data.outstandingPoints, data.outstandingPoints * 100],
      [],
      ['BIẾN ĐỘNG ĐIỂM TÍCH LŨY (Movement - BR-75)'],
      ['Chỉ mục', 'Điểm thưởng (Points)'],
      ['Số dư đầu kỳ (Opening Balance)', data.movement.opening],
      ['(+) Điểm phát sinh mới (Points Issued)', data.movement.issued],
      ['(-) Điểm đã đổi voucher/giảm giá (Points Redeemed)', -data.movement.redeemed],
      ['(-) Điểm hết hạn (12 tháng không tương tác - BR-35)', -data.movement.expired],
      ['Số dư cuối kỳ (Closing Balance)', data.movement.closing],
    ];

    const csvContent = "\uFEFF" + rows.map(e => e.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `bao_cao_loyalty_points_${range.from}_to_${range.to}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const setQuickRange = (type: '7days' | 'thisMonth' | 'lastMonth') => {
    const now = new Date();
    const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    
    if (type === '7days') {
      const past = new Date();
      past.setDate(now.getDate() - 7);
      setRange({ from: iso(past), to: iso(now) });
    } else if (type === 'thisMonth') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      setRange({ from: iso(firstDay), to: iso(now) });
    } else if (type === 'lastMonth') {
      const firstDayLast = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lastDayLast = new Date(now.getFullYear(), now.getMonth(), 0);
      setRange({ from: iso(firstDayLast), to: iso(lastDayLast) });
    }
  };

  const isRangeActive = (type: '7days' | 'thisMonth' | 'lastMonth') => {
    const now = new Date();
    const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    
    let targetRange: DateRange;
    if (type === '7days') {
      const past = new Date();
      past.setDate(now.getDate() - 7);
      targetRange = { from: iso(past), to: iso(now) };
    } else if (type === 'thisMonth') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      targetRange = { from: iso(firstDay), to: iso(now) };
    } else {
      const firstDayLast = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lastDayLast = new Date(now.getFullYear(), now.getMonth(), 0);
      targetRange = { from: iso(firstDayLast), to: iso(lastDayLast) };
    }
    return range.from === targetRange.from && range.to === targetRange.to;
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header Area */}
      <div>
        <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontFamily: 'Roboto, sans-serif' }}>
          HQ Admin Portal &rsaquo; Báo cáo &rsaquo; Loyalty Points Liability & Movement
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Báo Cáo Điểm Thưởng Hội Viên (Loyalty Points)
          </h1>
          <button
            type="button"
            onClick={exportToCsv}
            disabled={!data}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 18px',
              background: '#3D2314',
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
            Xuất Báo Cáo
          </button>
        </div>
      </div>

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
        <div style={{ display: 'flex', gap: '8px' }}>
          {[
            { id: '7days', label: '7 ngày qua' },
            { id: 'thisMonth', label: 'Tháng này' },
            { id: 'lastMonth', label: 'Tháng trước' }
          ].map((btn) => {
            const active = isRangeActive(btn.id as any);
            return (
              <button
                key={btn.id}
                type="button"
                onClick={() => setQuickRange(btn.id as any)}
                style={{
                  padding: '6px 14px',
                  background: active ? '#FDFAF7' : 'transparent',
                  border: `1px solid ${active ? '#C89D7C' : '#E5DBCF'}`,
                  borderRadius: '6px',
                  color: active ? '#3D2314' : '#8C766C',
                  fontWeight: active ? 700 : 400,
                  fontSize: '13px',
                  cursor: 'pointer',
                  fontFamily: 'Inter, sans-serif',
                  transition: 'all 0.15s'
                }}
              >
                {btn.label}
              </button>
            );
          })}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Từ:</span>
            <input
              type="date"
              aria-label="Từ ngày"
              value={range.from}
              max={range.to}
              onChange={(e) => setRange(r => ({ ...r, from: e.target.value }))}
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
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Đến:</span>
            <input
              type="date"
              aria-label="Đến ngày"
              value={range.to}
              min={range.from}
              onChange={(e) => setRange(r => ({ ...r, to: e.target.value }))}
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
            <select
              aria-label="Chi nhánh"
              value={selectedBranchId}
              onChange={(e) => setSelectedBranchId(e.target.value)}
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
              <option value="">Tất cả</option>
              {branches.map(b => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C', background: '#FFFFFF', borderRadius: '12px', border: '1px solid #EADDD3' }}>
          Đang tải…
        </div>
      ) : data ? (
        <>
          {/* Giant Gradient Banner Card */}
          <div style={{
            background: 'linear-gradient(225deg, #3D2314 0%, #5C3826 100%)',
            boxShadow: '0px 6px 18px 0px rgba(61, 35, 20, 0.15)',
            borderRadius: '16px',
            padding: '25px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            color: '#FFFFFF'
          }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#D1C4B9', fontFamily: 'Roboto, sans-serif' }}>
                Tổng dư nợ điểm tích lũy chưa quy đổi (Cuối kỳ)
              </div>
              <div style={{ fontSize: '36px', fontWeight: 700, color: '#C89D7C', fontFamily: 'Roboto, sans-serif' }}>
                {formatNum(data.outstandingPoints)} pts
              </div>
              <div style={{ fontSize: '14px', fontWeight: 500, color: '#D1C4B9', fontFamily: 'Roboto, sans-serif' }}>
                &asymp; Quy đổi ước tính: {formatNum(data.outstandingPoints * 100)} VND (BR-74)
              </div>
            </div>
            {/* SVG Crown/Loyalty Icon on the Right */}
            <div style={{ opacity: 0.85 }}>
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#C89D7C" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
              </svg>
            </div>
          </div>

          {/* Split View Grid: Reconciliation Table vs Operating Rules */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
            
            {/* Left Column: Reconciliation Table Card */}
            <div style={{
              background: '#FFFFFF',
              border: '1px solid #EADDD3',
              borderRadius: '12px',
              padding: '26px',
              boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)'
            }}>
              <div style={{
                fontSize: '18px',
                fontWeight: 700,
                color: '#3D2314',
                paddingBottom: '26px',
                borderBottom: '1px solid #F9F6F3',
                fontFamily: 'Roboto, sans-serif',
                marginBottom: '15px'
              }}>
                Biến Động Điểm Tích Lũy (Movement - BR-75)
              </div>

              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                  <thead>
                    <tr style={{ background: '#F9F6F3', height: '56.5px' }}>
                      <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Chỉ mục</th>
                      <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Điểm thưởng (Points)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {/* Row 1 */}
                    <tr style={{ height: '47px', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                        Số dư đầu kỳ (Opening Balance)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif', fontSize: '15px' }}>
                        {formatNum(data.movement.opening)}
                      </td>
                    </tr>

                    {/* Row 2 */}
                    <tr style={{ height: '47px', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                        (+) Điểm phát sinh mới (Points Issued)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif', fontSize: '15px' }}>
                        +{formatNum(data.movement.issued)}
                      </td>
                    </tr>

                    {/* Row 3 */}
                    <tr style={{ height: '61px', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                        (&minus;) Điểm đã đổi voucher/giảm giá (Points Redeemed)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif', fontSize: '15px' }}>
                        ({formatNum(data.movement.redeemed)})
                      </td>
                    </tr>

                    {/* Row 4 */}
                    <tr style={{ height: '61.5px', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                        (&minus;) Điểm hết hạn (12 tháng không tương tác - BR-35)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif', fontSize: '15px' }}>
                        ({formatNum(data.movement.expired)})
                      </td>
                    </tr>

                    {/* Row 5 */}
                    <tr style={{ height: '47.5px', borderTop: '2px solid #3D2314', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                        Số dư cuối kỳ (Closing Balance)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif', fontSize: '15px', fontWeight: 700 }}>
                        {formatNum(data.movement.closing)}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            {/* Right Column: Business Rules Card */}
            <div style={{
              background: '#FDFAF7',
              border: '1px solid #EADDD3',
              borderRadius: '12px',
              padding: '26px',
              boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
              display: 'flex',
              flexDirection: 'column',
              gap: '15px'
            }}>
              <div style={{
                fontSize: '16px',
                fontWeight: 700,
                color: '#5C3826',
                paddingBottom: '15px',
                borderBottom: '1px solid #EADDD3',
                fontFamily: 'Roboto, sans-serif'
              }}>
                Quy định vận hành Điểm thưởng (Business Rules)
              </div>

              <ul style={{
                paddingLeft: '20px',
                margin: 0,
                display: 'flex',
                flexDirection: 'column',
                gap: '16px',
                fontFamily: 'Roboto, sans-serif',
                fontSize: '13px',
                lineHeight: '22px',
                color: '#000000'
              }}>
                <li>
                  <strong style={{ color: '#5C3826', fontWeight: 700 }}>BR-75 (Báo cáo Loyalty): </strong>
                  Dư nợ được báo cáo theo đơn vị ĐIỂM (không quy đổi trực tiếp trong sổ sách kế toán cốt lõi). Phục vụ việc theo dõi và đánh giá độ phơi nhiễm (exposure) của chuỗi.
                </li>
                <li>
                  <strong style={{ color: '#5C3826', fontWeight: 700 }}>BR-01 &amp; BR-69 (Tích điểm): </strong>
                  Điểm được tích lũy theo tỷ lệ phần trăm (ví dụ: 1%) trên tổng thanh toán thực tế của hóa đơn.
                </li>
                <li>
                  <strong style={{ color: '#5C3826', fontWeight: 700 }}>BR-35 (Hết hạn): </strong>
                  Điểm tự động hết hạn và giảm trừ nếu tài khoản khách hàng không phát sinh bất kỳ giao dịch tích/tiêu điểm nào trong vòng <span style={{ fontWeight: 700, color: '#5C3826' }}>12 tháng liên tục</span>.
                </li>
                <li>
                  <strong style={{ color: '#5C3826', fontWeight: 700 }}>Quy đổi VND (BR-74): </strong>
                  Được tính toán bên ngoài thông qua giá trị hệ thống <span style={{ fontWeight: 700, color: '#5C3826' }}>LOYALTY_REDEMPTION_VALUE_PER_POINT</span> (mặc định 1 pt = 100 VND).
                </li>
              </ul>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
