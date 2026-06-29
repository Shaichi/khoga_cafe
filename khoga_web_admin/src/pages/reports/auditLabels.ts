// Shared VN labels + timestamp formatting for the audit-trail report pages (UC-77/83).

export function entityLabel(entity: string): string {
  switch (entity) {
    case 'MenuItem': return 'Giá menu';
    case 'Voucher': return 'Voucher';
    case 'User': return 'Tài khoản';
    default: return entity;
  }
}

export function actionLabel(action: string | null): string {
  switch (action) {
    case 'CREATE': return 'Tạo';
    case 'UPDATE': return 'Sửa';
    case 'DELETE': return 'Xóa';
    default: return action ?? '—';
  }
}

export function formatTs(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString('vi-VN');
}
