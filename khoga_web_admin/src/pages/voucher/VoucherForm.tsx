import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  createVoucher,
  getVoucher,
  updateVoucher,
  type DiscountType,
  type CreateVoucherInput,
  type UpdateVoucherInput,
} from '../../api/vouchers';
import { errorMessage } from '../../api/client';

const numOrNull = (s: string): number | null => (s.trim() === '' ? null : Number(s));
// BE expects LocalDateTime; <input type="date"> gives YYYY-MM-DD.
const toStart = (d: string): string | null => (d ? `${d}T00:00:00` : null);
const toEnd = (d: string): string | null => (d ? `${d}T23:59:59` : null);
const datePart = (iso: string | null): string => (iso ? iso.slice(0, 10) : '');

export default function VoucherForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [code, setCode] = useState('');
  const [discountType, setDiscountType] = useState<DiscountType | ''>('');
  const [discountValue, setDiscountValue] = useState('');
  const [maxDiscount, setMaxDiscount] = useState('');
  const [minOrder, setMinOrder] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [perCustomer, setPerCustomer] = useState('');
  const [maxTotal, setMaxTotal] = useState('');
  const [active, setActive] = useState(true);

  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const isPercentage = discountType === 'PERCENTAGE';

  useEffect(() => {
    if (!id) return;
    getVoucher(id)
      .then((v) => {
        setCode(v.code);
        setDiscountType(v.discountType);
        setDiscountValue(v.discountValue?.toString() ?? '');
        setMaxDiscount(v.maxDiscountAmount?.toString() ?? '');
        setMinOrder(v.minOrderValue?.toString() ?? '');
        setStartDate(datePart(v.startDate));
        setEndDate(datePart(v.endDate));
        setPerCustomer(v.usageLimitPerCustomer?.toString() ?? '');
        setMaxTotal(v.maxTotalUses?.toString() ?? '');
        setActive(v.status !== 'INACTIVE');
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!discountType) { setError('Vui lòng chọn loại chiết khấu'); return; }
    if (isPercentage && maxDiscount.trim() === '') {
      setError('Voucher giảm theo phần trăm phải có mức giảm tối đa (BR-42)');
      return;
    }
    const base = {
      discountType,
      discountValue: Number(discountValue),
      minOrderValue: numOrNull(minOrder),
      startDate: toStart(startDate),
      endDate: toEnd(endDate),
      maxDiscountAmount: isPercentage ? numOrNull(maxDiscount) : null,
      usageLimitPerCustomer: numOrNull(perCustomer),
      maxTotalUses: numOrNull(maxTotal),
    };
    setSubmitting(true);
    try {
      if (isEdit && id) {
        const input: UpdateVoucherInput = { ...base, active };
        await updateVoucher(id, input);
      } else {
        const input: CreateVoucherInput = { code, ...base };
        await createVoucher(input);
      }
      navigate('/vouchers');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="full-center">Đang tải…</div>;

  return (
    <div>
      <div className="page-head">
        <Link to="/vouchers" className="back-link">← Vouchers</Link>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Chiến Dịch Voucher' : 'Tạo Voucher Mới'}</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label">Mã Voucher (Alphanumeric) *</label>
          <input className="input" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())}
            placeholder="Ví dụ: SUMMER50K" required disabled={isEdit} />
          {isEdit && <p className="hint">Mã voucher là bất biến sau khi tạo (BR-40).</p>}
        </div>

        <div className="field">
          <label className="label">Loại chiết khấu *</label>
          <select className="input" value={discountType} onChange={(e) => setDiscountType(e.target.value as DiscountType | '')} required>
            <option value="">— Chọn loại</option>
            <option value="PERCENTAGE">Giảm theo phần trăm (%)</option>
            <option value="FIXED_AMOUNT">Số tiền mặt cố định</option>
          </select>
        </div>

        <div className="field">
          <label className="label">Giá trị giảm *</label>
          <input className="input" type="number" step="any" min="0" value={discountValue}
            onChange={(e) => setDiscountValue(e.target.value)} placeholder="Ví dụ: 15 hoặc 15000" required />
        </div>

        {isPercentage && (
          <div className="field">
            <label className="label">Mức giảm tối đa (VND) *</label>
            <input className="input" type="number" step="any" min="0" value={maxDiscount}
              onChange={(e) => setMaxDiscount(e.target.value)} placeholder="Ví dụ: 30000" />
            <p className="hint">Bắt buộc với voucher giảm theo phần trăm (BR-42).</p>
          </div>
        )}

        <div className="field">
          <label className="label">Giá trị đơn hàng tối thiểu (VND)</label>
          <input className="input" type="number" step="any" min="0" value={minOrder}
            onChange={(e) => setMinOrder(e.target.value)} placeholder="Ví dụ: 50000" />
        </div>

        <div className="form-row">
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Hạn hiệu lực — Ngày bắt đầu</label>
            <input className="input" type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Hạn hiệu lực — Ngày hết hạn</label>
            <input className="input" type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
        </div>

        {isEdit && (
          <div className="field">
            <label className="label">Trạng thái hoạt động</label>
            <select className="input" value={active ? 'true' : 'false'} onChange={(e) => setActive(e.target.value === 'true')}>
              <option value="true">Đang áp dụng</option>
              <option value="false">Vô hiệu hóa</option>
            </select>
          </div>
        )}

        <div className="form-row">
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Giới hạn lượt dùng / khách</label>
            <input className="input" type="number" min="0" step="1" value={perCustomer}
              onChange={(e) => setPerCustomer(e.target.value)} placeholder="Ví dụ: 1" />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Tổng lượt dùng tối đa</label>
            <input className="input" type="number" min="0" step="1" value={maxTotal}
              onChange={(e) => setMaxTotal(e.target.value)} placeholder="Ví dụ: 100" />
          </div>
        </div>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : isEdit ? 'Lưu Thay Đổi' : 'Tạo Voucher'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/vouchers')}>Hủy bỏ</button>
        </div>
      </form>
    </div>
  );
}
