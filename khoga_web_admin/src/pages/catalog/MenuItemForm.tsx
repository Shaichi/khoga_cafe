import { useEffect, useState, type FormEvent, type ChangeEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  createMenuItem,
  getMenuItem,
  updateMenuItem,
  listCategories,
  listRawMaterials,
  type Category,
  type RawMaterial,
  type MenuItemInput,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

interface RecipeItemState {
  rawMaterialId: string;
  rawMaterialName: string;
  quantity: number;
  unit: string;
}

interface ToppingItemState {
  id?: string;
  name: string;
  price: number;
  selected: boolean;
}

export default function MenuItemForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  // Basic Form States
  const [name, setName] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState('');
  const [barcode, setBarcode] = useState('');
  const [description, setDescription] = useState('');
  const [imageUrl, setImageUrl] = useState('');

  // Image Upload Preview
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  // Recipe (Định lượng nguyên liệu)
  const [recipeLines, setRecipeLines] = useState<RecipeItemState[]>([]);
  const [selectedMatId, setSelectedMatId] = useState('');
  const [matQuantity, setMatQuantity] = useState('');

  // Toppings (Tùy chọn kèm theo)
  const [toppings, setToppings] = useState<ToppingItemState[]>([
    { name: 'Trân châu trắng', price: 5000, selected: true },
    { name: 'Thạch đào', price: 5000, selected: true },
    { name: 'Sữa yến mạch', price: 10000, selected: true },
    { name: 'Kem Macchiato', price: 10000, selected: true },
  ]);
  const [newToppingName, setNewToppingName] = useState('');
  const [newToppingPrice, setNewToppingPrice] = useState('');

  // Master Data
  const [categories, setCategories] = useState<Category[]>([]);
  const [materials, setMaterials] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    Promise.all([
      listCategories(true).catch(() => []),
      listRawMaterials().catch(() => []),
      id ? getMenuItem(id) : Promise.resolve(null),
    ])
      .then(([cats, mats, item]) => {
        setCategories(cats);
        setMaterials(mats.filter((m) => m.active));
        if (item) {
          setName(item.name);
          setPrice(item.price.toString());
          setCategoryId(item.categoryId ?? '');
          setBarcode(item.barcode ?? '');
          setDescription(item.description ?? '');
          setImageUrl(item.imageUrl ?? '');
          if (item.imageUrl) setImagePreview(item.imageUrl);
          
          if (item.recipe) {
            setRecipeLines(
              item.recipe.map((r) => ({
                rawMaterialId: r.rawMaterialId,
                rawMaterialName: r.rawMaterialName || '',
                quantity: r.quantity,
                unit: r.unit,
              }))
            );
          }
        }
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id]);

  // Handle local image file upload
  const handleImageFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        setError('Kích thước ảnh vượt quá 2MB. Vui lòng chọn ảnh nhỏ hơn.');
        return;
      }
      setError('');
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setImagePreview(result);
        setImageUrl(result);
      };
      reader.readAsDataURL(file);
    }
  };

  // Add Recipe Formulation line from dropdown
  const handleAddRecipeLine = () => {
    if (!selectedMatId || !matQuantity || Number(matQuantity) <= 0) return;
    const mat = materials.find((m) => m.id === selectedMatId);
    if (!mat) return;

    // Avoid duplicates
    if (recipeLines.some((l) => l.rawMaterialId === mat.id)) {
      setRecipeLines(
        recipeLines.map((l) =>
          l.rawMaterialId === mat.id
            ? { ...l, quantity: Number(matQuantity) }
            : l
        )
      );
    } else {
      setRecipeLines([
        ...recipeLines,
        {
          rawMaterialId: mat.id,
          rawMaterialName: mat.name,
          quantity: Number(matQuantity),
          unit: mat.unit,
        },
      ]);
    }

    setSelectedMatId('');
    setMatQuantity('');
  };

  const handleRemoveRecipeLine = (rawMatId: string) => {
    setRecipeLines(recipeLines.filter((l) => l.rawMaterialId !== rawMatId));
  };

  // Topping handlers
  const handleToggleTopping = (index: number) => {
    setToppings(
      toppings.map((t, i) => (i === index ? { ...t, selected: !t.selected } : t))
    );
  };

  const handleAddTopping = () => {
    if (!newToppingName.trim()) return;
    const priceVal = Number(newToppingPrice) || 0;
    setToppings([
      ...toppings,
      { name: newToppingName.trim(), price: priceVal, selected: true },
    ]);
    setNewToppingName('');
    setNewToppingPrice('');
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    if (!name.trim()) {
      setError('Vui lòng nhập tên món ăn');
      return;
    }
    if (!price || Number(price) <= 0) {
      setError('Giá bán phải lớn hơn 0');
      return;
    }

    // Sanitize image URL: filter out long base64 data strings to prevent DB column overflow
    const safeImageUrl = imageUrl && !imageUrl.startsWith('data:') ? imageUrl.trim() : undefined;

    const input: MenuItemInput = {
      name: name.trim(),
      price: Number(price),
      description: description.trim() || undefined,
      categoryId: categoryId || null,
      barcode: barcode.trim() || undefined,
      imageUrl: safeImageUrl,
      recipe: recipeLines.map((l) => ({
        rawMaterialId: l.rawMaterialId,
        quantity: l.quantity,
        unit: l.unit,
      })),
    };

    setSubmitting(true);
    try {
      if (isEdit && id) await updateMenuItem(id, input);
      else await createMenuItem(input);
      navigate('/catalog');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '50px', color: '#8C766C', fontFamily: 'Roboto, sans-serif' }}>
        Đang tải thông tin form…
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px', fontFamily: 'Segoe UI, Roboto, sans-serif', maxWidth: '1062px', margin: '0 auto', width: '100%' }}>
      
      {/* ── Page Header (#149:1226) ── */}
      <div
        style={{
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '14px',
        }}
      >
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11' }}>
          {isEdit ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn Mới'}
        </h1>
      </div>

      {error && <div className="alert alert--error">{error}</div>}

      {/* ── Main Form Card (#149:1228) ── */}
      <form
        onSubmit={handleSubmit}
        style={{
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '31px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
          display: 'flex',
          flexDirection: 'column',
          gap: '30px',
        }}
      >
        {/* 2-Column Inputs Container (#149:1229) */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '30px', alignItems: 'start' }}>
          
          {/* ── LEFT COLUMN (485px) ── */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            
            {/* 1. Tên món */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Tên món *
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Nhập tên món ăn/thức uống"
                required
                style={{
                  height: '42px',
                  padding: '0 12px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '15px',
                  color: '#2C1A11',
                  outline: 'none',
                }}
              />
            </div>

            {/* 2. Danh mục */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Danh mục
              </label>
              <select
                aria-label="Danh mục"
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                style={{
                  height: '42px',
                  padding: '0 12px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '15px',
                  color: '#2C1A11',
                  outline: 'none',
                  cursor: 'pointer',
                }}
              >
                <option value="">— Chọn danh mục</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>

            {/* 3. Giá bán (VND) */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Giá bán (VND) *
              </label>
              <input
                type="number"
                step="any"
                min="0"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="Ví dụ: 35000"
                required
                style={{
                  height: '42px',
                  padding: '0 12px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '15px',
                  color: '#2C1A11',
                  outline: 'none',
                }}
              />
            </div>

            {/* 4. Mã vạch (SKU/Barcode) */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Mã vạch (SKU/Barcode)
              </label>
              <input
                type="text"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                placeholder="Nhập mã SKU"
                style={{
                  height: '42px',
                  padding: '0 12px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '15px',
                  color: '#2C1A11',
                  outline: 'none',
                }}
              />
            </div>

            {/* 5. Mô tả món ăn */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Mô tả món ăn
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Nhập mô tả"
                rows={4}
                style={{
                  height: '107px',
                  padding: '10px 12px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '15px',
                  color: '#2C1A11',
                  outline: 'none',
                  resize: 'vertical',
                }}
              />
            </div>
          </div>

          {/* ── RIGHT COLUMN (485px) ── */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            
            {/* 1. Hình ảnh món ăn (File Upload from Computer) */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Hình ảnh món ăn
              </label>
              
              <label
                style={{
                  height: '164px',
                  background: '#FAF8F5',
                  border: '2px dashed #C89D7C',
                  borderRadius: '8px',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  padding: '16px',
                  textAlign: 'center',
                  boxSizing: 'border-box',
                  position: 'relative',
                  overflow: 'hidden',
                }}
              >
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleImageFileChange}
                  style={{ display: 'none' }}
                />

                {imagePreview ? (
                  <div style={{ position: 'relative', width: '100%', height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                    <img
                      src={imagePreview}
                      alt="Preview"
                      style={{ maxHeight: '130px', maxWidth: '100%', objectFit: 'contain', borderRadius: '6px' }}
                    />
                    <div style={{ position: 'absolute', bottom: '0', background: 'rgba(0,0,0,0.6)', color: '#FFFFFF', padding: '2px 8px', borderRadius: '4px', fontSize: '11px' }}>
                      Nhấp để thay đổi ảnh
                    </div>
                  </div>
                ) : (
                  <>
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#C89D7C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: '8px' }}>
                      <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                      <circle cx="8.5" cy="8.5" r="1.5"/>
                      <polyline points="21 15 16 10 5 21"/>
                    </svg>
                    <span style={{ fontSize: '13px', fontWeight: 700, color: '#5C3826', marginBottom: '4px' }}>
                      Tải ảnh món ăn từ máy tính
                    </span>
                    <span style={{ fontSize: '11px', color: '#8C766C' }}>
                      Hỗ trợ JPG, PNG (Tối đa 2MB)
                    </span>
                  </>
                )}
              </label>

              {/* Optional Image URL Input */}
              <input
                type="text"
                placeholder="Hoặc nhập đường dẫn ảnh (http://...)"
                value={imageUrl.startsWith('data:') ? '' : imageUrl}
                onChange={(e) => {
                  setImageUrl(e.target.value);
                  setImagePreview(e.target.value || null);
                }}
                style={{
                  height: '36px',
                  padding: '0 10px',
                  background: '#FFFFFF',
                  border: '1px solid #E5DBCF',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#2C1A11',
                  outline: 'none',
                  marginTop: '4px',
                }}
              />
            </div>

            {/* 2. Topping đi kèm được phép sử dụng (Reusable custom toppings) */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Topping đi kèm được phép sử dụng
              </label>
              
              <div
                style={{
                  background: '#FAF8F5',
                  border: '1px solid #EADDD3',
                  borderRadius: '8px',
                  padding: '13px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '12px',
                }}
              >
                {/* Toppings Grid (Checkbox + Name + Price) */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  {toppings.map((top, idx) => (
                    <label
                      key={idx}
                      onClick={() => handleToggleTopping(idx)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '8px 10px',
                        background: '#FFFFFF',
                        border: top.selected ? '1px solid #C89D7C' : '1px solid #E5DBCF',
                        borderRadius: '6px',
                        cursor: 'pointer',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <input
                          type="checkbox"
                          checked={top.selected}
                          onChange={() => {}} // handled by parent label onClick
                          style={{ cursor: 'pointer' }}
                        />
                        <span style={{ fontSize: '13px', fontWeight: 700, color: '#5C3826' }}>
                          {top.name}
                        </span>
                      </div>
                      <span style={{ fontSize: '12px', color: '#8C766C', fontWeight: 600 }}>
                        +{top.price.toLocaleString('vi-VN')}₫
                      </span>
                    </label>
                  ))}
                </div>

                {/* Add New Topping Row (#149:1304) */}
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '4px' }}>
                  <input
                    type="text"
                    placeholder="Tên topping mới..."
                    value={newToppingName}
                    onChange={(e) => setNewToppingName(e.target.value)}
                    style={{
                      flex: 1,
                      height: '36px',
                      padding: '0 10px',
                      background: '#FFFFFF',
                      border: '1px solid #E5DBCF',
                      borderRadius: '8px',
                      fontSize: '13px',
                      color: '#2C1A11',
                      outline: 'none',
                    }}
                  />
                  <input
                    type="number"
                    placeholder="Giá cộng thêm..."
                    value={newToppingPrice}
                    onChange={(e) => setNewToppingPrice(e.target.value)}
                    style={{
                      width: '130px',
                      height: '36px',
                      padding: '0 10px',
                      background: '#FFFFFF',
                      border: '1px solid #E5DBCF',
                      borderRadius: '8px',
                      fontSize: '13px',
                      color: '#2C1A11',
                      outline: 'none',
                    }}
                  />
                  <button
                    type="button"
                    onClick={handleAddTopping}
                    style={{
                      height: '36px',
                      padding: '0 14px',
                      background: '#3D2314',
                      color: '#FFFFFF',
                      border: 'none',
                      borderRadius: '8px',
                      fontSize: '13px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    + Thêm
                  </button>
                </div>
              </div>
            </div>

            {/* 3. Công thức định lượng nguyên liệu (Recipe Mappings) */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
                Công thức định lượng nguyên liệu (Recipe Mappings)
              </label>

              {/* Recipe Lines Display Box (#149:1313) */}
              <div
                style={{
                  background: '#FAF8F5',
                  border: '1px solid #EADDD3',
                  borderRadius: '8px',
                  padding: '12px',
                  minHeight: '61px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'center',
                  gap: '8px',
                }}
              >
                {recipeLines.length === 0 ? (
                  <div style={{ textAlign: 'center', color: '#8C766C', fontSize: '13px' }}>
                    Chưa cấu hình nguyên liệu định lượng.
                  </div>
                ) : (
                  recipeLines.map((l) => (
                    <div
                      key={l.rawMaterialId}
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        background: '#FFFFFF',
                        border: '1px solid #E5DBCF',
                        borderRadius: '6px',
                        padding: '6px 12px',
                        fontSize: '13px',
                      }}
                    >
                      <span style={{ fontWeight: 600, color: '#2C1A11' }}>
                        • {l.quantity}{l.unit} {l.rawMaterialName}
                      </span>
                      <button
                        type="button"
                        onClick={() => handleRemoveRecipeLine(l.rawMaterialId)}
                        style={{
                          background: 'transparent',
                          border: 'none',
                          color: '#C62828',
                          fontWeight: 700,
                          cursor: 'pointer',
                          fontSize: '12px',
                        }}
                      >
                        Xóa
                      </button>
                    </div>
                  ))
                )}
              </div>

              {/* Select Raw Material & Add Quantity Row (#149:1315) */}
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '4px' }}>
                <select
                  aria-label="Chọn nguyên liệu"
                  value={selectedMatId}
                  onChange={(e) => setSelectedMatId(e.target.value)}
                  style={{
                    flex: 1,
                    height: '36px',
                    padding: '0 10px',
                    background: '#FFFFFF',
                    border: '1px solid #E5DBCF',
                    borderRadius: '8px',
                    fontSize: '13px',
                    color: '#2C1A11',
                    outline: 'none',
                    cursor: 'pointer',
                  }}
                >
                  <option value="">— Chọn nguyên liệu từ kho</option>
                  {materials.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name} ({m.unit})
                    </option>
                  ))}
                </select>

                <input
                  type="number"
                  step="any"
                  min="0"
                  placeholder="Lượng..."
                  value={matQuantity}
                  onChange={(e) => setMatQuantity(e.target.value)}
                  style={{
                    width: '100px',
                    height: '36px',
                    padding: '0 10px',
                    background: '#FFFFFF',
                    border: '1px solid #E5DBCF',
                    borderRadius: '8px',
                    fontSize: '13px',
                    color: '#2C1A11',
                    outline: 'none',
                  }}
                />

                <button
                  type="button"
                  onClick={handleAddRecipeLine}
                  style={{
                    height: '36px',
                    padding: '0 14px',
                    background: '#3D2314',
                    color: '#FFFFFF',
                    border: 'none',
                    borderRadius: '8px',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  + Định lượng
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* ── Bottom Action Buttons (#149:1321) ── */}
        <div
          style={{
            display: 'flex',
            gap: '12px',
            borderTop: '1px solid #F2EDE8',
            paddingTop: '20px',
          }}
        >
          <button
            type="submit"
            disabled={submitting}
            style={{
              height: '41px',
              padding: '0 24px',
              background: '#3D2314',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 700,
              cursor: submitting ? 'not-allowed' : 'pointer',
              fontFamily: 'Arial, sans-serif',
              letterSpacing: '0.5px',
            }}
          >
            {submitting ? 'ĐANG LƯU…' : isEdit ? 'LƯU THAY ĐỔI' : 'THÊM MÓN ĂN'}
          </button>

          <button
            type="button"
            onClick={() => navigate('/catalog')}
            style={{
              height: '41px',
              padding: '0 25px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              color: '#8C766C',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer',
              fontFamily: 'Arial, sans-serif',
            }}
          >
            HỦY BỎ
          </button>
        </div>
      </form>
    </div>
  );
}
