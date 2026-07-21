import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { listGlobalConfig, updateGlobalConfig } from '../../api/systemConfig';
import { changePassword } from '../../api/auth';
import { errorMessage } from '../../api/client';

// Exact 6 fields in Figma node 409-5 design
const FIGMA_KEYS = [
  'VAT_RATE',
  'LOYALTY_ACCRUAL_PERCENTAGE',
  'LOYALTY_REDEMPTION_VALUE_PER_POINT',
  'LOYALTY_MAX_REDEMPTION_PERCENT',
  'LOYALTY_MAX_REDEMPTION_LIMIT',
  'AUTO_LOGOUT_MINUTES',
];

const CONFIG_FIELDS: Record<string, { label: string; defaultValue: string }> = {
  VAT_RATE: { label: 'Thuế VAT mặc định (%)', defaultValue: '10' },
  LOYALTY_ACCRUAL_PERCENTAGE: { label: 'Tỷ lệ tích lũy điểm (% trên tổng hóa đơn)', defaultValue: '1.0' },
  LOYALTY_REDEMPTION_VALUE_PER_POINT: { label: 'Giá trị quy đổi điểm (VND/điểm)', defaultValue: '100' },
  LOYALTY_MAX_REDEMPTION_PERCENT: { label: 'Tỷ lệ thanh toán bằng điểm tối đa (%)', defaultValue: '50' },
  LOYALTY_MAX_REDEMPTION_LIMIT: { label: 'Số tiền giảm giá bằng điểm tối đa (VND/đơn)', defaultValue: '100000' },
  AUTO_LOGOUT_MINUTES: { label: 'Thời gian tự động đăng xuất (Phút)', defaultValue: '30' },
};

export default function CentralSettings() {
  // Config state
  const [values, setValues] = useState<Record<string, string>>({});
  const [original, setOriginal] = useState<Record<string, string>>({});
  const [loadingConfig, setLoadingConfig] = useState(true);
  const [configError, setConfigError] = useState('');
  const [savingConfig, setSavingConfig] = useState(false);
  const [configSuccess, setConfigSuccess] = useState(false);

  // Change Password State
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [passwordSuccess, setPasswordSuccess] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);

  useEffect(() => {
    listGlobalConfig()
      .then((cfgs) => {
        const map: Record<string, string> = {};
        FIGMA_KEYS.forEach((key) => {
          const found = cfgs.find((c) => c.key === key);
          map[key] = found ? found.value : CONFIG_FIELDS[key].defaultValue;
        });
        setValues(map);
        setOriginal(map);
      })
      .catch((e) => setConfigError(errorMessage(e)))
      .finally(() => setLoadingConfig(false));
  }, []);

  const handleSaveConfig = async (e: FormEvent) => {
    e.preventDefault();
    setConfigError('');
    setConfigSuccess(false);
    setSavingConfig(true);
    try {
      const changedKeys = FIGMA_KEYS.filter((key) => values[key] !== original[key]);
      for (const key of changedKeys) {
        await updateGlobalConfig(key, values[key]);
      }
      setOriginal({ ...values });
      setConfigSuccess(true);
    } catch (e) {
      setConfigError(errorMessage(e, 'Lưu cấu hình thất bại'));
    } finally {
      setSavingConfig(false);
    }
  };

  const handleChangePassword = async (e: FormEvent) => {
    e.preventDefault();
    setPasswordError('');
    setPasswordSuccess(false);

    if (!currentPassword) {
      setPasswordError('Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    if (newPassword.length < 8) {
      setPasswordError('Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError('Xác nhận mật khẩu mới không khớp');
      return;
    }

    setSavingPassword(true);
    try {
      await changePassword(currentPassword, newPassword);
      setPasswordSuccess(true);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (e) {
      setPasswordError(errorMessage(e, 'Đổi mật khẩu thất bại'));
    } finally {
      setSavingPassword(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px', width: '100%', fontFamily: 'Roboto, Segoe UI, sans-serif' }}>
      
      {/* ── Page Header (#409:17) ── */}
      <div
        style={{
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '16px',
          width: '100%',
        }}
      >
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11', fontFamily: 'Roboto, sans-serif' }}>
          Cấu Hình &amp; Bảo Mật Hệ Thống
        </h1>
      </div>

      {/* ── 3 Column Cards Grid (Figma #409:19) ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '24px', width: '100%', alignItems: 'flex-start' }}>
        
        {/* ── Card 1: Cấu Hình Hệ Thống Trung Tâm (#409:20) ── */}
        <form
          onSubmit={handleSaveConfig}
          style={{
            width: '100%',
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '31px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            display: 'flex',
            flexDirection: 'column',
            gap: '20px',
            boxSizing: 'border-box',
          }}
        >
          {/* Header (#409:21) */}
          <div
            style={{
              borderBottom: '1px solid #F2EDE8',
              paddingBottom: '12px',
            }}
          >
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#3D2314' }}>
              Cấu Hình Hệ Thống Trung Tâm
            </h2>
          </div>

          {configError && <div className="alert alert--error">{configError}</div>}
          {configSuccess && <div className="alert alert--success">Đã lưu cấu hình thành công.</div>}

          {loadingConfig ? (
            <div style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Đang tải cấu hình…</div>
          ) : (
            FIGMA_KEYS.map((key) => (
              <div key={key} style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <label
                  htmlFor={`cfg-${key}`}
                  style={{ fontSize: '15px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}
                >
                  {CONFIG_FIELDS[key].label}
                </label>
                <input
                  id={`cfg-${key}`}
                  type="text"
                  value={values[key] ?? ''}
                  onChange={(e) => setValues((v) => ({ ...v, [key]: e.target.value }))}
                  style={{
                    width: '100%',
                    height: '42px',
                    padding: '0 12px',
                    background: '#FFFFFF',
                    border: '1px solid #E5DBCF',
                    borderRadius: '8px',
                    fontSize: '15px',
                    color: '#2C1A11',
                    outline: 'none',
                    boxSizing: 'border-box',
                    fontFamily: 'Inter, sans-serif',
                  }}
                />
              </div>
            ))
          )}

          {/* Submit Button (#409:47) */}
          <button
            type="submit"
            disabled={loadingConfig || savingConfig}
            style={{
              width: '100%',
              height: '39px',
              background: '#3D2314',
              border: 'none',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '13px',
              fontWeight: 700,
              cursor: savingConfig ? 'not-allowed' : 'pointer',
              fontFamily: 'Inter, sans-serif',
              marginTop: '10px',
            }}
          >
            {savingConfig ? 'ĐANG LƯU…' : 'LƯU CẤU HÌNH'}
          </button>
        </form>

        {/* ── Card 2: Quản Lý Hệ Thống Chi Nhánh (#409:49) ── */}
        <div
          style={{
            width: '100%',
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '31px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            display: 'flex',
            flexDirection: 'column',
            gap: '20px',
            boxSizing: 'border-box',
          }}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Header (#409:51) */}
            <div
              style={{
                borderBottom: '1px solid #F2EDE8',
                paddingBottom: '12px',
              }}
            >
              <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#3D2314' }}>
                Quản Lý Hệ Thống Chi Nhánh
              </h2>
            </div>

            {/* Description (#409:53) */}
            <div style={{ fontSize: '14px', lineHeight: '21px', color: '#5C3826' }}>
              Quản lý vòng đời hoạt động của các chi nhánh cửa hàng. Thêm mới chi nhánh, cập nhật thông tin địa chỉ, số điện thoại hoặc tạm đóng cửa hàng khi cần thiết.
            </div>

            {/* Footnote (#409:54) */}
            <div style={{ fontSize: '13px', color: '#8C766C' }}>
              * Giới hạn tối đa: MAX_ACTIVE_BRANCHES chi nhánh hoạt động (BR-54).
            </div>
          </div>

          {/* Action Link Button (#409:55) */}
          <Link
            to="/branches"
            style={{
              width: '100%',
              height: '42px',
              background: '#3D2314',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '16px',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              textDecoration: 'none',
              cursor: 'pointer',
              fontFamily: 'Roboto, sans-serif',
              boxSizing: 'border-box',
              marginTop: '10px',
            }}
          >
            ĐI TỚI QUẢN LÝ CHI NHÁNH
          </Link>
        </div>

        {/* ── Card 3: Đổi Mật Khẩu Quản Trị (#409:57) ── */}
        <form
          onSubmit={handleChangePassword}
          style={{
            width: '100%',
            background: '#FFFFFF',
            border: '1px solid #EADDD3',
            borderRadius: '12px',
            padding: '31px',
            boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
            display: 'flex',
            flexDirection: 'column',
            gap: '20px',
            boxSizing: 'border-box',
          }}
        >
          {/* Header (#409:58) */}
          <div
            style={{
              borderBottom: '1px solid #F2EDE8',
              paddingBottom: '12px',
            }}
          >
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#3D2314' }}>
              Đổi Mật Khẩu Quản Trị
            </h2>
          </div>

          {passwordError && <div className="alert alert--error">{passwordError}</div>}
          {passwordSuccess && <div className="alert alert--success">Cập nhật mật khẩu thành công.</div>}

          {/* Field 1: Mật khẩu hiện tại (#409:60) */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <label style={{ fontSize: '15px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
              Mật khẩu hiện tại *
            </label>
            <input
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="Mật khẩu hiện tại"
              required
              style={{
                width: '100%',
                height: '42px',
                padding: '0 12px',
                background: '#FFFFFF',
                border: '1px solid #E5DBCF',
                borderRadius: '8px',
                fontSize: '15px',
                color: '#2C1A11',
                outline: 'none',
                boxSizing: 'border-box',
                fontFamily: 'Inter, sans-serif',
              }}
            />
          </div>

          {/* Field 2: Mật khẩu mới (#409:64) */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <label style={{ fontSize: '15px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
              Mật khẩu mới *
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Mật khẩu mới (ít nhất 8 ký tự)"
              required
              style={{
                width: '100%',
                height: '42px',
                padding: '0 12px',
                background: '#FFFFFF',
                border: '1px solid #E5DBCF',
                borderRadius: '8px',
                fontSize: '15px',
                color: '#2C1A11',
                outline: 'none',
                boxSizing: 'border-box',
                fontFamily: 'Inter, sans-serif',
              }}
            />
          </div>

          {/* Field 3: Xác nhận mật khẩu mới (#409:68) */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <label style={{ fontSize: '15px', fontWeight: 600, color: '#5C3826', fontFamily: 'Roboto, sans-serif' }}>
              Xác nhận mật khẩu mới *
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Nhập lại mật khẩu mới"
              required
              style={{
                width: '100%',
                height: '42px',
                padding: '0 12px',
                background: '#FFFFFF',
                border: '1px solid #E5DBCF',
                borderRadius: '8px',
                fontSize: '15px',
                color: '#2C1A11',
                outline: 'none',
                boxSizing: 'border-box',
                fontFamily: 'Inter, sans-serif',
              }}
            />
          </div>

          {/* Submit Button (#409:72) */}
          <button
            type="submit"
            disabled={savingPassword}
            style={{
              width: '100%',
              height: '39px',
              background: '#3D2314',
              border: 'none',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '13px',
              fontWeight: 700,
              cursor: savingPassword ? 'not-allowed' : 'pointer',
              fontFamily: 'Inter, sans-serif',
              marginTop: '10px',
            }}
          >
            {savingPassword ? 'ĐANG CẬP NHẬT…' : 'CẬP NHẬT MẬT KHẨU'}
          </button>
        </form>
      </div>
    </div>
  );
}
