import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { labourReport, formatNum, type LabourReport as LabourReportDto, type DateRange } from '../../api/reports';

/** Default date range: first day of current month -> today */
const defaultRange = (): DateRange => {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
};

/** UC-79 — labour hours vs revenue (non-monetary labour KPI). */
export default function LabourReport() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<LabourReportDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Load report data
  useEffect(() => {
    setLoading(true);
    setError('');
    labourReport(range)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range]);

  // Client-side CSV export
  const exportToCsv = () => {
    if (!data) return;
    const rows = [
      ['BÁO CÁO HIỆU SUẤT SỬ DỤNG NHÂN SỰ (LABOUR HOURS VS REVENUE)'],
      [`Từ ngày: ${range.from}`, `Đến ngày: ${range.to}`],
      [],
      ['Chi nhánh', 'Tổng giờ công (Labour Hrs)', 'Doanh thu thuần (Net Sales)', 'Giờ công / 1 triệu VND (Hrs / 1M VND)', 'Doanh thu / Giờ công (VND / Hr)'],
      ...data.branches.map(r => [
        r.storeName,
        `${r.labourHours} giờ`,
        `${r.netSales} VND`,
        r.hoursPerMillion,
        `${r.vndPerHour} VND`
      ])
    ];
    if (data.chainTotal) {
      rows.push([
        'Tổng toàn chuỗi (Chain total)',
        `${data.chainTotal.labourHours} giờ`,
        `${data.chainTotal.netSales} VND`,
        data.chainTotal.hoursPerMillion,
        `${data.chainTotal.vndPerHour} VND`
      ]);
    }

    const csvContent = "\uFEFF" + rows.map(e => e.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `nang_suat_lao_dong_${range.from}_to_${range.to}.csv`);
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
          HQ Admin Portal &rsaquo; Báo cáo &rsaquo; Labour Hours vs Revenue Report
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Hiệu Suất Sử Dụng Nhân Sự (Labour Hours vs Revenue)
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

      {/* Info Alert Banner */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        background: '#EEF4FF',
        border: '1px solid #C6D8F5',
        borderRadius: '8px',
        padding: '12px 17px',
        gap: '8px'
      }}>
        <span style={{ color: '#1C5FB0', fontWeight: 700, fontSize: '15px' }}>&#8505;</span>
        <span style={{ fontSize: '13px', color: '#1C5FB0', fontFamily: 'Roboto, sans-serif', lineHeight: '1.4' }}>
          Chỉ số năng suất lao động phi tiền tệ (không lưu thông tin tiền lương hoặc chi phí nhân sự thực tế, các khoản này được quản lý bởi hệ thống kế toán bên ngoài - §1.2).
        </span>
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
            Chỉ Số Hiệu Suất Từng Chi Nhánh (Labour Productivity - BR-76)
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ background: '#F9F6F3', height: '56.5px' }}>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Chi nhánh</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Tổng giờ công (Labour Hrs)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Doanh thu thuần (Net Sales)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Giờ công / 1 triệu VND (Hrs / 1M VND)</th>
                  <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Doanh thu / Giờ công (VND / Hr)</th>
                </tr>
              </thead>
              <tbody>
                {data.branches.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Không có dữ liệu trong kỳ.</td>
                  </tr>
                ) : data.branches.map((r) => {
                  const chainAvgHrsPerM = data.chainTotal?.hoursPerMillion || 0.01;
                  const chainAvgVndPerHr = data.chainTotal?.vndPerHour || 1;
                  
                  // Efficiency styling (better = green, worse = orange)
                  const isHrsPerMBetter = r.hoursPerMillion <= chainAvgHrsPerM;
                  const isVndPerHrBetter = r.vndPerHour >= chainAvgVndPerHr;

                  return (
                    <tr key={r.storeId} style={{ height: '61px', borderBottom: '1px solid #F5EEE8' }}>
                      <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                        {r.storeName}
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {formatNum(r.labourHours)} giờ
                      </td>
                      <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                        {formatNum(r.netSales)} VND
                      </td>
                      <td style={{
                        padding: '12px 16px',
                        color: isHrsPerMBetter ? '#2E7D32' : '#E65100',
                        textAlign: 'right',
                        fontFamily: 'Inter, sans-serif',
                        fontWeight: 600
                      }}>
                        {r.hoursPerMillion.toFixed(2)}
                      </td>
                      <td style={{
                        padding: '12px 16px',
                        color: isVndPerHrBetter ? '#2E7D32' : '#E65100',
                        textAlign: 'right',
                        fontFamily: 'Inter, sans-serif',
                        fontWeight: 600
                      }}>
                        {formatNum(r.vndPerHour)} VND
                      </td>
                    </tr>
                  );
                })}

                {/* Chain Total Row */}
                {data.chainTotal && (
                  <tr style={{ height: '45.5px', background: '#F9F6F3', borderTop: '2px solid #3D2314', borderBottom: '1px solid #EADDD3' }}>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                      Tổng toàn chuỗi (Chain total)
                    </td>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                      {formatNum(data.chainTotal.labourHours)} giờ
                    </td>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                      {formatNum(data.chainTotal.netSales)} VND
                    </td>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                      {data.chainTotal.hoursPerMillion.toFixed(2)}
                    </td>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, textAlign: 'right', fontFamily: 'Inter, sans-serif' }}>
                      {formatNum(data.chainTotal.vndPerHour)} VND
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div style={{
            marginTop: '15px',
            fontSize: '12px',
            color: '#8C766C',
            fontFamily: 'Roboto, sans-serif'
          }}>
            * Số giờ công được trích xuất từ dữ liệu điểm danh thực tế (BR-77). Doanh thu thuần là tổng Net Payable tích lũy trong cùng kỳ (BR-69).
          </div>
        </div>
      ) : null}
    </div>
  );
}
