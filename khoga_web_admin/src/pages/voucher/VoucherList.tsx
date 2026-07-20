import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react';

import { Link } from 'react-router-dom';

import {
  deactivateVoucher,
  DISCOUNT_TYPE_LABELS,
  listVouchers,
  VOUCHER_STATUS_LABELS,
  type Voucher,
} from '../../api/vouchers';

import { errorMessage } from '../../api/client';
import './VoucherList.css';

const formatMoney = (value: number) =>
  value.toLocaleString('vi-VN');

const formatDate = (iso: string | null) => {
  if (!iso) {
    return '—';
  }

  const [year, month, day] = iso
    .slice(0, 10)
    .split('-');

  return `${day}/${month}/${year}`;
};

const getDiscountValue = (voucher: Voucher) => {
  if (voucher.discountType === 'PERCENTAGE') {
    const maximumDiscount =
      voucher.maxDiscountAmount !== null
        ? ` (Tối đa ${formatMoney(
          voucher.maxDiscountAmount,
        )}đ)`
        : '';

    return `${formatMoney(
      voucher.discountValue,
    )}%${maximumDiscount}`;
  }

  return `${formatMoney(
    voucher.discountValue,
  )} VND`;
};

const getStatusClass = (
  status: Voucher['status'],
) => {
  switch (status) {
    case 'ACTIVE':
      return 'voucher-list-status--active';

    case 'EXPIRED':
      return 'voucher-list-status--expired';

    case 'SCHEDULED':
      return 'voucher-list-status--scheduled';

    case 'INACTIVE':
    default:
      return 'voucher-list-status--inactive';
  }
};

export default function VoucherList() {
  const [vouchers, setVouchers] = useState<
    Voucher[]
  >([]);

  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [deactivatingId, setDeactivatingId] =
    useState<string | null>(null);

  const loadVouchers = useCallback(async () => {
    setLoading(true);

    try {
      const data = await listVouchers();

      setVouchers(data);
      setError('');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadVouchers();
  }, [loadVouchers]);

  const filteredVouchers = useMemo(() => {
    const keyword = search
      .trim()
      .toLowerCase();

    if (!keyword) {
      return vouchers;
    }

    return vouchers.filter((voucher) =>
      voucher.code
        .toLowerCase()
        .includes(keyword),
    );
  }, [search, vouchers]);

  const handleDeactivate = async (
    voucher: Voucher,
  ) => {
    const confirmed = window.confirm(
      `Bạn có chắc muốn vô hiệu voucher "${voucher.code}"?\n\n` +
      'Voucher sẽ ngừng được áp dụng ngay lập tức.',
    );

    if (!confirmed) {
      return;
    }

    setDeactivatingId(voucher.id);
    setError('');

    try {
      await deactivateVoucher(voucher.id);
      await loadVouchers();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setDeactivatingId(null);
    }
  };

  return (
    <div className="voucher-list-page">
      {/* ================= HEADER ================= */}

      <header className="voucher-list-header">
        <h1 className="voucher-list-header__title">
          Chương Trình Khuyến Mãi &amp; Vouchers
        </h1>

        <Link
          to="/vouchers/new"
          className="voucher-list-create-button"
        >
          + Tạo Voucher Mới
        </Link>
      </header>

      {/* ================= SEARCH ================= */}

      <div className="voucher-list-toolbar">
        <input
          type="search"
          className="voucher-list-search"
          value={search}
          aria-label="Tìm theo mã voucher"
          onChange={(event) =>
            setSearch(event.target.value)
          }
        />
      </div>

      {error && (
        <div className="voucher-list-error">
          {error}
        </div>
      )}

      {/* ================= TABLE ================= */}

      <div className="voucher-list-table-wrap">
        <table className="voucher-list-table">
          <thead>
            <tr>
              <th>Mã Voucher</th>
              <th>Loại giảm giá</th>
              <th>Giá trị giảm</th>
              <th>Đơn tối thiểu</th>
              <th>Ngày hết hạn</th>
              <th>Trạng thái</th>
              <th>Hành động</th>
            </tr>
          </thead>

          <tbody>
            {loading ? (
              <tr>
                <td
                  colSpan={7}
                  className="voucher-list-table__empty"
                >
                  Đang tải…
                </td>
              </tr>
            ) : filteredVouchers.length === 0 ? (
              <tr>
                <td
                  colSpan={7}
                  className="voucher-list-table__empty"
                >
                  Chưa có voucher nào.
                </td>
              </tr>
            ) : (
              filteredVouchers.map((voucher) => (
                <tr key={voucher.id}>
                  <td className="voucher-list-table__code">
                    {voucher.code}
                  </td>

                  <td>
                    {
                      DISCOUNT_TYPE_LABELS[
                      voucher.discountType
                      ]
                    }
                  </td>

                  <td>
                    {getDiscountValue(voucher)}
                  </td>

                  <td>
                    {voucher.minOrderValue !== null
                      ? `${formatMoney(
                        voucher.minOrderValue,
                      )} VND`
                      : '—'}
                  </td>

                  <td>
                    {formatDate(voucher.endDate)}
                  </td>

                  <td>
                    <span
                      className={`voucher-list-status ${getStatusClass(
                        voucher.status,
                      )}`}
                    >
                      {
                        VOUCHER_STATUS_LABELS[
                        voucher.status
                        ]
                      }
                    </span>
                  </td>

                  <td>
                    <div className="voucher-list-actions">
                      <Link
                        to={`/vouchers/${voucher.id}/edit`}
                        className="voucher-list-action"
                      >
                        Sửa
                      </Link>

                      {(voucher.status === 'ACTIVE' ||
                        voucher.status ===
                        'SCHEDULED') && (
                          <button
                            type="button"
                            className="voucher-list-action voucher-list-action--danger"
                            disabled={
                              deactivatingId ===
                              voucher.id
                            }
                            onClick={() =>
                              void handleDeactivate(
                                voucher,
                              )
                            }
                          >
                            {deactivatingId ===
                              voucher.id
                              ? 'Đang xử lý…'
                              : 'Vô hiệu'}
                          </button>
                        )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}