import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext';

/** Gate for authenticated areas. Also forces the first-login password change (BR-12). */
export default function ProtectedRoute() {
  const { user, loading, mustChangePassword } = useAuth();
  const location = useLocation();

  if (loading) {
    return <div className="full-center">Đang tải…</div>;
  }
  if (!user) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }
  if (mustChangePassword && location.pathname !== '/force-password-change') {
    return <Navigate to="/force-password-change" replace />;
  }
  return <Outlet />;
}
