import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import * as authApi from '../api/auth';
import type { Profile } from '../api/types';

const MUST_CHANGE_KEY = 'khoga_must_change_pw';

interface AuthState {
  user: Profile | null;
  loading: boolean;
  mustChangePassword: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  completePasswordChange: () => void;
  /** Re-fetch the current user (e.g. after a self-service profile edit). */
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [mustChangePassword, setMustChangePassword] = useState<boolean>(
    () => sessionStorage.getItem(MUST_CHANGE_KEY) === 'true',
  );

  // On first load, ask the backend who we are. The HttpOnly cookie (if present)
  // authenticates the request; a 401 simply means "not logged in".
  useEffect(() => {
    authApi
      .getProfile()
      .then(setUser)
      .catch(() => setUser(null))
      .finally(() => setLoading(false));
  }, []);

  const login = async (username: string, password: string) => {
    const res = await authApi.login(username, password); // sets HttpOnly cookie
    setMustChangePassword(res.mustChangePassword);
    sessionStorage.setItem(MUST_CHANGE_KEY, String(res.mustChangePassword));
    setUser(await authApi.getProfile());
  };

  const logout = async () => {
    try {
      await authApi.logout();
    } finally {
      setUser(null);
      setMustChangePassword(false);
      sessionStorage.removeItem(MUST_CHANGE_KEY);
    }
  };

  const completePasswordChange = () => {
    setMustChangePassword(false);
    sessionStorage.removeItem(MUST_CHANGE_KEY);
  };

  const refreshProfile = async () => {
    setUser(await authApi.getProfile());
  };

  return (
    <AuthContext.Provider
      value={{ user, loading, mustChangePassword, login, logout, completePasswordChange, refreshProfile }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
