import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  createCustomer,
  getCustomer,
  updateCustomer,
  adjustPoints,
  tierFromPoints,
  CONSENT_VERSION,
  type Customer,
} from '../../api/customers';
import { errorMessage } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import { tierBadgeClass } from './CustomerList';

const fmtDate = (iso: string | null) => {
  if (!iso) return '—';
  const [y, m, d] = iso.slice(0, 10).split('-');
  return `${d}/${m}/${y}`;
};

export default function CustomerForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();
  const { user } = useAuth();
  const canAdjustPoints = user?.role === 'SSADMIN' || user?.role === 'BUSINESSADMIN';

  const [existing, setExisting] = useState<Customer | null>(null);
  const [phone, setPhone] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [consent, setConsent] = useState(false);

  // Point adjustment (edit only) — newPoints is the absolute target; delta is computed.
  const [newPoints, setNewPoints] = useState('');
  const [reason, setReason] = useState('');

  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    getCustomer(id)
      .then((c) => {
        setExisting(c);
        setPhone(c.phone);
        setFullName(c.fullName);
        setEmail(c.email ?? '');
        setNewPoints((c.points ?? 0).toString());
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const currentPoints = existing?.points ?? 0;
  const tier = tierFromPoints(isEdit ? currentPoints : 0);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    if (!isEdit && !consent) {
      setError('Cần xác nhận khách hàng đồng ý xử lý dữ liệu (PDPA) trước khi tạo hồ sơ.');
      return;
    }

    const pointsChanged = isEdit && canAdjustPoints && Number(newPoints) !== currentPoints;
    if (pointsChanged && reason.trim() === '') {
      setError('Phải nhập lý do khi điều chỉnh điểm tích lũy.');
      return;
    }

    setSubmitting(true);
    try {
      if (isEdit && id) {
        await updateCustomer(id, { fullName, email: email || undefined });
        if (pointsChanged) {
          await adjustPoints(id, { delta: Number(newPoints) - currentPoints, reason: reason.trim() });
        }
      } else {
        await createCustomer({ phone, fullName, email: email || undefined, consentVersion: CONSENT_VERSION });
      }
      navigate('/customers');
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
        <p className="breadcrumb">
          <Link to="/customers">Khách hàng</Link>
          {isEdit ? <> › {existing?.fullName} › Chỉnh sửa</> : <> › Thêm mới</>}
        </p>
        <h1 className="page-title">{isEdit ? 'Chỉnh Sửa Thông Tin Khách Hàng' : 'Đăng Ký Thành Viên Mới'}</h1>
      </div>

      <form className="form-card form-card--wide" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="info-panel">
          <div className="info-panel__stat">
            <span className="info-panel__label">{isEdit ? 'Hạng thành viên' : 'Hạng mặc định'}</span>
            <span className={`badge ${tierBadgeClass(tier)}`} style={{ alignSelf: 'flex-start' }}>{tier}</span>
          </div>
          <div className="info-panel__stat">
            <span className="info-panel__label">{isEdit ? 'Điểm tích lũy' : 'Điểm khởi tạo'}</span>
            <span className="info-panel__value">{isEdit ? `${currentPoints.toLocaleString('vi-VN')} điểm` : '0 điểm'}</span>
          </div>
          <div className="info-panel__stat">
            <span className="info-panel__label">Ngày đăng ký</span>
            <span className="info-panel__value">{isEdit ? fmtDate(existing?.consentAt ?? null) : 'Hôm nay'}</span>
          </div>
        </div>

        <div className="form-row">
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Họ và tên *</label>
            <input className="input" value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Nhập họ và tên khách hàng" required />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label className="label">Số điện thoại *</label>
            <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)}
              placeholder="Nhập số điện thoại (10-12 chữ số)" required disabled={isEdit}
              pattern="[0-9]{10,12}" inputMode="numeric" />
            {isEdit && <p className="hint">Số điện thoại là định danh, không thể thay đổi.</p>}
          </div>
        </div>

        <div className="field">
          <label className="label">Email liên hệ <span className="muted">(tùy chọn)</span></label>
          <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="example@email.com" />
        </div>

        {!isEdit && (
          <label className="checkbox-row">
            <input type="checkbox" checked={consent} onChange={(e) => setConsent(e.target.checked)} />
            <span>Khách hàng đồng ý cho phép thu thập & xử lý dữ liệu cá nhân (PDPA).</span>
          </label>
        )}

        {isEdit && canAdjustPoints && (
          <>
            <hr className="divider" />
            <div className="adjust-head">
              <span className="section-title" style={{ margin: 0 }}>Điều chỉnh điểm thành viên</span>
              <span className="badge badge--gold">CHỈ ADMIN</span>
            </div>
            <div className="form-row">
              <div className="field" style={{ flex: 1 }}>
                <label className="label">Điểm tích lũy mới</label>
                <input className="input" type="number" min="0" step="1" value={newPoints} onChange={(e) => setNewPoints(e.target.value)} />
              </div>
              <div className="field" style={{ flex: 1 }}>
                <label className="label">Lý do điều chỉnh <span className="muted">(bắt buộc nếu thay đổi)</span></label>
                <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Ví dụ: Xử lý tranh chấp, Hoàn điểm lỗi hệ thống…" />
              </div>
            </div>
          </>
        )}

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : isEdit ? 'Lưu thay đổi' : 'Tạo tài khoản'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/customers')}>Hủy bỏ</button>
        </div>
      </form>
    </div>
  );
}
