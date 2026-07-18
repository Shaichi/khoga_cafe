import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  listVouchers,
  deactivateVoucher,
  DISCOUNT_TYPE_LABELS,
  VOUCHER_STATUS_LABELS,
  type Voucher,
} from '../../api/vouchers';
import { errorMessage } from '../../api/client';

const fmtMoney = (n: number) => n.toLocaleString('vi-VN');

const fmtDate = (iso: string | null) => {
  if (!iso) return '—';
  const [y, m, d] = iso.slice(0, 10).split('-');
  return `${d}/${m}/${y}`;
};

const discountValueLabel = (v: Voucher) => {
  if (v.discountType === 'PERCENTAGE') {
    const cap = v.maxDiscountAmount != null ? ` (Tối đa ${fmtMoney(v.maxDiscountAmount)}đ)` : '';
    return `${v.discountValue}%${cap}`;
  }
  return `${fmtMoney(v.discountValue)} VND`;
};

const statusBadgeClass = (s: Voucher['status']) =>
  s === 'ACTIVE' ? 'badge--active' : s === 'SCHEDULED' ? 'badge--scheduled' : 'badge--inactive';

export default function VoucherList() {
  const [items, setItems] = useState<Voucher[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const load = () => {
    listVouchers()
      .then(setItems)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return items;
    return items.filter((v) => v.code.toLowerCase().includes(q));
  }, [items, search]);

  const deactivate = async (v: Voucher) => {
    if (!window.confirm(`Vô hiệu hóa voucher "${v.code}"? (ngừng áp dụng ngay lập tức)`)) return;
    setError('');
    try { await deactivateVoucher(v.id); load(); }
    catch (err) { setError(errorMessage(err)); }
  };

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <h1 className="page-title">Chương Trình Khuyến Mãi & Vouchers</h1>
          <p className="page-subtitle">Quản lý mã giảm giá toàn hệ thống.</p>
        </div>
        <Link to="/vouchers/new" className="btn btn--primary">+ Tạo Voucher Mới</Link>
      </div>

      <div className="toolbar">
        <input className="input toolbar__search" placeholder="Tìm theo mã voucher…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Mã Voucher</th><th>Loại Giảm Giá</th><th>Giá Trị Giảm</th><th>Đơn Tối Thiểu</th><th>Ngày Hết Hạn</th><th>Trạng Thái</th><th>Hành Động</th></tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} className="table__empty">Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={7} className="table__empty">Chưa có voucher nào.</td></tr>
            ) : filtered.map((v) => (
              <tr key={v.id}>
                <td style={{ fontWeight: 600 }}>{v.code}</td>
                <td>{DISCOUNT_TYPE_LABELS[v.discountType]}</td>
                <td>{discountValueLabel(v)}</td>
                <td>{v.minOrderValue != null ? `${fmtMoney(v.minOrderValue)} VND` : '—'}</td>
                <td>{fmtDate(v.endDate)}</td>
                <td><span className={`badge ${statusBadgeClass(v.status)}`}>{VOUCHER_STATUS_LABELS[v.status]}</span></td>
                <td>
                  <span className="actions-cell">
                    <Link to={`/vouchers/${v.id}/edit`} className="link-action">Sửa</Link>
                    {(v.status === 'ACTIVE' || v.status === 'SCHEDULED') && (
                      <button className="link-action link-action--danger" onClick={() => deactivate(v)}>Vô hiệu</button>
                    )}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
