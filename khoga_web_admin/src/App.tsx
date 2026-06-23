import { Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute';
import AppLayout from './layout/AppLayout';
import Login from './pages/Login';
import ForcePasswordChange from './pages/ForcePasswordChange';
import Dashboard from './pages/Dashboard';
import Placeholder from './pages/Placeholder';
import BranchList from './pages/branch/BranchList';
import BranchForm from './pages/branch/BranchForm';
import UserList from './pages/user/UserList';
import UserForm from './pages/user/UserForm';
import UserDetail from './pages/user/UserDetail';
import MenuItemList from './pages/catalog/MenuItemList';
import MenuItemForm from './pages/catalog/MenuItemForm';
import CategoryList from './pages/catalog/CategoryList';
import RawMaterialList from './pages/catalog/RawMaterialList';
import RawMaterialForm from './pages/catalog/RawMaterialForm';
import VoucherList from './pages/voucher/VoucherList';
import VoucherForm from './pages/voucher/VoucherForm';
import CustomerList from './pages/customer/CustomerList';
import CustomerForm from './pages/customer/CustomerForm';
import CustomerHistory from './pages/customer/CustomerHistory';

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
          <Route path="/users" element={<UserList />} />
          <Route path="/users/new" element={<UserForm />} />
          <Route path="/users/:id" element={<UserDetail />} />
          <Route path="/users/:id/edit" element={<UserForm />} />
          <Route path="/catalog" element={<MenuItemList />} />
          <Route path="/catalog/new" element={<MenuItemForm />} />
          <Route path="/catalog/categories" element={<CategoryList />} />
          <Route path="/catalog/:id/edit" element={<MenuItemForm />} />
          <Route path="/raw-materials" element={<RawMaterialList />} />
          <Route path="/raw-materials/new" element={<RawMaterialForm />} />
          <Route path="/raw-materials/:id/edit" element={<RawMaterialForm />} />
          <Route path="/vouchers" element={<VoucherList />} />
          <Route path="/vouchers/new" element={<VoucherForm />} />
          <Route path="/vouchers/:id/edit" element={<VoucherForm />} />
          <Route path="/customers" element={<CustomerList />} />
          <Route path="/customers/new" element={<CustomerForm />} />
          <Route path="/customers/:id/edit" element={<CustomerForm />} />
          <Route path="/customers/:id/history" element={<CustomerHistory />} />
          <Route path="/settings" element={<Placeholder title="Cấu hình hệ thống" hint="UC-24 · SystemConfig" />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
