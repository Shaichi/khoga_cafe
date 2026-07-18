import type { Role } from '../api/types';

// ─────────────────────────────────────────────────────────────────────────────
// RDS Role → Chức năng mapping (đọc lại từ toàn bộ docs/rds_sections):
//
// SSADMIN:        User Mgmt (UC-10→14), Branch Lifecycle (UC-63→65),
//                 System Config UC-30 (R+W), Reports (HQ)
// BUSINESSADMIN:  Catalog/Menu (UC-15→19,68→74), Voucher (UC-20→23),
//                 Customer adjust points (BR-49), Raw Material Master (UC-74),
//                 System Config UC-30 (Read only), Reports (HQ)
// CEOVIEWER:      Reports (HQ read-only) — UC-28/29, UC-83
// STORE_MANAGER:  Branch Settings (UC-42), Customer (edit UC-26),
//                 Reports (branch-level), Inventory (import/export — mobile)
// CASHIER/BARISTA: POS only (Flutter app) — no web admin modules
// ─────────────────────────────────────────────────────────────────────────────

export interface NavItem {
  to: string;
  label: string;
  end?: boolean;
  roles?: Role[];
}

/** Sidebar navigation — mỗi item gắn với danh sách role được phép theo RDS. */
export const ALL_NAV: NavItem[] = [
  // ── Tất cả role ─────────────────────────────────────────────────────────
  { to: '/', label: 'Tổng quan', end: true },

  // ── SSADMIN only ────────────────────────────────────────────────────────
  { to: '/branches', label: 'Chi nhánh', roles: ['SSADMIN'] },
  { to: '/users',    label: 'Tài khoản', roles: ['SSADMIN'] },

  // ── BUSINESSADMIN only (RDS §3.3, §3.4, §3.6.2) ───────────────────────
  { to: '/catalog',       label: 'Thực đơn & Danh mục', roles: ['BUSINESSADMIN'] },
  { to: '/raw-materials', label: 'Nguyên liệu',           roles: ['BUSINESSADMIN'] },
  { to: '/vouchers',      label: 'Voucher',                roles: ['BUSINESSADMIN'] },

  // ── BUSINESSADMIN + STORE_MANAGER (RDS §3.5: biz adjust, SM edit) ──────
  { to: '/customers', label: 'Khách hàng', roles: ['BUSINESSADMIN', 'STORE_MANAGER'] },

  // ── Reports: HQ (ceo/biz/ss) + SM (branch-level) ──────────────────────
  {
    to: '/reports',
    label: 'Báo cáo',
    roles: ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN', 'STORE_MANAGER'],
  },

  // ── System Config: SSADMIN (R+W) ───────────
  { to: '/settings', label: 'Cấu hình hệ thống', roles: ['SSADMIN'] },

  // ── STORE_MANAGER: branch settings (UC-42) ────────────────────────────
  {
    to: '/branches',
    label: 'Cài đặt chi nhánh',
    roles: ['STORE_MANAGER'],
  },
];

/**
 * Trả về danh sách nav items hiển thị cho role hiện tại.
 * Dashboard (/) luôn hiển thị; các mục khác lọc theo `roles`.
 */
export function navForRole(role: Role): NavItem[] {
  const seen = new Set<string>();
  return ALL_NAV.filter((item) => {
    if (seen.has(item.to)) return false;
    const allowed = !item.roles || item.roles.includes(role);
    if (allowed) seen.add(item.to);
    return allowed;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Route-level access: ánh xạ route prefix → danh sách role được phép.
// Dùng cho <RoleRoute> guard trong App.tsx.
// ─────────────────────────────────────────────────────────────────────────────

const ALL_ROLES: Role[] = ['CASHIER','BARISTA','STORE_MANAGER','CEOVIEWER','BUSINESSADMIN','SSADMIN'];

const ROUTE_ROLES: Array<{ prefix: string; roles: Role[] }> = [
  // Branch lifecycle: SSADMIN. Branch settings: SSADMIN + SM
  { prefix: '/branches',      roles: ['SSADMIN', 'STORE_MANAGER'] },
  // User management: SSADMIN only
  { prefix: '/users',         roles: ['SSADMIN'] },
  // Catalog/Menu: BUSINESSADMIN only (RDS §3.3)
  { prefix: '/catalog',       roles: ['BUSINESSADMIN'] },
  // Raw materials: BUSINESSADMIN only (RDS §3.6.2 UC-74)
  { prefix: '/raw-materials', roles: ['BUSINESSADMIN'] },
  // Vouchers: BUSINESSADMIN only (RDS §3.4)
  { prefix: '/vouchers',      roles: ['BUSINESSADMIN'] },
  // Customers: BUSINESSADMIN (point adjust) + SM (edit)
  { prefix: '/customers',     roles: ['BUSINESSADMIN', 'STORE_MANAGER'] },
  // System config: SSADMIN (R+W)
  { prefix: '/settings',      roles: ['SSADMIN'] },
  // Reports: HQ + SM
  {
    prefix: '/reports',
    roles: ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN', 'STORE_MANAGER'],
  },
  // Profile & force-password: tất cả role
  { prefix: '/profile',               roles: ALL_ROLES },
  { prefix: '/force-password-change',  roles: ALL_ROLES },
];

/**
 * Kiểm tra role có được phép truy cập `pathname` không.
 * Dashboard `/` luôn được phép.
 */
export function canAccess(role: Role, pathname: string): boolean {
  if (pathname === '/') return true;
  const rule = ROUTE_ROLES.find((r) => pathname.startsWith(r.prefix));
  if (!rule) return true; // route không khai báo → cho qua
  return rule.roles.includes(role);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard quick-links theo role (chỉ hiện chức năng RDS cho phép)
// ─────────────────────────────────────────────────────────────────────────────

export interface DashModule {
  to: string;
  title: string;
  desc: string;
}

const MODULES_BY_ROLE: Record<Role, DashModule[]> = {
  SSADMIN: [
    { to: '/branches', title: 'Chi nhánh',          desc: 'Quản lý chuỗi cửa hàng' },
    { to: '/users',    title: 'Tài khoản',           desc: 'Nhân sự & phân quyền' },
    { to: '/settings', title: 'Cấu hình hệ thống',  desc: 'Tham số toàn chuỗi' },
    { to: '/reports',  title: 'Báo cáo',              desc: 'Báo cáo & phân tích toàn chuỗi' },
  ],
  BUSINESSADMIN: [
    { to: '/catalog',       title: 'Thực đơn & Danh mục', desc: 'Món, danh mục, topping' },
    { to: '/raw-materials', title: 'Nguyên liệu',           desc: 'Master nguyên liệu' },
    { to: '/vouchers',      title: 'Voucher',                desc: 'Khuyến mãi' },
    { to: '/customers',     title: 'Khách hàng',             desc: 'Loyalty & điều chỉnh điểm' },
    { to: '/reports',       title: 'Báo cáo',                desc: 'COGS, doanh thu, lịch sử giá' },
  ],
  CEOVIEWER: [
    { to: '/reports', title: 'Báo cáo tổng hợp', desc: 'Doanh thu, COGS, Anomaly (UC-28/29)' },
  ],
  STORE_MANAGER: [
    { to: '/branches',  title: 'Cài đặt chi nhánh', desc: 'Cấu hình thiết bị & múi giờ (UC-42)' },
    { to: '/customers', title: 'Khách hàng',          desc: 'Xem & chỉnh sửa khách hàng (UC-26)' },
    { to: '/reports',   title: 'Báo cáo chi nhánh',  desc: 'Doanh thu, Z-report, nhân sự' },
  ],
  CASHIER:  [],
  BARISTA:  [],
};

export function dashModulesForRole(role: Role): DashModule[] {
  return MODULES_BY_ROLE[role] ?? [];
}
