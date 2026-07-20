import {
  useEffect,
  useState,
  type FormEvent,
} from 'react';

import {
  useNavigate,
  useParams,
} from 'react-router-dom';

import {
  createVoucher,
  getVoucher,
  updateVoucher,
  type CreateVoucherInput,
  type DiscountType,
  type UpdateVoucherInput,
} from '../../api/vouchers';

import { errorMessage } from '../../api/client';
import './VoucherForm.css';

/**
 * Chuyển giá trị trong input thành number.
 * Trả về null nếu người dùng để trống hoặc nhập không hợp lệ.
 */
const numberOrNull = (
  value: string,
): number | null => {
  const normalizedValue = value.trim();

  if (!normalizedValue) {
    return null;
  }

  const parsedValue = Number(normalizedValue);

  if (!Number.isFinite(parsedValue)) {
    return null;
  }

  return parsedValue;
};

/**
 * Chuyển ngày YYYY-MM-DD thành thời điểm đầu ngày.
 */
const toStartDateTime = (
  date: string,
): string | null => {
  if (!date) {
    return null;
  }

  return `${date}T00:00:00`;
};

/**
 * Chuyển ngày YYYY-MM-DD thành thời điểm cuối ngày.
 */
const toEndDateTime = (
  date: string,
): string | null => {
  if (!date) {
    return null;
  }

  return `${date}T23:59:59`;
};

/**
 * Lấy riêng phần YYYY-MM-DD từ datetime trả về bởi backend.
 */
const getDatePart = (
  isoDate: string | null | undefined,
): string => {
  if (!isoDate) {
    return '';
  }

  return isoDate.slice(0, 10);
};

export default function VoucherForm() {
  const navigate = useNavigate();

  const { id } = useParams<{
    id: string;
  }>();

  const isEditMode = Boolean(id);

  /* ==================== Form state ==================== */

  const [code, setCode] = useState('');

  const [
    discountType,
    setDiscountType,
  ] = useState<DiscountType | ''>('');

  const [
    discountValue,
    setDiscountValue,
  ] = useState('');

  const [
    maxDiscountAmount,
    setMaxDiscountAmount,
  ] = useState('');

  const [
    minOrderValue,
    setMinOrderValue,
  ] = useState('');

  const [
    startDate,
    setStartDate,
  ] = useState('');

  const [
    endDate,
    setEndDate,
  ] = useState('');

  const [
    usageLimitPerCustomer,
    setUsageLimitPerCustomer,
  ] = useState('1');

  const [
    maxTotalUses,
    setMaxTotalUses,
  ] = useState('100');

  /**
   * Trạng thái active vẫn được lưu để khi chỉnh sửa
   * không làm thay đổi trạng thái hiện tại của voucher.
   *
   * Ô trạng thái trên giao diện chỉ hiển thị nền xám,
   * không hiển thị chữ theo đúng màn hình SRS.
   */
  const [active, setActive] =
    useState(true);

  /* ==================== UI state ==================== */

  const [loading, setLoading] =
    useState(isEditMode);

  const [submitting, setSubmitting] =
    useState(false);

  const [error, setError] =
    useState('');

  const isPercentage =
    discountType === 'PERCENTAGE';

  /* ==================== Load voucher ==================== */

  useEffect(() => {
    if (!id) {
      return;
    }

    const loadVoucher = async () => {
      setLoading(true);
      setError('');

      try {
        const voucher =
          await getVoucher(id);

        setCode(voucher.code);

        setDiscountType(
          voucher.discountType,
        );

        setDiscountValue(
          voucher.discountValue?.toString() ??
          '',
        );

        setMaxDiscountAmount(
          voucher.maxDiscountAmount?.toString() ??
          '',
        );

        setMinOrderValue(
          voucher.minOrderValue?.toString() ??
          '',
        );

        setStartDate(
          getDatePart(voucher.startDate),
        );

        setEndDate(
          getDatePart(voucher.endDate),
        );

        setUsageLimitPerCustomer(
          voucher.usageLimitPerCustomer?.toString() ??
          '1',
        );

        setMaxTotalUses(
          voucher.maxTotalUses?.toString() ??
          '100',
        );

        setActive(
          voucher.status !== 'INACTIVE',
        );
      } catch (err) {
        setError(errorMessage(err));
      } finally {
        setLoading(false);
      }
    };

    void loadVoucher();
  }, [id]);

  /* ==================== Submit ==================== */

  const handleSubmit = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault();

    setError('');

    const normalizedCode = code
      .trim()
      .toUpperCase();

    const parsedDiscountValue =
      numberOrNull(discountValue);

    const parsedMaxDiscountAmount =
      numberOrNull(maxDiscountAmount);

    const parsedMinOrderValue =
      numberOrNull(minOrderValue);

    const parsedUsageLimitPerCustomer =
      numberOrNull(
        usageLimitPerCustomer,
      );

    const parsedMaxTotalUses =
      numberOrNull(maxTotalUses);

    /* ==================== Validation ==================== */

    if (
      !isEditMode &&
      !normalizedCode
    ) {
      setError(
        'Mã voucher không được để trống.',
      );

      return;
    }

    if (
      !isEditMode &&
      !/^[A-Z0-9]+$/.test(
        normalizedCode,
      )
    ) {
      setError(
        'Mã voucher chỉ được chứa chữ cái và chữ số.',
      );

      return;
    }

    if (!discountType) {
      setError(
        'Vui lòng chọn loại chiết khấu.',
      );

      return;
    }

    if (
      parsedDiscountValue === null ||
      parsedDiscountValue <= 0
    ) {
      setError(
        'Giá trị giảm phải lớn hơn 0.',
      );

      return;
    }

    if (
      discountType === 'PERCENTAGE' &&
      (
        parsedDiscountValue < 1 ||
        parsedDiscountValue > 100
      )
    ) {
      setError(
        'Giá trị giảm theo phần trăm phải nằm trong khoảng từ 1 đến 100.',
      );

      return;
    }

    if (
      discountType === 'PERCENTAGE' &&
      (
        parsedMaxDiscountAmount === null ||
        parsedMaxDiscountAmount <= 0
      )
    ) {
      setError(
        'Voucher giảm theo phần trăm phải có mức giảm tối đa.',
      );

      return;
    }

    if (
      parsedMinOrderValue !== null &&
      parsedMinOrderValue < 0
    ) {
      setError(
        'Giá trị đơn hàng tối thiểu không được âm.',
      );

      return;
    }

    if (
      startDate &&
      endDate &&
      new Date(startDate).getTime() >=
      new Date(endDate).getTime()
    ) {
      setError(
        'Ngày hết hạn phải sau ngày bắt đầu.',
      );

      return;
    }

    if (
      parsedUsageLimitPerCustomer !== null &&
      (
        !Number.isInteger(
          parsedUsageLimitPerCustomer,
        ) ||
        parsedUsageLimitPerCustomer < 0
      )
    ) {
      setError(
        'Giới hạn lượt dùng mỗi khách phải là số nguyên không âm.',
      );

      return;
    }

    if (
      parsedMaxTotalUses !== null &&
      (
        !Number.isInteger(
          parsedMaxTotalUses,
        ) ||
        parsedMaxTotalUses < 0
      )
    ) {
      setError(
        'Tổng lượt dùng tối đa phải là số nguyên không âm.',
      );

      return;
    }

    const commonInput = {
      discountType,

      discountValue:
        parsedDiscountValue,

      maxDiscountAmount:
        discountType === 'PERCENTAGE'
          ? parsedMaxDiscountAmount
          : null,

      minOrderValue:
        parsedMinOrderValue,

      startDate:
        toStartDateTime(startDate),

      endDate:
        toEndDateTime(endDate),

      usageLimitPerCustomer:
        parsedUsageLimitPerCustomer,

      maxTotalUses:
        parsedMaxTotalUses,
    };

    setSubmitting(true);

    try {
      if (isEditMode && id) {
        const input: UpdateVoucherInput = {
          ...commonInput,
          active,
        };

        await updateVoucher(
          id,
          input,
        );
      } else {
        const input: CreateVoucherInput = {
          code: normalizedCode,
          ...commonInput,
        };

        await createVoucher(input);
      }

      navigate('/vouchers', {
        replace: true,
      });
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  /* ==================== Cancel ==================== */

  const handleCancel = () => {
    if (submitting) {
      return;
    }

    navigate('/vouchers');
  };

  /* ==================== Loading ==================== */

  if (loading) {
    return (
      <div className="voucher-form-page">
        <header className="voucher-form-page__header">
          <h1 className="voucher-form-page__title">
            Chỉnh Sửa Chiến Dịch Voucher
          </h1>
        </header>

        <div className="voucher-form-card voucher-form-card--loading">
          Đang tải dữ liệu voucher…
        </div>
      </div>
    );
  }

  return (
    <div className="voucher-form-page">
      {/* ==================== Header ==================== */}

      <header className="voucher-form-page__header">
        <h1 className="voucher-form-page__title">
          {isEditMode
            ? 'Chỉnh Sửa Chiến Dịch Voucher'
            : 'Tạo Voucher Mới'}
        </h1>
      </header>

      {/* ==================== Error ==================== */}

      {error && (
        <div className="voucher-form-page__error">
          {error}
        </div>
      )}

      {/* ==================== Form ==================== */}

      <form
        className="voucher-form-card"
        onSubmit={handleSubmit}
      >
        {/* ==================== Mã Voucher ==================== */}

        <div className="voucher-form-field">
          <label
            className="voucher-form-field__label"
            htmlFor="voucher-code"
          >
            Mã Voucher (Alphanumeric)
          </label>

          <input
            id="voucher-code"
            className={`voucher-form-field__control ${isEditMode
                ? 'voucher-form-field__control--readonly'
                : ''
              }`}
            type="text"
            value={code}
            maxLength={50}
            disabled={
              isEditMode ||
              submitting
            }
            placeholder="Ví dụ: SUMMER50K"
            onChange={(event) => {
              const normalizedValue =
                event.target.value
                  .toUpperCase()
                  .replace(
                    /[^A-Z0-9]/g,
                    '',
                  );

              setCode(normalizedValue);
            }}
            required
          />
        </div>

        {/* ==================== Loại chiết khấu ==================== */}

        <div className="voucher-form-field">
          <label
            className="voucher-form-field__label"
            htmlFor="voucher-discount-type"
          >
            Loại chiết khấu
          </label>

          <select
            id="voucher-discount-type"
            className="voucher-form-field__control voucher-form-field__control--discount-type"
            value={discountType}
            disabled={submitting}
            aria-label="Loại chiết khấu"
            onChange={(event) => {
              const nextDiscountType =
                event.target.value as
                | DiscountType
                | '';

              setDiscountType(
                nextDiscountType,
              );

              if (
                nextDiscountType !==
                'PERCENTAGE'
              ) {
                setMaxDiscountAmount('');
              }
            }}
            required
          >
            <option value="">
              Chọn loại chiết khấu
            </option>

            <option value="PERCENTAGE">
              Giảm theo phần trăm (%)
            </option>

            <option value="FIXED_AMOUNT">
              Số tiền mặt cố định
            </option>
          </select>
        </div>

        {/* ==================== Giá trị giảm ==================== */}

        <div className="voucher-form-field">
          <label
            className="voucher-form-field__label"
            htmlFor="voucher-discount-value"
          >
            Giá trị giảm
          </label>

          <input
            id="voucher-discount-value"
            className="voucher-form-field__control"
            type="number"
            min="0"
            step="any"
            value={discountValue}
            disabled={submitting}
            placeholder="Ví dụ: 15 hoặc 15000"
            onChange={(event) =>
              setDiscountValue(
                event.target.value,
              )
            }
            required
          />
        </div>

        {/* ==================== Mức giảm tối đa ==================== */}

        {isPercentage && (
          <div className="voucher-form-field">
            <label
              className="voucher-form-field__label"
              htmlFor="voucher-max-discount"
            >
              Mức giảm tối đa (VND)
            </label>

            <input
              id="voucher-max-discount"
              className="voucher-form-field__control"
              type="number"
              min="0"
              step="any"
              value={maxDiscountAmount}
              disabled={submitting}
              placeholder="Ví dụ: 30000"
              onChange={(event) =>
                setMaxDiscountAmount(
                  event.target.value,
                )
              }
              required
            />
          </div>
        )}

        {/* ==================== Đơn hàng tối thiểu ==================== */}

        <div className="voucher-form-field">
          <label
            className="voucher-form-field__label"
            htmlFor="voucher-min-order"
          >
            Giá trị đơn hàng tối thiểu (VND)
          </label>

          <input
            id="voucher-min-order"
            className="voucher-form-field__control"
            type="number"
            min="0"
            step="any"
            value={minOrderValue}
            disabled={submitting}
            placeholder="Ví dụ: 50000"
            onChange={(event) =>
              setMinOrderValue(
                event.target.value,
              )
            }
          />
        </div>

        {/* ==================== Thời hạn ==================== */}

        {isEditMode ? (
          <div className="voucher-form-field">
            <span className="voucher-form-field__label">
              Hạn hiệu lực
            </span>

            <div className="voucher-form-date-grid">
              <label className="voucher-form-date-field">
                <span className="voucher-form-date-field__label">
                  Ngày bắt đầu
                </span>

                <input
                  className="voucher-form-field__control"
                  type="date"
                  value={startDate}
                  disabled={submitting}
                  onChange={(event) =>
                    setStartDate(
                      event.target.value,
                    )
                  }
                />
              </label>

              <label className="voucher-form-date-field">
                <span className="voucher-form-date-field__label">
                  Ngày hết hạn
                </span>

                <input
                  className="voucher-form-field__control"
                  type="date"
                  value={endDate}
                  disabled={submitting}
                  onChange={(event) =>
                    setEndDate(
                      event.target.value,
                    )
                  }
                />
              </label>
            </div>
          </div>
        ) : (
          <>
            <div className="voucher-form-field">
              <label
                className="voucher-form-field__label"
                htmlFor="voucher-start-date"
              >
                Hạn hiệu lực (Ngày bắt đầu)
              </label>

              <input
                id="voucher-start-date"
                className="voucher-form-field__control"
                type="date"
                value={startDate}
                disabled={submitting}
                onChange={(event) =>
                  setStartDate(
                    event.target.value,
                  )
                }
              />
            </div>

            <div className="voucher-form-field">
              <label
                className="voucher-form-field__label"
                htmlFor="voucher-end-date"
              >
                Hạn hiệu lực (Ngày hết hạn)
              </label>

              <input
                id="voucher-end-date"
                className="voucher-form-field__control"
                type="date"
                value={endDate}
                disabled={submitting}
                onChange={(event) =>
                  setEndDate(
                    event.target.value,
                  )
                }
              />
            </div>
          </>
        )}

        {/* ==================== Trạng thái hoạt động ==================== */}

        {isEditMode && (
          <div className="voucher-form-field">
            <label
              className="voucher-form-field__label"
              htmlFor="voucher-status"
            >
              Trạng thái hoạt động
            </label>

            <input
              id="voucher-status"
              className="voucher-form-field__control voucher-form-field__control--blank-status"
              type="text"
              value=""
              disabled
              readOnly
              aria-label="Trạng thái hoạt động"
            />
          </div>
        )}

        {/* ==================== Giới hạn sử dụng ==================== */}

        <div className="voucher-form-two-columns">
          <div className="voucher-form-field">
            <label
              className="voucher-form-field__label"
              htmlFor="voucher-per-customer"
            >
              Giới hạn lượt dùng / khách
            </label>

            <input
              id="voucher-per-customer"
              className="voucher-form-field__control"
              type="number"
              min="0"
              step="1"
              value={
                usageLimitPerCustomer
              }
              disabled={submitting}
              onChange={(event) =>
                setUsageLimitPerCustomer(
                  event.target.value,
                )
              }
            />
          </div>

          <div className="voucher-form-field">
            <label
              className="voucher-form-field__label"
              htmlFor="voucher-max-total"
            >
              Tổng lượt dùng tối đa
            </label>

            <input
              id="voucher-max-total"
              className="voucher-form-field__control"
              type="number"
              min="0"
              step="1"
              value={maxTotalUses}
              disabled={submitting}
              onChange={(event) =>
                setMaxTotalUses(
                  event.target.value,
                )
              }
            />
          </div>
        </div>

        {/* ==================== Buttons ==================== */}

        <div className="voucher-form-actions">
          <button
            type="submit"
            className="voucher-form-button voucher-form-button--primary"
            disabled={submitting}
          >
            {submitting
              ? 'ĐANG LƯU…'
              : isEditMode
                ? 'LƯU THAY ĐỔI'
                : 'TẠO VOUCHER'}
          </button>

          <button
            type="button"
            className="voucher-form-button voucher-form-button--cancel"
            disabled={submitting}
            onClick={handleCancel}
          >
            HỦY BỎ
          </button>
        </div>
      </form>
    </div>
  );
}