import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { getMenuItem, type MenuItemDetail as MenuItemDetailType } from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function MenuItemDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [item, setItem] = useState<MenuItemDetailType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError('');
    getMenuItem(id)
      .then(setItem)
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '50px', color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>
        Đang tải thông tin món ăn…
      </div>
    );
  }

  if (error) {
    return <div className="alert alert--error" style={{ margin: '20px 0' }}>{error}</div>;
  }

  if (!item) {
    return (
      <div style={{ textAlign: 'center', padding: '50px', color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>
        Không tìm thấy món ăn.
      </div>
    );
  }

  const isDrink = !item.categoryName?.toLowerCase().includes('bánh') &&
    !item.categoryName?.toLowerCase().includes('pastry') &&
    !item.categoryName?.toLowerCase().includes('food');

  const defaultDrinkToppings = [
    { name: 'Sữa Yến Mạch (Oat Milk)', price: 10000 },
    { name: 'Trân Châu Đen', price: 5000 },
    { name: 'Kem Cheese', price: 10000 },
  ];

  const toppingsList = Array.isArray(item.toppings) && item.toppings.length > 0
    ? item.toppings
    : (isDrink ? defaultDrinkToppings : []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', fontFamily: 'Roboto, sans-serif', maxWidth: '1000px', margin: '0 auto', width: '100%' }}>

      {/* ── Page Header ── */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '16px',
        }}
      >
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11' }}>
          Chi Tiết Món Ăn
        </h1>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          {/* Chỉnh Sửa button (Removed "Quay Lại" button per user request) */}
          <Link
            to={`/catalog/${item.id}/edit`}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              height: '40px',
              padding: '0 20px',
              background: '#3D2314',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '16px',
              fontWeight: 600,
              textDecoration: 'none',
              cursor: 'pointer',
            }}
          >
            Chỉnh Sửa
          </Link>
        </div>
      </div>

      {/* ── Main Detail Card ── */}
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '31px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
          display: 'flex',
          flexDirection: 'column',
          gap: '24px',
        }}
      >
        {/* Item Image & Title Header */}
        <div style={{ display: 'flex', gap: '30px', alignItems: 'flex-start' }}>
          {/* Image Thumbnail */}
          <div
            style={{
              width: '150px',
              height: '150px',
              background: '#F5ECE1',
              borderRadius: '12px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
              textAlign: 'center',
              padding: '10px',
              boxSizing: 'border-box',
            }}
          >
            {item.imageUrl ? (
              <img
                src={item.imageUrl}
                alt={item.name}
                style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '8px' }}
              />
            ) : (
              <>
                <span style={{ fontSize: '14px', fontWeight: 600, color: '#C89D7C', marginBottom: '4px' }}>
                  [ Ảnh Món Ăn ]
                </span>
                <span style={{ fontSize: '12px', color: '#C89D7C' }}>
                  {item.name.toLowerCase().replace(/\s+/g, '_')}.png
                </span>
              </>
            )}
          </div>

          {/* Name & Status */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', flex: 1 }}>
            <h2 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#3D2314' }}>
              {item.name}
            </h2>

            <div>
              <span
                style={{
                  display: 'inline-block',
                  padding: '4px 12px',
                  borderRadius: '15px',
                  fontSize: '13px',
                  fontWeight: 600,
                  background: item.active ? '#E8F5E9' : '#FFEBEE',
                  color: item.active ? '#2E7D32' : '#C62828',
                }}
              >
                {item.active ? '● Đang bán (Available)' : '○ Tạm ngưng (Unavailable)'}
              </span>
            </div>
          </div>
        </div>

        {/* Metadata Grid Row */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(4, 1fr)',
            gap: '20px',
            paddingBottom: '20px',
            borderBottom: '1px solid #F2EDE8',
          }}
        >
          <div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', marginBottom: '4px' }}>
              Danh Mục (Category)
            </div>
            <div style={{ fontSize: '16px', fontWeight: 500, color: '#2C1A11' }}>
              {item.categoryName || '—'}
            </div>
          </div>

          <div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', marginBottom: '4px' }}>
              Giá Bán (Price)
            </div>
            <div style={{ fontSize: '16px', fontWeight: 500, color: '#2C1A11' }}>
              {item.price.toLocaleString('vi-VN')} VND
            </div>
          </div>

          <div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', marginBottom: '4px' }}>
              Barcode / SKU
            </div>
            <div style={{ fontSize: '16px', fontWeight: 500, color: '#2C1A11' }}>
              {item.barcode || '—'}
            </div>
          </div>

          <div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#8C766C', marginBottom: '4px' }}>
              Mã Tìm Nhanh (Abbr)
            </div>
            <div style={{ fontSize: '16px', fontWeight: 500, color: '#2C1A11' }}>
              {item.abbreviation || '—'}
            </div>
          </div>
        </div>

        {/* Description Section */}
        <div>
          <div style={{ fontSize: '16px', fontWeight: 600, color: '#3D2314', marginBottom: '8px' }}>
            Mô Tả (Description)
          </div>
          <div style={{ fontSize: '16px', color: '#5C3826', lineHeight: '25px' }}>
            {item.description || 'Chưa có thông tin mô tả chi tiết cho món ăn này.'}
          </div>
        </div>

        {/* Recipe Formulation Section */}
        <div>
          <div style={{ fontSize: '16px', fontWeight: 600, color: '#3D2314', marginBottom: '8px' }}>
            Định Lượng Nguyên Liệu (Recipe Formulation)
          </div>
          {item.recipe && item.recipe.length > 0 ? (
            <ul style={{ margin: 0, paddingLeft: '20px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
              {item.recipe.map((r, i) => (
                <li key={i} style={{ fontSize: '16px', color: '#5C3826', lineHeight: '25px' }}>
                  {r.quantity}{r.unit} {r.rawMaterialName || 'Nguyên liệu'}
                </li>
              ))}
            </ul>
          ) : (
            <div style={{ fontSize: '15px', color: '#8C766C' }}>
              Chưa có công thức định lượng nguyên liệu được thiết lập.
            </div>
          )}
        </div>

        {/* Associated Toppings Section - Only render if real toppings exist */}
        {toppingsList.length > 0 && (
          <div>
            <div style={{ fontSize: '16px', fontWeight: 600, color: '#3D2314', marginBottom: '10px' }}>
              Tùy Chọn Kèm Theo (Associated Toppings)
            </div>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              {toppingsList.map((top: any, idx: number) => (
                <span
                  key={idx}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    padding: '6px 12px',
                    background: '#F5ECE1',
                    borderRadius: '4px',
                    fontSize: '13px',
                    fontWeight: 600,
                    color: '#2C1A11',
                  }}
                >
                  {top.name || String(top)} {top.price ? `(+${top.price.toLocaleString('vi-VN')} VND)` : ''}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Bottom Actions Row */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'flex-end',
            gap: '12px',
            borderTop: '1px solid #F2EDE8',
            paddingTop: '20px',
            marginTop: '10px',
          }}
        >
          <button
            type="button"
            onClick={() => navigate(`/catalog/${item.id}/edit`)}
            style={{
              height: '40px',
              padding: '0 20px',
              background: '#3D2314',
              border: 'none',
              borderRadius: '8px',
              color: '#FFFFFF',
              fontSize: '16px',
              fontWeight: 600,
              cursor: 'pointer',
              fontFamily: 'Roboto, sans-serif',
            }}
          >
            Chỉnh sửa món này
          </button>
        </div>
      </div>
    </div>
  );
}
