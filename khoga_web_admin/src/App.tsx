import { Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute';
import AppLayout from './layout/AppLayout';
import Login from './pages/Login';
import ForcePasswordChange from './pages/ForcePasswordChange';
import Dashboard from './pages/Dashboard';
import Placeholder from './pages/Placeholder';
import BranchList from './pages/branch/BranchList';
import BranchForm from './pages/branch/BranchForm';

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      <Route element={<ProtectedRoute />}>
        <Route path="/force-password-change" element={<ForcePasswordChange />} />

        <Route element={<AppLayout />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/branches" element={<BranchList />} />
          <Route path="/branches/new" element={<BranchForm />} />
          <Route path="/branches/:id" element={<BranchForm />} />
          <Route path="/users" element={<Placeholder title="Quản lý tài khoản" hint="UC-10–14 · /api/v1/users" />} />
          <Route path="/catalog" element={<Placeholder title="Thực đơn & Danh mục" hint="UC-14–18 · /api/v1/menu-items, /categories" />} />
          <Route path="/raw-materials" element={<Placeholder title="Nguyên liệu" hint="UC-74 · /api/v1/raw-materials" />} />
          <Route path="/vouchers" element={<Placeholder title="Voucher & Khuyến mãi" hint="UC-19–23 · /api/v1/vouchers" />} />
          <Route path="/customers" element={<Placeholder title="Khách hàng & Loyalty" hint="UC-22–27 · /api/v1/customers" />} />
          <Route path="/settings" element={<Placeholder title="Cấu hình hệ thống" hint="UC-24 · SystemConfig" />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
