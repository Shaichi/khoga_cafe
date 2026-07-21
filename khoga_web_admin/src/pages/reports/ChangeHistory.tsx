import { useEffect, useState } from 'react';
import { errorMessage } from '../../api/client';
import { priceHistory, type AuditChangeRow, type DateRange } from '../../api/reports';
import type { PageResponse } from '../../api/types';
import { listUsers, type User } from '../../api/users';
import { entityLabel, formatTs } from './auditLabels';

/** Helper to format old/new audit values */
const formatValue = (val: string | null, entity: string, action: string) => {
  if (!val) {
    if (action === 'CREATE') return '(Chưa tạo)';
    return '—';
  }
  
  const trimmed = val.trim();
  if (trimmed.startsWith('{')) {
    try {
      const parsed = JSON.parse(trimmed);
      
      if (parsed.price !== undefined) {
        return `${Number(parsed.price).toLocaleString('vi-VN')} đ`;
      }
      
      if (parsed.discountType !== undefined || parsed.discountValue !== undefined) {
        if (parsed.discountType === 'PERCENTAGE') {
          const limitStr = parsed.maxDiscountAmount 
            ? ` / tối đa ${Number(parsed.maxDiscountAmount) >= 1000 ? (Number(parsed.maxDiscountAmount) / 1000) + 'k' : Number(parsed.maxDiscountAmount)}`
            : '';
          return `Giảm ${parsed.discountValue}%${limitStr}`;
        }
        return `Giảm ${Number(parsed.discountValue).toLocaleString('vi-VN')} đ`;
      }
      
      if (parsed.active !== undefined) {
        return parsed.active ? 'Trạng thái: Hoạt động' : 'Đã hủy kích hoạt (Deactivated)';
      }
      
      if (parsed.event) {
        switch (parsed.event) {
          case 'LOGIN': return 'Đăng nhập';
          case 'LOGOUT': return 'Đăng xuất';
          case 'PASSWORD_RESET': return 'Reset mật khẩu';
          case 'FORCE_PASSWORD_CHANGE': return 'Yêu cầu đổi mật khẩu';
          case 'PASSWORD_CHANGE': return 'Đổi mật khẩu';
          default: return parsed.event;
        }
      }
      
      if (parsed.code) return parsed.code;
      if (parsed.name) return parsed.name;
      
      return Object.entries(parsed)
        .map(([k, v]) => `${k}: ${v}`)
        .join(', ');
    } catch {
      return val;
    }
  }
  
  if (val === 'CREATE') return '(Chưa tạo)';
  if (val === 'DEACTIVATE') return 'Đã hủy kích hoạt (Deactivated)';
  
  if (!Number.isNaN(Number(val))) {
    if (entity === 'MenuItem') {
      return `${Number(val).toLocaleString('vi-VN')} đ`;
    }
    return Number(val).toLocaleString('vi-VN');
  }
  
  return val;
};

/** Helper to generate target descriptive labels */
const getTargetLabel = (r: AuditChangeRow) => {
  const baseLabel = entityLabel(r.entity);
  let detail = '';
  
  if (r.oldValue && r.oldValue.trim().startsWith('{')) {
    try {
      const parsed = JSON.parse(r.oldValue);
      if (parsed.name) detail = `: ${parsed.name}`;
      else if (parsed.code) detail = `: ${parsed.code}`;
    } catch {}
  }
  
  if (!detail && r.newValue && r.newValue.trim().startsWith('{')) {
    try {
      const parsed = JSON.parse(r.newValue);
      if (parsed.name) detail = `: ${parsed.name}`;
      else if (parsed.code) detail = `: ${parsed.code}`;
    } catch {}
  }

  const cleanLabel = baseLabel === 'Món ăn' ? 'Giá món' : baseLabel === 'Voucher' ? 'Mã Voucher' : baseLabel;
  return `${cleanLabel}${detail}`;
};

/** Default date range: first day of current month -> today */
const defaultRange = (): DateRange => {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
};

/** UC-77 — read-only price & voucher change history from the audit log. */
export default function ChangeHistory() {
  const [range, setRange] = useState<DateRange>(defaultRange);
  const [type, setType] = useState('ALL');
  const [page, setPage] = useState(0);
  const [data, setData] = useState<PageResponse<AuditChangeRow> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [selectedActorId, setSelectedActorId] = useState('');
  const [search, setSearch] = useState('');

  // Load user list for filtering
  useEffect(() => {
    listUsers()
      .then(setUsers)
      .catch(() => {});
  }, []);

  // Load history data
  useEffect(() => {
    setLoading(true);
    setError('');
    priceHistory(range, { type, actorId: selectedActorId || undefined, page })
      .then(setData)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [range, type, selectedActorId, page]);

  // Client-side search filtering
  const filteredContent = data?.content.filter(r => {
    const q = search.toLowerCase();
    if (!q) return true;
    const actor = (r.actor || '').toLowerCase();
    const entity = getTargetLabel(r).toLowerCase();
    const oldVal = formatValue(r.oldValue, r.entity, r.action).toLowerCase();
    const newVal = formatValue(r.newValue, r.entity, r.action).toLowerCase();
    return actor.includes(q) || entity.includes(q) || oldVal.includes(q) || newVal.includes(q);
  }) || [];

  // Client-side CSV export
  const exportToCsv = () => {
    if (!data || filteredContent.length === 0) return;
    const headers = ['Thời điểm', 'Người thực hiện', 'Thực thể thay đổi', 'Giá trị cũ', 'Giá trị mới'];
    const rows = filteredContent.map(r => [
      formatTs(r.timestamp),
      r.actor,
      getTargetLabel(r),
      formatValue(r.oldValue, r.entity, r.action),
      formatValue(r.newValue, r.entity, r.action)
    ]);
    
    const csvContent = "\uFEFF" + [headers.join(','), ...rows.map(e => e.map(val => `"${val.replace(/"/g, '""')}"`).join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `nhat_ky_thay_doi_gia_voucher_${range.from}_to_${range.to}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {error && <div className="alert alert--error">{error}</div>}
      {/* Header Area */}
      <div>
        <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontFamily: 'Roboto, sans-serif' }}>
          HQ Admin Portal &rsaquo; Báo cáo &rsaquo; Lịch sử thay đổi Giá & Voucher
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#3D2314', margin: 0, fontFamily: 'Roboto, sans-serif' }}>
            Nhật Ký Thay Đổi Giá & Voucher
          </h1>
          <button
            type="button"
            onClick={exportToCsv}
            disabled={!data || filteredContent.length === 0}
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
              cursor: !data || filteredContent.length === 0 ? 'not-allowed' : 'pointer',
              opacity: !data || filteredContent.length === 0 ? 0.6 : 1,
              fontFamily: 'Inter, sans-serif'
            }}
          >
            Xuất Báo Cáo
          </button>
        </div>
      </div>

      {/* Yellow Warning Banner */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        background: '#FFFDE7',
        border: '1px solid #FFF59D',
        borderRadius: '8px',
        padding: '12px 17px',
        gap: '8px'
      }}>
        <span style={{ color: '#F57F17', fontWeight: 700, fontSize: '15px' }}>&#9888;</span>
        <span style={{ fontSize: '13px', color: '#F57F17', fontFamily: 'Roboto, sans-serif' }}>
          Thông tin được trích xuất từ <strong style={{ fontWeight: 700 }}>AUDIT_LOG</strong> bất biến toàn hệ thống (BR-68). Không thể sửa đổi hoặc xóa các bản ghi này.
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
        {/* Entity Quick Filters */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {[
            { id: 'ALL', label: 'Tất cả thực thể' },
            { id: 'PRICE', label: 'Menu Giá' },
            { id: 'VOUCHER', label: 'Vouchers' }
          ].map((btn) => {
            const active = type === btn.id;
            return (
              <button
                key={btn.id}
                type="button"
                onClick={() => { setPage(0); setType(btn.id); }}
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

        {/* Date Filters & Actor Dropdown */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Từ:</span>
            <input
              type="date"
              aria-label="Từ ngày"
              value={range.from}
              max={range.to}
              onChange={(e) => { setPage(0); setRange(r => ({ ...r, from: e.target.value })); }}
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
              onChange={(e) => { setPage(0); setRange(r => ({ ...r, to: e.target.value })); }}
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
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>Người thực hiện:</span>
            <select
              aria-label="Người thực hiện"
              value={selectedActorId}
              onChange={(e) => { setPage(0); setSelectedActorId(e.target.value); }}
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
              {users.map(u => (
                <option key={u.id} value={u.id}>{u.fullName} ({u.username})</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Main Table Card */}
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
        {/* Search Input */}
        <input
          type="text"
          placeholder="Tìm kiếm theo tên món, mã voucher, người thực hiện..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            width: '100%',
            padding: '10px 16px',
            border: '1px solid #EADDD3',
            borderRadius: '8px',
            fontSize: '14px',
            outline: 'none',
            fontFamily: 'Inter, sans-serif'
          }}
        />

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
            <thead>
              <tr style={{ background: '#F9F6F3', height: '40.5px' }}>
                <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Thời gian</th>
                <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Người thực hiện (Actor)</th>
                <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Thực thể thay đổi (Entity)</th>
                <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Giá trị cũ (Old Value)</th>
                <th style={{ padding: '12px 16px', fontFamily: 'Roboto, sans-serif', fontWeight: 600, fontSize: '14px', color: '#5C3826', textAlign: 'left', borderBottom: '1px solid #EADDD3' }}>Giá trị mới (New Value)</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Đang tải…</td>
                </tr>
              ) : filteredContent.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Không có thay đổi trong kỳ.</td>
                </tr>
              ) : filteredContent.map((r) => {
                const oldValText = formatValue(r.oldValue, r.entity, r.action);
                const newValText = formatValue(r.newValue, r.entity, r.action);
                const isDeactivated = newValText.includes('Deactivated') || newValText.includes('đã xóa');

                return (
                  <tr key={r.id} style={{ height: '45px', borderBottom: '1px solid #F5EEE8' }}>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
                      {formatTs(r.timestamp)}
                    </td>
                    <td style={{ padding: '12px 16px', color: '#5C3826', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                      {r.actor}
                    </td>
                    <td style={{ padding: '12px 16px', color: '#3D2314', fontWeight: 700, fontFamily: 'Roboto, sans-serif' }}>
                      {getTargetLabel(r)}
                    </td>
                    <td style={{ padding: '12px 16px', color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>
                      {oldValText}
                    </td>
                    <td style={{
                      padding: '12px 16px',
                      color: isDeactivated ? '#C62828' : '#2E7D32',
                      fontWeight: 600,
                      fontFamily: 'Roboto, sans-serif'
                    }}>
                      {newValText}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Footer / Pagination */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          paddingTop: '16px',
          borderTop: '1px solid #EADDD3',
          fontSize: '14px',
          color: '#8C766C'
        }}>
          <span>
            Đang hiển thị bản ghi {filteredContent.length > 0 ? 1 : 0} - {filteredContent.length} của {filteredContent.length}
          </span>
          {data && data.totalPages > 1 && (
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                type="button"
                disabled={page <= 0}
                onClick={() => setPage((p) => p - 1)}
                style={{
                  padding: '6px 14px',
                  background: '#FFFFFF',
                  border: '1px solid #EADDD3',
                  borderRadius: '6px',
                  color: '#3D2314',
                  cursor: page <= 0 ? 'not-allowed' : 'pointer',
                  opacity: page <= 0 ? 0.6 : 1,
                  fontFamily: 'Inter, sans-serif'
                }}
              >
                &lt; Trước
              </button>
              <button
                type="button"
                disabled={page >= data.totalPages - 1}
                onClick={() => setPage((p) => p + 1)}
                style={{
                  padding: '6px 14px',
                  background: '#FFFFFF',
                  border: '1px solid #EADDD3',
                  borderRadius: '6px',
                  color: '#3D2314',
                  cursor: page >= data.totalPages - 1 ? 'not-allowed' : 'pointer',
                  opacity: page >= data.totalPages - 1 ? 0.6 : 1,
                  fontFamily: 'Inter, sans-serif'
                }}
              >
                Sau &gt;
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
