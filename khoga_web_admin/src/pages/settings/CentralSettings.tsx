import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { listGlobalConfig, updateGlobalConfig, type SystemConfigItem } from '../../api/systemConfig';
import { errorMessage } from '../../api/client';

// Friendly Vietnamese labels for the seeded GLOBAL keys (matches Figma screen 24).
// Unknown keys fall back to the raw key, so new backend config still renders.
const LABELS: Record<string, string> = {
  VAT_RATE: 'Thuế VAT mặc định (%)',
  LOYALTY_ACCRUAL_PERCENTAGE: 'Tỷ lệ tích lũy điểm (% trên tổng hóa đơn)',
  LOYALTY_REDEMPTION_VALUE_PER_POINT: 'Giá trị quy đổi điểm (VND/điểm)',
  LOYALTY_MAX_REDEMPTION_PERCENT: 'Tỷ lệ thanh toán bằng điểm tối đa (%)',
  LOYALTY_MAX_REDEMPTION_LIMIT: 'Số tiền giảm giá bằng điểm tối đa (VND/đơn)',
  MAX_ACTIVE_BRANCHES: 'Số chi nhánh hoạt động tối đa',
  HQ_MFA_REQUIRED: 'Bắt buộc MFA cho tài khoản HQ (true/false)',
  CANCEL_REFUND_ALERT_THRESHOLD: 'Ngưỡng cảnh báo hủy/hoàn đơn (%)',
};

/**
 * Screen 24 — "Cấu Hình & Bảo Mật Hệ Thống" (UC-24). Three cards: central chain-wide
 * config (editable), a shortcut to branch management, and admin password change.
 * Only changed keys are persisted (one PUT per dirty key).
 */
export default function CentralSettings() {
  const [items, setItems] = useState<SystemConfigItem[]>([]);
  const [values, setValues] = useState<Record<string, string>>({});
  const [original, setOriginal] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    listGlobalConfig()
      .then((cfgs) => {
        setItems(cfgs);
        const map = Object.fromEntries(cfgs.map((c) => [c.key, c.value]));
        setValues(map);
        setOriginal(map);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const handleSave = async () => {
    setError('');
    setSaved(false);
    setSaving(true);
    try {
      const changed = items.filter((it) => values[it.key] !== original[it.key]);
      for (const it of changed) {
        await updateGlobalConfig(it.key, values[it.key]);
      }
      setOriginal({ ...values });
      setSaved(true);
    } catch (e) {
      setError(errorMessage(e, 'Lưu cấu hình thất bại'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Cấu hình &amp; bảo mật hệ thống</h1>
        <p className="page-subtitle">Cấu hình toàn chuỗi</p>
      </div>

      <div className="settings-grid">
        <section className="form-card">
          <h2 className="section-title" style={{ marginTop: 0 }}>Cấu hình hệ thống trung tâm</h2>
          {error && <div className="alert alert--error">{error}</div>}
          {saved && <div className="alert alert--success">Đã lưu cấu hình.</div>}
          {loading ? (
            <p className="muted">Đang tải…</p>
          ) : (
            items.map((it) => (
              <div className="field" key={it.key}>
                <label className="label" htmlFor={`cfg-${it.key}`}>{LABELS[it.key] ?? it.key}</label>
                <input
                  id={`cfg-${it.key}`}
                  className="input"
                  value={values[it.key] ?? ''}
                  onChange={(e) => setValues((v) => ({ ...v, [it.key]: e.target.value }))}
                />
              </div>
            ))
          )}
          <div className="form-actions">
            <button type="button" className="btn btn--primary" onClick={handleSave} disabled={loading || saving}>
              {saving ? 'Đang lưu…' : 'Lưu cấu hình'}
            </button>
          </div>
        </section>

        <section className="form-card">
          <h2 className="section-title" style={{ marginTop: 0 }}>Quản lý hệ thống chi nhánh</h2>
          <p className="muted">
            Quản lý vòng đời hoạt động của các chi nhánh: thêm mới, cập nhật thông tin địa chỉ/điện thoại,
            hoặc tạm đóng cửa khi cần.
          </p>
          <p className="info-note">
            Giới hạn tối đa <strong>MAX_ACTIVE_BRANCHES</strong> chi nhánh hoạt động.
          </p>
          <Link to="/branches" className="btn btn--primary">Đi tới quản lý chi nhánh</Link>
        </section>

        <section className="form-card">
          <h2 className="section-title" style={{ marginTop: 0 }}>Đổi mật khẩu quản trị</h2>
          <p className="muted">Thay đổi mật khẩu của tài khoản quản trị đang đăng nhập.</p>
          <Link to="/profile/password" className="btn btn--primary">Đổi mật khẩu</Link>
        </section>
      </div>
    </div>
  );
}
