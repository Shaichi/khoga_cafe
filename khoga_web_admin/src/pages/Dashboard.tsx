import { Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const MODULES = [
  { to: '/branches', title: 'Chi nhánh', desc: 'Quản lý chuỗi cửa hàng (UC-63/64/65)' },
  { to: '/users', title: 'Tài khoản', desc: 'Nhân sự & phân quyền (UC-10–14)' },
  { to: '/catalog', title: 'Thực đơn & Danh mục', desc: 'Món, danh mục, topping (UC-14–18)' },
  { to: '/raw-materials', title: 'Nguyên liệu', desc: 'Master nguyên liệu (UC-74)' },
  { to: '/vouchers', title: 'Voucher', desc: 'Khuyến mãi (UC-19–23)' },
  { to: '/customers', title: 'Khách hàng', desc: 'Loyalty & lịch sử (UC-22–27)' },
];

export default function Dashboard() {
  const { user } = useAuth();
  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">Xin chào, {user?.fullName || user?.username}</h1>
        <p className="page-subtitle">Bảng điều khiển quản trị trung tâm Khoga Café.</p>
      </div>
      <div className="card-grid">
        {MODULES.map((m) => (
          <Link key={m.to} to={m.to} className="module-card">
            <h3>{m.title}</h3>
            <p>{m.desc}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
