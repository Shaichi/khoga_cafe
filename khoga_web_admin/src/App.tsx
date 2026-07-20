import { Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute';
import RoleRoute from './auth/RoleRoute';
import AppLayout from './layout/AppLayout';
import Login from './pages/Login';
import ForcePasswordChange from './pages/ForcePasswordChange';
import Dashboard from './pages/Dashboard';
import BranchList from './pages/branch/BranchList';
import BranchForm from './pages/branch/BranchForm';
import BranchSettings from './pages/branch/BranchSettings';
import UserList from './pages/user/UserList';
import UserForm from './pages/user/UserForm';
import UserDetail from './pages/user/UserDetail';
import MenuItemList from './pages/catalog/MenuItemList';
import MenuItemDetail from './pages/catalog/MenuItemDetail';
import MenuItemForm from './pages/catalog/MenuItemForm';
import RawMaterialList from './pages/catalog/RawMaterialList';
import RawMaterialForm from './pages/catalog/RawMaterialForm';
import VoucherList from './pages/voucher/VoucherList';
import VoucherForm from './pages/voucher/VoucherForm';
import CustomerList from './pages/customer/CustomerList';
import CustomerForm from './pages/customer/CustomerForm';
import CustomerHistory from './pages/customer/CustomerHistory';
import ProfileView from './pages/profile/ProfileView';
import ProfileEdit from './pages/profile/ProfileEdit';
import ChangePassword from './pages/profile/ChangePassword';
import CentralSettings from './pages/settings/CentralSettings';
import ReportsHome from './pages/reports/ReportsHome';
import HqConsolidated from './pages/reports/HqConsolidated';
import StoreRevenue from './pages/reports/StoreRevenue';
import CogsReport from './pages/reports/CogsReport';
import ChangeHistory from './pages/reports/ChangeHistory';
import AccessReview from './pages/reports/AccessReview';
import LoyaltyLiability from './pages/reports/LoyaltyLiability';
import LabourReport from './pages/reports/LabourReport';
import ZReport from './pages/reports/ZReport';
import AnomalyReport from './pages/reports/AnomalyReport';

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      <Route element={<ProtectedRoute />}>
        <Route path="/force-password-change" element={<ForcePasswordChange />} />

        <Route element={<AppLayout />}>
          {/* Dashboard — tất cả role */}
          <Route path="/" element={<Dashboard />} />

          {/* Profile — tất cả role đã đăng nhập */}
          <Route path="/profile" element={<ProfileView />} />
          <Route path="/profile/edit" element={<ProfileEdit />} />
          <Route path="/profile/password" element={<ChangePassword />} />

          {/* Tất cả routes còn lại bảo vệ bằng RoleRoute */}
          <Route element={<RoleRoute />}>
            {/* SSADMIN */}
            <Route path="/branches" element={<BranchList />} />
            <Route path="/branches/new" element={<BranchForm />} />
            <Route path="/branches/:id" element={<BranchForm />} />

            {/* SSADMIN + STORE_MANAGER */}
            <Route path="/branches/:id/settings" element={<BranchSettings />} />

            {/* SSADMIN */}
            <Route path="/users" element={<UserList />} />
            <Route path="/users/new" element={<UserForm />} />
            <Route path="/users/:id" element={<UserDetail />} />
            <Route path="/users/:id/edit" element={<UserForm />} />

            {/* SSADMIN + BUSINESSADMIN */}
            <Route path="/catalog" element={<MenuItemList />} />
            <Route path="/catalog/new" element={<MenuItemForm />} />
            <Route path="/catalog/categories" element={<Navigate to="/catalog" replace />} />
            <Route path="/catalog/:id" element={<MenuItemDetail />} />
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
            <Route path="/settings" element={<CentralSettings />} />

            {/* Reports: HQ + STORE_MANAGER */}
            <Route path="/reports" element={<ReportsHome />} />
            <Route path="/reports/hq-consolidated" element={<HqConsolidated />} />
            <Route path="/reports/store-revenue" element={<StoreRevenue />} />
            <Route path="/reports/cogs" element={<CogsReport />} />
            <Route path="/reports/change-history" element={<ChangeHistory />} />
            <Route path="/reports/access-review" element={<AccessReview />} />
            <Route path="/reports/loyalty-liability" element={<LoyaltyLiability />} />
            <Route path="/reports/labour" element={<LabourReport />} />
            <Route path="/reports/z-report" element={<ZReport />} />
            <Route path="/reports/anomaly" element={<AnomalyReport />} />
          </Route>
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

