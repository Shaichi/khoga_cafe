import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  getMenuItem,
  listRawMaterials,
  type MenuItemDetail as MenuItemDetailData,
  type RawMaterial,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';
import './MenuItemDetail.css';

const vndFormatter = new Intl.NumberFormat('vi-VN');
const quantityFormatter = new Intl.NumberFormat('vi-VN', {
  maximumFractionDigits: 3,
});

function formatVnd(value: number): string {
  return `${vndFormatter.format(value)} VND`;
}

function getImageName(imageUrl: string | null): string {
  if (!imageUrl) return 'Chưa có ảnh';

  const cleanUrl = imageUrl.split('?')[0];
  const fileName = cleanUrl.split('/').pop();
  return fileName || 'Ảnh món ăn';
}

export default function MenuItemDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [item, setItem] = useState<MenuItemDetailData | null>(null);
  const [materials, setMaterials] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [imageFailed, setImageFailed] = useState(false);

  useEffect(() => {
    if (!id) {
      setError('Không tìm thấy mã món ăn.');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError('');
    setImageFailed(false);

    Promise.all([
      getMenuItem(id),
      listRawMaterials().catch(() => []),
    ])
      .then(([menuItem, rawMaterials]) => {
        setItem(menuItem);
        setMaterials(rawMaterials);
      })
      .catch((err) => setError(errorMessage(err)))
      .finally(() => setLoading(false));
  }, [id]);

  const materialCodeById = useMemo(
    () => new Map(materials.map((material) => [material.id, material.code])),
    [materials],
  );

  if (loading) {
    return <div className="catalog-detail-loading">Đang tải chi tiết món ăn…</div>;
  }

  if (error || !item) {
    return (
      <div className="catalog-detail-page">
        <div className="catalog-management-page__header">
          <h1 className="catalog-management-page__title">Chi Tiết Món Ăn</h1>
          <button
            type="button"
            className="catalog-button catalog-button--outline"
            onClick={() => navigate('/catalog')}
          >
            Quay Lại
          </button>
        </div>

        <div className="alert alert--error">{error || 'Không tìm thấy món ăn.'}</div>
      </div>
    );
  }

  const activeToppings = item.toppings.filter((topping) => topping.active);
  const showImage = Boolean(item.imageUrl) && !imageFailed;

  return (
    <div className="catalog-detail-page">
      <div className="catalog-management-page__header catalog-detail-page__header">
        <h1 className="catalog-management-page__title">Chi Tiết Món Ăn</h1>

        <div className="catalog-management-page__header-actions">
          <Link to="/catalog" className="catalog-button catalog-button--outline catalog-detail-page__top-button">
            Quay Lại
          </Link>
          <Link
            to={`/catalog/${item.id}/edit`}
            className="catalog-button catalog-button--primary catalog-detail-page__top-button"
          >
            Chỉnh Sửa
          </Link>
        </div>
      </div>

      <article className="menu-detail-card">
        <div className="menu-detail-card__hero">
          <div className="menu-detail-card__image-box">
            {showImage ? (
              <img
                src={item.imageUrl ?? ''}
                alt={item.name}
                className="menu-detail-card__image"
                onError={() => setImageFailed(true)}
              />
            ) : (
              <div className="menu-detail-card__image-placeholder">
                <span>[ Ảnh Món Ăn ]</span>
                <strong>{getImageName(item.imageUrl)}</strong>
              </div>
            )}
          </div>

          <div className="menu-detail-card__identity">
            <h2>{item.name}</h2>
            <span
              className={`menu-detail-status ${item.active ? 'menu-detail-status--active' : 'menu-detail-status--inactive'
                }`}
            >
              <span className="menu-detail-status__dot" />
              {item.active ? 'Đang bán (Available)' : 'Tạm ngưng (Unavailable)'}
            </span>
          </div>
        </div>

        <div className="menu-detail-meta-grid">
          <div className="menu-detail-meta">
            <span>Danh Mục (Category)</span>
            <strong>{item.categoryName || 'Chưa phân loại'}</strong>
          </div>
          <div className="menu-detail-meta">
            <span>Giá Bán (Price)</span>
            <strong>{formatVnd(item.price)}</strong>
          </div>
          <div className="menu-detail-meta">
            <span>Barcode / SKU</span>
            <strong>{item.barcode || '—'}</strong>
          </div>
          <div className="menu-detail-meta">
            <span>Mã Tìm Nhanh (Abbr)</span>
            <strong>{item.abbreviation || '—'}</strong>
          </div>
        </div>

        <div className="menu-detail-divider" />

        <section className="menu-detail-section">
          <h3>Mô Tả (Description)</h3>
          <p>{item.description || 'Chưa có mô tả cho món ăn này.'}</p>
        </section>

        <section className="menu-detail-section">
          <h3>Định Lượng Nguyên Liệu (Recipe Formulation)</h3>
          {item.recipe.length === 0 ? (
            <p>Chưa có định lượng nguyên liệu.</p>
          ) : (
            <ul className="menu-detail-recipe-list">
              {item.recipe.map((line) => {
                const materialCode = materialCodeById.get(line.rawMaterialId);
                return (
                  <li key={`${line.rawMaterialId}-${line.unit}`}>
                    {quantityFormatter.format(line.quantity)}{line.unit}{' '}
                    {line.rawMaterialName || line.rawMaterialId}
                    {materialCode ? ` (Mã kho: ${materialCode})` : ''}
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        <section className="menu-detail-section">
          <h3>Tùy Chọn Kèm Theo (Associated Toppings)</h3>
          {activeToppings.length === 0 ? (
            <p>Chưa có tùy chọn kèm theo.</p>
          ) : (
            <div className="menu-detail-toppings">
              {activeToppings.map((topping) => (
                <span className="menu-detail-topping" key={topping.id}>
                  {topping.name} (+{formatVnd(topping.price)})
                </span>
              ))}
            </div>
          )}
        </section>

        <div className="menu-detail-card__footer">
          <Link to="/catalog" className="catalog-button catalog-button--outline menu-detail-card__footer-button">
            Quay lại danh sách
          </Link>
          <Link
            to={`/catalog/${item.id}/edit`}
            className="catalog-button catalog-button--primary menu-detail-card__footer-button menu-detail-card__footer-button--edit"
          >
            Chỉnh sửa món này
          </Link>
        </div>
      </article>
    </div>
  );
}
