import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  getCustomer,
  getCustomerHistory,
  tierFromPoints,
  ORDER_STATUS_LABELS,
  type Customer,
  type CustomerOrderEntry,
} from '../../api/customers';
import { errorMessage } from '../../api/client';
import { tierBadgeClass } from './CustomerList';

const fmtDate = (iso: string | null) => {
  if (!iso) return '—';
  const [y, m, d] = iso.slice(0, 10).split('-');
  return `${d}/${m}/${y}`;
};

export default function CustomerHistory() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [orders, setOrders] = useState<CustomerOrderEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!id) return;
    Promise.all([getCustomer(id), getCustomerHistory(id)])
      .then(([c, o]) => { setCustomer(c); setOrders(o); })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="full-center">Đang tải…</div>;
  if (error) return <div className="alert alert--error">{error}</div>;
  if (!customer) return null;

  const tier = tierFromPoints(customer.points);

  return (
    <div>
      <div className="page-head page-head--row">
        <div>
          <p className="breadcrumb">
            <Link to="/customers">Khách hàng</Link> › {customer.fullName} › Lịch sử
          </p>
          <h1 className="page-title">Lịch Sử Đơn Hàng</h1>
        </div>
        <button className="btn btn--ghost" onClick={() => navigate('/customers')}>← Quay lại</button>
      </div>

      <div className="info-panel" style={{ marginBottom: 20 }}>
        <div className="info-panel__stat">
          <span className="info-panel__label">Khách hàng</span>
          <span className="info-panel__value">{customer.fullName}</span>
        </div>
        <div className="info-panel__stat">
          <span className="info-panel__label">Điện thoại</span>
          <span className="info-panel__value">{customer.phone}</span>
        </div>
        <div className="info-panel__stat">
          <span className="info-panel__label">Hạng thành viên</span>
          <span className={`badge ${tierBadgeClass(tier)}`} style={{ alignSelf: 'flex-start' }}>{tier}</span>
        </div>
        <div className="info-panel__stat">
          <span className="info-panel__label">Điểm tích lũy</span>
          <span className="info-panel__value">{(customer.points ?? 0).toLocaleString('vi-VN')} điểm</span>
        </div>
        <div className="info-panel__stat">
          <span className="info-panel__label">Thành viên từ</span>
          <span className="info-panel__value">{fmtDate(customer.consentAt)}</span>
        </div>
      </div>

      <h2 className="section-title" style={{ marginTop: 0 }}>Lịch Sử Mua Hàng</h2>
      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr><th>Ngày</th><th>Mã Đơn</th><th>Trạng Thái</th><th>Tổng Tiền</th></tr>
          </thead>
          <tbody>
            {orders.length === 0 ? (
              <tr><td colSpan={4} className="table__empty">Khách hàng chưa có đơn hàng nào.</td></tr>
            ) : orders.map((o) => (
              <tr key={o.orderId}>
                <td>{fmtDate(o.createdAt)}</td>
                <td style={{ fontWeight: 600 }}>{o.orderNumber}</td>
                <td>{ORDER_STATUS_LABELS[o.status] ?? o.status}</td>
                <td>{o.total.toLocaleString('vi-VN')} VND</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="section-title">Nhật Ký Điều Chỉnh Điểm Thủ Công</h2>
      <p className="info-note">
        Nhật ký điều chỉnh điểm được ghi vào <strong>audit log</strong> nhưng chưa có API riêng để truy vấn.
        Mục này sẽ hiển thị khi endpoint lịch sử điều chỉnh điểm được bổ sung.
      </p>
    </div>
  );
}
