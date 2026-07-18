import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext';
import { canAccess } from './rbac';

/**
 * Đặt bên trong <ProtectedRoute> để chặn truy cập route
 * không thuộc quyền của role hiện tại. Redirect về "/" với
 * thông báo lỗi 403 ẩn danh.
 */
export default function RoleRoute() {
  const { user } = useAuth();
  const location = useLocation();

  if (!user) return null; // ProtectedRoute đã xử lý redirect login

  if (!canAccess(user.role, location.pathname)) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}
