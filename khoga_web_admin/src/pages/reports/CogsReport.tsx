import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { cogsReport, formatVnd, formatNum, type CogsReport as CogsReportDto, type DateRange } from '../../api/reports';
import { listBranches, type Branch } from '../../api/branches';

/** Default date range: first day of current month -> today */
const defaultRange = (): DateRange => {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
};

/** UC-76 — per-item standard-cost margin + ingredient shrinkage. */
export default function CogsReport() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [data, setData] = useState<CogsReportDto | null>(null);
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
    cogsReport(range, selectedBranchId || undefined)
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, selectedBranchId]);

  // Find selected branch name for CSV
  const selectedBranchName = selectedBranchId 
    ? branches.find(b => b.id === selectedBranchId)?.name || 'Chi nhánh'
    : 'Tất cả chi nhánh';

  // Client-side CSV export
  const exportToCsv = () => {
    if (!data) return;
    const rows = [
      ['BÁO CÁO COGS & HAO HỤT NGUYÊN LIỆU'],
      [`Từ ngày: ${range.from}`, `Đến ngày: ${range.to}`, `Chi nhánh: ${selectedBranchName}`],
      [],
      ['BIÊN LỢI NHUẬN TỪNG MÓN (Standard-cost COGS)'],
      ['Món ăn / Topping', 'Giá bán (VND)', 'COGS định mức (VND)', 'Lợi nhuận gộp (VND)', 'Tỷ suất LN gộp (%)', 'Trạng thái'],
      ...data.items.map(m => [
        m.name,
        m.price,
        m.cogs,
        m.margin,
        `${m.marginPercent}%`,
        m.marginPercent >= 50 ? 'Hiệu quả cao' : 'Biên thấp'
      ]),
      [],
      ['HAO HỤT NGUYÊN LIỆU (Thực tế kiểm kho vs Công thức)'],
      ['Nguyên liệu', 'Lý thuyết', 'Thực tế sử dụng', 'Chênh lệch (Hao hụt)', 'Giá trị hao hụt (VND)', 'Cảnh báo'],
      ...data.shrinkage.map(s => [
        `${s.name} (${s.unit})`,
        s.theoretical,
        s.actualUsage,
        s.variance,
        s.lossValue,
        s.flagged ? 'Vượt ngưỡng' : 'Bình thường'
      ])
    ];

    const csvContent = "\uFEFF" + rows.map(e => e.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `cogs_hao_hut_${range.from}_to_${range.to}.csv`);
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
          HQ Admin Portal &rsaquo; Báo cáo &rsaquo; COGS / Biên lợi nhuận & Hao hụt nguyên liệu
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Báo cáo COGS & Hao Hụt
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
        <div style={{ display: 'flex', flexDirection: 'column', gap: '30px' }}>
          {/* Table 1 Card: Biên lợi nhuận */}
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
              Biên Lợi Nhuận Từng Món (Standard-cost COGS &mdash; BR-66)
            </div>

            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                <thead>
                  <tr style={{ background: '#F9F6F3', height: '40.5px' }}>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Món ăn / Topping</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Giá bán (VND)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>COGS định mức (VND)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Lợi nhuận gộp (VND)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Tỷ suất LN gộp (%)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3', paddingLeft: '24px' }}>Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  {data.items.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Chưa có món nào.</td>
                    </tr>
                  ) : data.items.map((m) => {
                    const isHigh = m.marginPercent >= 50;
                    const raw = m as any;
                    const price = m.price ?? (raw.revenue / (raw.soldQuantity || 1));
                    const cogsVal = m.cogs ?? 0;
                    const marginVal = m.margin ?? 0;
                    const key = m.itemId ?? raw.menuItemId ?? m.name;
                    const safeFormat = (val: any) => formatNum(val || 0);
                    return (
                      <tr key={key} style={{ height: '49px', borderBottom: '1px solid #F5EEE8' }}>
                        <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>{m.name}</td>
                        <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif' }}>{safeFormat(price)}</td>
                        <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif' }}>{safeFormat(cogsVal)}</td>
                        <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif', fontWeight: 600 }}>{safeFormat(marginVal)}</td>
                        <td style={{ padding: '12px 16px', color: '#2E7D32', textAlign: 'right', fontFamily: 'Roboto, sans-serif', fontWeight: 600 }}>{m.marginPercent}%</td>
                        <td style={{ padding: '12px 16px', textAlign: 'left', paddingLeft: '24px' }}>
                          <span style={{
                            display: 'inline-block',
                            padding: '4px 8px',
                            borderRadius: '4px',
                            background: isHigh ? '#E8F5E9' : '#FFF3E0',
                            color: isHigh ? '#2E7D32' : '#E65100',
                            fontSize: '11px',
                            fontWeight: 700,
                            fontFamily: 'Roboto, sans-serif'
                          }}>
                            {isHigh ? 'Hiệu quả cao' : 'Biên thấp'}
                          </span>
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
              color: '#8C766C',
              fontFamily: 'Roboto, sans-serif'
            }}>
              * COGS định mức được tính dựa trên giá vốn tiêu chuẩn (standard_cost) khai báo trong danh mục nguyên liệu master (BR-66).
            </div>
          </div>

          {/* Table 2 Card: Hao hụt */}
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
              Hao Hụt Nguyên Liệu (Hao hụt định thuyết vs Thực tế kiểm kho @ Standard Cost)
            </div>

            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                <thead>
                  <tr style={{ background: '#F9F6F3', height: '56.5px' }}>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Nguyên liệu</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Tiêu thụ thuyết tính (Recipe)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Thực tế sử dụng (Audited)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Chênh lệch (Hao hụt)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'right', borderBottom: '1px solid #EADDD3' }}>Giá trị hao hụt (VND)</th>
                    <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3', paddingLeft: '24px' }}>Cảnh báo</th>
                  </tr>
                </thead>
                <tbody>
                  {data.shrinkage.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Không có biến động kho trong kỳ.</td>
                    </tr>
                  ) : data.shrinkage.map((s) => {
                    const isLoss = s.variance < 0;
                    return (
                      <tr key={s.rawMaterialId} style={{ height: '61px', borderBottom: '1px solid #F5EEE8' }}>
                        <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                          {s.name}
                        </td>
                        <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif' }}>
                          {formatNum(s.theoretical)} {s.unit}
                        </td>
                        <td style={{ padding: '12px 16px', color: '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif' }}>
                          {formatNum(s.actualUsage)} {s.unit}
                        </td>
                        <td style={{ padding: '12px 16px', color: isLoss ? '#C62828' : '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif', fontWeight: 600 }}>
                          {isLoss ? '' : '+'}{formatNum(s.variance)} {s.unit}
                        </td>
                        <td style={{ padding: '12px 16px', color: isLoss ? '#C62828' : '#3D2314', textAlign: 'right', fontFamily: 'Roboto, sans-serif', fontWeight: 600 }}>
                          {formatNum(s.lossValue)}
                        </td>
                        <td style={{ padding: '12px 16px', textAlign: 'left', paddingLeft: '24px' }}>
                          {s.flagged ? (
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
                              (!) Vượt ngưỡng
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
              color: '#8C766C',
              fontFamily: 'Roboto, sans-serif'
            }}>
              * Chênh lệch hao hụt được đối chiếu giữa lượng nguyên liệu trừ đi theo công thức pha chế (UC-62) và lượng kiểm kê thực tế tại chi nhánh (UC-34).
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
