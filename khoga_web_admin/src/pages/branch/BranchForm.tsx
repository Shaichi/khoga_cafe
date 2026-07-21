import { useEffect, useState, type ChangeEvent, type FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  createBranch,
  getBranch,
  updateBranch,
  deactivateBranch,
  activateBranch,
  type BranchInput,
} from '../../api/branches';
import { errorMessage } from '../../api/client';

const PHONE_RE = /^[0-9]{10,12}$/;

/** UC-46/47 — edit branch details and manage operational status. */
export default function BranchForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [form, setForm] = useState<BranchInput>({ name: '', address: '', phone: '' });
  const [active, setActive] = useState(true);
  const [initialActive, setInitialActive] = useState(true);
  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    getBranch(id)
      .then((b) => {
        setForm({ name: b.name, address: b.address, phone: b.phone });
        setActive(b.active);
        setInitialActive(b.active);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const set = (key: keyof BranchInput) => (e: ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [key]: e.target.value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (!PHONE_RE.test(form.phone)) {
      setError('Số điện thoại phải có 10–12 chữ số.');
      return;
    }
    setSubmitting(true);
    try {
      if (isEdit && id) {
        if (active !== initialActive) {
          if (!active) {
            // If status changed to inactive, trigger confirmation
            if (!window.confirm('Vô hiệu hóa chi nhánh này? Tài khoản nhân sự của chi nhánh sẽ bị khóa và lịch làm việc tương lai bị xóa.')) {
              setSubmitting(false);
              return;
            }
            await deactivateBranch(id);
          } else {
            // Reactivate inactive branch
            await activateBranch(id);
          }
        }
        await updateBranch(id, form);
      } else {
        await createBranch(form);
      }
      navigate('/branches');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div style={{ textAlign: 'center', padding: '40px', color: '#8C766C' }}>Đang tải…</div>;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header Area */}
      <div style={{ borderBottom: '1px solid #EADDD3', paddingBottom: '16px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#2C1A11', margin: 0, fontFamily: 'Segoe UI, sans-serif' }}>
          {isEdit ? 'Chỉnh Sửa Chi Nhánh' : 'Thêm Chi Nhánh Mới'}
        </h1>
      </div>

      {error && <div className="alert alert--error" style={{ maxWidth: '662px' }}>{error}</div>}

      {/* Main Form Card */}
      <form
        onSubmit={handleSubmit}
        style={{
          width: '662px',
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '31px',
          boxShadow: '0px 4px 6px 0px rgba(0, 0, 0, 0.02)',
          display: 'flex',
          flexDirection: 'column',
          gap: '20px'
        }}
      >
        {/* Branch Code (Read Only, only shown on Edit) */}
        {isEdit && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <label style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
              Mã Chi Nhánh (Mặc định)
            </label>
            <input
              type="text"
              aria-label="Mã Chi Nhánh"
              value={id}
              readOnly
              style={{
                width: '100%',
                height: '46px',
                padding: '12px 14px',
                background: '#F5ECE1',
                border: '1px solid #E5DBCF',
                borderRadius: '8px',
                fontSize: '15px',
                color: '#666666',
                fontFamily: 'Segoe UI, sans-serif',
                outline: 'none',
                cursor: 'not-allowed'
              }}
            />
          </div>
        )}

        {/* Branch Name */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
            Tên Chi Nhánh <span style={{ color: '#FF0000' }}>*</span>
          </label>
          <input
            type="text"
            aria-label="Tên Chi Nhánh"
            value={form.name}
            onChange={set('name')}
            placeholder="Ví dụ: Khoga Café - Binh Thanh"
            required
            style={{
              width: '100%',
              height: '46px',
              padding: '12px 14px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#000000',
              fontFamily: 'Segoe UI, sans-serif',
              outline: 'none'
            }}
          />
        </div>

        {/* Address */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
            Địa Chỉ <span style={{ color: '#FF0000' }}>*</span>
          </label>
          <input
            type="text"
            aria-label="Địa Chỉ"
            value={form.address}
            onChange={set('address')}
            placeholder="Ví dụ: 200 Điện Biên Phủ, P. 17, Q. Bình Thạnh"
            required
            style={{
              width: '100%',
              height: '46px',
              padding: '12px 14px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#000000',
              fontFamily: 'Segoe UI, sans-serif',
              outline: 'none'
            }}
          />
        </div>

        {/* Phone */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
            Số Điện Thoại Liên Hệ <span style={{ color: '#FF0000' }}>*</span>
          </label>
          <input
            type="text"
            aria-label="Số Điện Thoại Liên Hệ"
            value={form.phone}
            onChange={set('phone')}
            placeholder="Ví dụ: 0283930005 (10-12 số)"
            required
            style={{
              width: '100%',
              height: '46px',
              padding: '12px 14px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#000000',
              fontFamily: 'Segoe UI, sans-serif',
              outline: 'none'
            }}
          />
        </div>

        {/* Active Status (Only shown when editing, new branches default to active) */}
        {isEdit && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <label style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
              Trạng Thái Hoạt Động
            </label>
            <select
              aria-label="Trạng Thái Hoạt Động"
              value={active ? 'ACTIVE' : 'INACTIVE'}
              onChange={(e) => setActive(e.target.value === 'ACTIVE')}
              style={{
                width: '100%',
                height: '46px',
                padding: '12px 14px',
                background: '#FFFFFF',
                border: '1px solid #E5DBCF',
                borderRadius: '8px',
                fontSize: '15px',
                color: '#2C1A11',
                fontFamily: 'Segoe UI, sans-serif',
                outline: 'none',
                cursor: 'pointer'
              }}
            >
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Vô hiệu hóa</option>
            </select>
          </div>
        )}

        {/* Form Actions */}
        <div style={{ display: 'flex', gap: '12px', marginTop: '10px' }}>
          <button
            type="submit"
            disabled={submitting}
            style={{
              width: '144.7px',
              height: '43px',
              background: '#3D2314',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              fontSize: '15px',
              fontWeight: 700,
              cursor: submitting ? 'not-allowed' : 'pointer',
              opacity: submitting ? 0.7 : 1,
              fontFamily: 'Arial, sans-serif'
            }}
          >
            {submitting ? 'Đang lưu…' : 'Lưu Thay Đổi'}
          </button>
          <button
            type="button"
            onClick={() => navigate('/branches')}
            style={{
              width: '100.84px',
              height: '43px',
              background: '#F5ECE1',
              border: '1px solid #EADDD3',
              borderRadius: '8px',
              color: '#3D2314',
              fontSize: '15px',
              fontWeight: 700,
              cursor: 'pointer',
              fontFamily: 'Segoe UI, sans-serif'
            }}
          >
            Hủy bỏ
          </button>
        </div>
      </form>
    </div>
  );
}
