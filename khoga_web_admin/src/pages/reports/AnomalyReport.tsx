import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { anomalyReport, formatNum, type AnomalyReport as AnomalyReportDto, type DateRange } from '../../api/reports';
import { listBranches, type Branch } from '../../api/branches';
import { useAuth } from '../../auth/AuthContext';

/** Default date range: first day of current month -> today */
const defaultRange = (): DateRange => {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
};

/** UC-82 — per-cashier void/refund anomaly with threshold flagging. */
export default function AnomalyReport() {
  const { user } = useAuth();
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<AnomalyReportDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [branches, setBranches] = useState<Branch[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState('');
  const [localThreshold, setLocalThreshold] = useState<number>(5.0);

  const isHqUser = user && ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN'].includes(user.role);

  // Load branch list
  useEffect(() => {
    listBranches(true)
      .then((res) => {
        setBranches(res);
        if (user && !isHqUser && user.storeId) {
          setSelectedBranchId(user.storeId);
        }
      })
      .catch(() => {});
  }, [user, isHqUser]);

  // Load report data
  useEffect(() => {
    setLoading(true);
    setError('');
    anomalyReport(range, selectedBranchId || undefined)
      .then((res) => {
        setData(res);
        if (res) {
          setLocalThreshold(res.thresholdPercent);
        }
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, selectedBranchId]);

  const activeBranchName = selectedBranchId 
    ? (branches.find(b => b.id === selectedBranchId)?.name || 'Chi nhánh')
    : 'Tất cả chi nhánh';

  // Client-side CSV export (using backend format but incorporating custom threshold)
  const exportToCsv = () => {
    if (!data) return;
    const rows = [
      ['BÁO CÁO BẤT THƯỜNG THỦY / HOÀN THEO THU NGÂN'],
      [`Từ ngày: ${range.from}`, `Đến ngày: ${range.to}`, `Chi nhánh: ${activeBranchName}`, `Ngưỡng: ${localThreshold}%`],
      [],
      ['Nhân viên thu ngân', 'Tổng số đơn hàng', 'Số đơn đã Hủy (Cancellations)', 'Tỉ lệ Hủy (%)', 'Số đơn Hoàn trả (Refunds)', 'Tỉ lệ Hoàn (%)', 'Voucher áp dụng', 'Món tặng (Comps)', 'Cảnh báo'],
      ...data.cashiers.map(c => {
        const flagged = c.cancelRate > localThreshold || c.refundRate > localThreshold;
        return [
          c.cashierName,
          c.orders,
          c.cancellations,
          `${c.cancelRate}%`,
          c.refunds,
          `${c.refundRate}%`,
          c.vouchers,
          c.comps,
          flagged ? `HIGH Alert (> ${localThreshold}%)` : 'Bình thường'
        ];
      })
    ];

    const csvContent = "\uFEFF" + rows.map(e => e.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `bat_thuong_thu_ngan_${range.from}_to_${range.to}.csv`);
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
          {isHqUser ? 'HQ Admin Portal' : 'Store Manager Portal'} &rsaquo; Báo cáo &rsaquo; Cashier Void / Refund Anomaly
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Báo Cáo Bất Thường Thu Ngân - {selectedBranchId ? `Chi nhánh ${activeBranchName}` : activeBranchName}
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
        {/* Quick select range */}
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

        {/* Date picking & Branch selector */}
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
            {isHqUser ? (
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
            ) : (
              <span style={{ fontSize: '14px', fontWeight: 700, color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                {activeBranchName} (Chỉ xem được chi nhánh trực thuộc - BR-44)
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Threshold Configurator Banner */}
      <div style={{
        background: '#FDFAF7',
        border: '1px solid #EADDD3',
        borderRadius: '8px',
        padding: '12px 20px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Settings gear / Shield icon */}
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#5C3826" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          <span style={{ fontSize: '14px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
            Cấu hình Ngưỡng Cảnh Báo An Toàn (CANCEL_REFUND_ALERT_THRESHOLD)
          </span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <input
            type="number"
            step="0.1"
            min="0.1"
            max="100"
            aria-label="Ngưỡng cảnh báo"
            value={localThreshold}
            onChange={(e) => setLocalThreshold(parseFloat(e.target.value) || 0)}
            style={{
              width: '68px',
              padding: '6px 8px',
              background: '#FFFFFF',
              border: '1px solid #EADDD3',
              borderRadius: '6px',
              fontSize: '14px',
              color: '#3D2314',
              outline: 'none',
              fontFamily: 'Inter, sans-serif',
              textAlign: 'center'
            }}
          />
          <span style={{ fontSize: '14px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
            % tổng số đơn
          </span>
        </div>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C', background: '#FFFFFF', borderRadius: '12px', border: '1px solid #EADDD3' }}>
          Đang tải…
        </div>
      ) : data ? (
        /* Main Card */
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
            Chi Tiết Hoạt Động Thu Ngân thuộc Chi nhánh (BR-79)
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ background: '#F9F6F3', height: '56.5px' }}>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Nhân viên thu ngân</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Tổng số đơn hàng</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Số đơn đã Hủy (Cancellations)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Số đơn Hoàn trả (Refunds)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Voucher áp dụng</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Món tặng (Comps)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3', paddingLeft: '24px' }}>Cảnh báo (Flag)</th>
                </tr>
              </thead>
              <tbody>
                {data.cashiers.length === 0 ? (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Không có dữ liệu trong kỳ.</td>
                  </tr>
                ) : data.cashiers.map((c) => {
                  // Determine flagged status dynamically from user threshold
                  const isFlagged = c.cancelRate > localThreshold || c.refundRate > localThreshold;

                  return (
                    <tr
                      key={c.cashierId}
                      style={{
                        height: '61px',
                        borderBottom: '1px solid #F5EEE8',
                        background: isFlagged ? '#FFF8F6' : 'transparent'
                      }}
                    >
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                        {c.cashierName} (Thu ngân)
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {formatNum(c.orders)}
                      </td>
                      <td style={{ padding: '12px 16px', color: '#000000', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        <span style={{ fontWeight: 700 }}>{c.cancellations}</span>
                        <span style={{ fontSize: '12px', color: '#8C766C', marginLeft: '4px' }}>({c.cancelRate}%)</span>
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {c.refunds} <span style={{ fontSize: '12px', color: '#8C766C' }}>({c.refundRate}%)</span>
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {formatNum(c.vouchers)}
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {formatNum(c.comps)}
                      </td>
                      <td style={{ padding: '12px 16px', textAlign: 'left', paddingLeft: '24px' }}>
                        {isFlagged ? (
                          <span style={{
                            display: 'inline-block',
                            padding: '4px 8px',
                            borderRadius: '4px',
                            background: '#FFEBEE',
                            color: '#C62828',
                            fontSize: '11px',
                            fontWeight: 700,
                            fontFamily: 'Roboto, sans-serif'
                          }}>
                            &alpha; HIGH cancel (&gt; {localThreshold}%)
                          </span>
                        ) : (
                          <span style={{ color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Bình thường</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div style={{
            marginTop: '15px',
            fontSize: '12px',
            color: '#D84315',
            fontWeight: 500,
            fontFamily: 'Roboto, sans-serif'
          }}>
            &#9888; Lưu ý: Phân tích hoạt động thu ngân giúp người quản lý chi nhánh đối chiếu dòng tiền ca kíp thực tế, ngăn ngừa các trường hợp gian lận hủy đơn sau khi nhận tiền mặt từ khách.
          </div>
        </div>
      ) : null}
    </div>
  );
}
