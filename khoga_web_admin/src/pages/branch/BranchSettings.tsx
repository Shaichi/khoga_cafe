import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { getBranch, getBranchSettings, updateBranchSettings, type Branch } from '../../api/branches';
import { errorMessage } from '../../api/client';

/**
 * Screen 33 — "Cấu Hình Chi Nhánh" (UC-42). Branch-scoped operational settings a
 * store manager tunes for their own branch. Only the backend-backed fields are
 * shown (timezone + receipt-printer address); email / a second printer / the
 * "test print" actions in the Figma are deferred until the backend supports them.
 */
export default function BranchSettings() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [branch, setBranch] = useState<Branch | null>(null);
  const [timezone, setTimezone] = useState('');
  const [printerAddress, setPrinterAddress] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    Promise.all([getBranch(id), getBranchSettings(id)])
      .then(([b, s]) => {
        setBranch(b);
        setTimezone(s.timezone ?? '');
        setPrinterAddress(s.printerAddress ?? '');
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!id) return;
    setError('');
    setSubmitting(true);
    try {
      await updateBranchSettings(id, { timezone, printerAddress });
      navigate('/branches');
    } catch (err) {
      setError(errorMessage(err, 'Lưu cấu hình thất bại'));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="full-center">Đang tải…</div>;

  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Cấu Hình Vận Hành Chi Nhánh</h1>
      </div>

      <form className="form-card" onSubmit={handleSubmit}>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="field">
          <label className="label" htmlFor="branch-name">Tên chi nhánh</label>
          <input id="branch-name" className="input" value={branch?.name ?? ''} readOnly />
        </div>
        <div className="field">
          <label className="label" htmlFor="timezone">Múi giờ hoạt động</label>
          <input
            id="timezone"
            className="input"
            value={timezone}
            onChange={(e) => setTimezone(e.target.value)}
            placeholder="vd: Asia/Ho_Chi_Minh"
          />
        </div>
        <div className="field">
          <label className="label" htmlFor="printer">IP máy in hóa đơn POS</label>
          <input
            id="printer"
            className="input"
            value={printerAddress}
            onChange={(e) => setPrinterAddress(e.target.value)}
            placeholder="vd: 192.168.1.150"
          />
        </div>

        <p className="hint">
          Cấu hình vận hành theo chi nhánh. Email &amp; máy in khu pha chế sẽ bổ sung khi backend hỗ trợ.
        </p>

        <div className="form-actions">
          <button type="submit" className="btn btn--primary" disabled={submitting}>
            {submitting ? 'Đang lưu…' : 'Lưu cài đặt'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => navigate('/branches')}>
            Hủy
          </button>
        </div>
      </form>
    </div>
  );
}
