import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  getCustomer,
  getCustomerHistory,
  getCustomerPointLogs,
  tierFromPoints,
  ORDER_STATUS_LABELS,
  type Customer,
  type CustomerOrderEntry,
  type PointLogEntry,
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
  const [pointLogs, setPointLogs] = useState<PointLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!id) return;
    Promise.all([
      getCustomer(id),
      getCustomerHistory(id),
      getCustomerPointLogs(id).catch(() => []),
    ])
      .then(([c, o, logs]) => {
        setCustomer(c);
        setOrders(o);
        setPointLogs(logs);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="full-center">Đang tải…</div>;
  if (error) return <div className="alert alert--error">{error}</div>;
  if (!customer) return null;

  const tier = tierFromPoints(customer.points);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px', fontFamily: 'Segoe UI, Roboto, sans-serif' }}>
      
      {/* ── Page Header ── */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '16px',
        }}
      >
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontFamily: 'Roboto, sans-serif' }}>
            <Link to="/customers" style={{ color: '#8C766C', textDecoration: 'none' }}>Khách hàng</Link> &rsaquo; {customer.fullName} &rsaquo; Lịch sử
          </div>
          <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11', fontFamily: 'Roboto, sans-serif' }}>
            Lịch Sử Đơn Hàng &amp; Tích Điểm
          </h1>
        </div>
      </div>

      {/* ── Customer Summary Info Panel ── */}
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '20px 24px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
          display: 'grid',
          gridTemplateColumns: 'repeat(5, 1fr)',
          gap: '20px',
        }}
      >
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontWeight: 600 }}>Khách hàng</div>
          <div style={{ fontSize: '16px', fontWeight: 700, color: '#2C1A11' }}>{customer.fullName}</div>
        </div>
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontWeight: 600 }}>Điện thoại</div>
          <div style={{ fontSize: '16px', fontWeight: 700, color: '#2C1A11' }}>{customer.phone}</div>
        </div>
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontWeight: 600 }}>Hạng thành viên</div>
          <div style={{ display: 'inline-block' }}>
            <span className={`badge ${tierBadgeClass(tier)}`}>{tier}</span>
          </div>
        </div>
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontWeight: 600 }}>Điểm tích lũy</div>
          <div style={{ fontSize: '16px', fontWeight: 700, color: '#3D2314' }}>{(customer.points ?? 0).toLocaleString('vi-VN')} điểm</div>
        </div>
        <div>
          <div style={{ fontSize: '13px', color: '#8C766C', marginBottom: '4px', fontWeight: 600 }}>Thành viên từ</div>
          <div style={{ fontSize: '16px', fontWeight: 700, color: '#2C1A11' }}>{fmtDate(customer.consentAt)}</div>
        </div>
      </div>

      {/* ── Purchase History Table ── */}
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '24px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
        }}
      >
        <h2 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#3D2314', fontFamily: 'Roboto, sans-serif' }}>
          Lịch Sử Mua Hàng
        </h2>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
            <thead>
              <tr style={{ background: '#F9F6F3', height: '42px' }}>
                <th style={{ padding: '10px 14px', textAlign: 'left', fontWeight: 600, color: '#5C3826', borderBottom: '1px solid #EADDD3' }}>Ngày</th>
                <th style={{ padding: '10px 14px', textAlign: 'left', fontWeight: 600, color: '#5C3826', borderBottom: '1px solid #EADDD3' }}>Mã Đơn</th>
                <th style={{ padding: '10px 14px', textAlign: 'left', fontWeight: 600, color: '#5C3826', borderBottom: '1px solid #EADDD3' }}>Trạng Thái</th>
                <th style={{ padding: '10px 14px', textAlign: 'right', fontWeight: 600, color: '#5C3826', borderBottom: '1px solid #EADDD3' }}>Tổng Tiền</th>
              </tr>
            </thead>
            <tbody>
              {orders.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>Khách hàng chưa có đơn hàng nào.</td>
                </tr>
              ) : orders.map((o) => (
                <tr key={o.orderId} style={{ height: '44px', borderBottom: '1px solid #F5EEE8' }}>
                  <td style={{ padding: '10px 14px', color: '#2C1A11' }}>{fmtDate(o.createdAt)}</td>
                  <td style={{ padding: '10px 14px', fontWeight: 700, color: '#3D2314' }}>{o.orderNumber}</td>
                  <td style={{ padding: '10px 14px', color: '#2C1A11' }}>{ORDER_STATUS_LABELS[o.status] ?? o.status}</td>
                  <td style={{ padding: '10px 14px', textAlign: 'right', fontWeight: 700, color: '#2C1A11' }}>{o.total.toLocaleString('vi-VN')} VND</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Manual Points Adjustment Log Table (Figma #149:760) ── */}
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '23px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
        }}
      >
        <div
          style={{
            borderBottom: '1px solid #F2EDE8',
            paddingBottom: '12px',
            marginBottom: '16px',
          }}
        >
          <h3 style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: '#3D2314', fontFamily: 'Segoe UI, sans-serif' }}>
            Nhật Ký Điều Chỉnh Điểm Thủ Công
          </h3>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
            <thead>
              <tr style={{ background: '#F5ECE1', height: '39.5px' }}>
                <th
                  style={{
                    padding: '10px 14px',
                    fontFamily: 'Segoe UI, sans-serif',
                    fontWeight: 700,
                    fontSize: '13px',
                    color: '#3D2314',
                    textAlign: 'left',
                    borderBottom: '1px solid #EADDD3',
                    width: '139px',
                  }}
                >
                  Ngày
                </th>
                <th
                  style={{
                    padding: '10px 14px',
                    fontFamily: 'Segoe UI, sans-serif',
                    fontWeight: 700,
                    fontSize: '13px',
                    color: '#3D2314',
                    textAlign: 'left',
                    borderBottom: '1px solid #EADDD3',
                    width: '212px',
                  }}
                >
                  Loại
                </th>
                <th
                  style={{
                    padding: '10px 14px',
                    fontFamily: 'Segoe UI, sans-serif',
                    fontWeight: 700,
                    fontSize: '13px',
                    color: '#3D2314',
                    textAlign: 'left',
                    borderBottom: '1px solid #EADDD3',
                    width: '161px',
                  }}
                >
                  Thay đổi điểm
                </th>
                <th
                  style={{
                    padding: '10px 14px',
                    fontFamily: 'Segoe UI, sans-serif',
                    fontWeight: 700,
                    fontSize: '13px',
                    color: '#3D2314',
                    textAlign: 'left',
                    borderBottom: '1px solid #EADDD3',
                    width: '420px',
                  }}
                >
                  Lý do
                </th>
                <th
                  style={{
                    padding: '10px 14px',
                    fontFamily: 'Segoe UI, sans-serif',
                    fontWeight: 700,
                    fontSize: '13px',
                    color: '#3D2314',
                    textAlign: 'left',
                    borderBottom: '1px solid #EADDD3',
                    width: '161px',
                  }}
                >
                  Thực hiện bởi
                </th>
              </tr>
            </thead>
            <tbody>
              {pointLogs.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: '#8C766C' }}>
                    Chưa có nhật ký điều chỉnh điểm.
                  </td>
                </tr>
              ) : (
                pointLogs.map((log) => (
                  <tr key={log.id} style={{ height: '41px', borderBottom: '1px solid #EADDD3' }}>
                    <td style={{ padding: '10px 14px', color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif', fontSize: '14px' }}>
                      {log.date}
                    </td>
                    <td style={{ padding: '10px 14px', color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif', fontSize: '14px' }}>
                      {log.type}
                    </td>
                    <td style={{ padding: '10px 14px', fontFamily: 'Segoe UI, sans-serif', fontSize: '14px' }}>
                      {log.pointsDelta > 0 ? (
                        <span style={{ fontWeight: 700, color: '#2E7D32' }}>
                          +{log.pointsDelta} điểm
                        </span>
                      ) : (
                        <span style={{ fontWeight: 700, color: '#C62828' }}>
                          {log.pointsDelta} điểm
                        </span>
                      )}
                    </td>
                    <td style={{ padding: '10px 14px', color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif', fontSize: '14px' }}>
                      {log.reason}
                    </td>
                    <td style={{ padding: '10px 14px', color: '#2C1A11', fontFamily: 'Segoe UI, sans-serif', fontSize: '14px' }}>
                      {log.performedBy}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
