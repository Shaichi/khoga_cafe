import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  addMenuItemTopping,
  createMenuItem,
  getMenuItem,
  linkMenuItemTopping,
  listAllToppings,
  listCategories,
  listRawMaterials,
  unlinkMenuItemTopping,
  updateMenuItem,
  updateMenuItemTopping,
  type Category,
  type MenuItemInput,
  type RawMaterial,
  type RecipeLine,
  type Topping,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';
import './MenuItemForm.css';

interface RecipeLineState {
  rawMaterialId: string;
  quantity: string;
  unit: string;
}

interface ToppingRowState {
  id: string;
  name: string;
  price: string;
  initialPrice: string;
  linked: boolean;
  initialLinked: boolean;
  recipe: RecipeLine[];
  isNew: boolean;
}

const normalizeNumber = (value: string) => Number(value.replace(/,/g, '').trim());

const toToppingRow = (topping: Topping, linked: boolean): ToppingRowState => ({
  id: topping.id,
  name: topping.name,
  price: String(topping.price),
  initialPrice: String(topping.price),
  linked,
  initialLinked: linked,
  recipe: topping.recipe ?? [],
  isNew: false,
});

export default function MenuItemForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [name, setName] = useState('');
  const [price, setPrice] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [barcode, setBarcode] = useState('');
  const [description, setDescription] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [imageFailed, setImageFailed] = useState(false);
  const [recipe, setRecipe] = useState<RecipeLineState[]>([]);
  const [toppings, setToppings] = useState<ToppingRowState[]>([]);

  const [newToppingName, setNewToppingName] = useState('');
  const [newToppingPrice, setNewToppingPrice] = useState('');
  const [selectedMaterialId, setSelectedMaterialId] = useState('');
  const [selectedQuantity, setSelectedQuantity] = useState('');

  const [categories, setCategories] = useState<Category[]>([]);
  const [materials, setMaterials] = useState<RawMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let cancelled = false;

    Promise.all([
      listCategories(true).catch(() => []),
      listRawMaterials().catch(() => []),
      listAllToppings().catch(() => []),
      id ? getMenuItem(id) : Promise.resolve(null),
    ])
      .then(([categoryList, materialList, allToppings, item]) => {
        if (cancelled) return;

        setCategories(categoryList);
        setMaterials(materialList.filter((material) => material.active));

        const assignedIds = new Set(item?.toppings.map((topping) => topping.id) ?? []);
        const mergedToppings = new Map<string, Topping>();
        allToppings.forEach((topping) => mergedToppings.set(topping.id, topping));
        item?.toppings.forEach((topping) => mergedToppings.set(topping.id, topping));
        setToppings(
          Array.from(mergedToppings.values()).map((topping) =>
            toToppingRow(topping, assignedIds.has(topping.id)),
          ),
        );

        if (item) {
          setName(item.name);
          setPrice(String(item.price));
          setCategoryId(item.categoryId ?? '');
          setBarcode(item.barcode ?? '');
          setDescription(item.description ?? '');
          setImageUrl(item.imageUrl ?? '');
          setRecipe(
            item.recipe.map((line) => ({
              rawMaterialId: line.rawMaterialId,
              quantity: String(line.quantity),
              unit: line.unit,
            })),
          );
        }
      })
      .catch((reason: unknown) => {
        if (!cancelled) setError(errorMessage(reason));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [id]);

  const materialById = useMemo(
    () => new Map(materials.map((material) => [material.id, material])),
    [materials],
  );

  const changeImageUrl = () => {
    const nextUrl = window.prompt('Nhập URL hình ảnh món ăn:', imageUrl);
    if (nextUrl === null) return;
    setImageUrl(nextUrl.trim());
    setImageFailed(false);
  };

  const toggleTopping = (rowId: string) => {
    setToppings((current) =>
      current.map((row) => (row.id === rowId ? { ...row, linked: !row.linked } : row)),
    );
  };

  const changeToppingPrice = (rowId: string, nextPrice: string) => {
    setToppings((current) =>
      current.map((row) => (row.id === rowId ? { ...row, price: nextPrice } : row)),
    );
  };

  const addLocalTopping = () => {
    const toppingName = newToppingName.trim();
    const toppingPrice = normalizeNumber(newToppingPrice);

    if (!toppingName) {
      setError('Vui lòng nhập tên topping mới.');
      return;
    }
    if (!Number.isFinite(toppingPrice) || toppingPrice < 0) {
      setError('Giá cộng thêm của topping phải là số không âm.');
      return;
    }

    const duplicated = toppings.some(
      (row) => row.name.trim().toLocaleLowerCase('vi-VN') === toppingName.toLocaleLowerCase('vi-VN'),
    );
    if (duplicated) {
      setError('Topping này đã tồn tại trong danh sách.');
      return;
    }

    setToppings((current) => [
      ...current,
      {
        id: `new-${crypto.randomUUID()}`,
        name: toppingName,
        price: String(toppingPrice),
        initialPrice: String(toppingPrice),
        linked: true,
        initialLinked: false,
        recipe: [],
        isNew: true,
      },
    ]);
    setNewToppingName('');
    setNewToppingPrice('');
    setError('');
  };

  const addRecipeLine = () => {
    const material = materialById.get(selectedMaterialId);
    const quantity = normalizeNumber(selectedQuantity);

    if (!material) {
      setError('Vui lòng chọn nguyên liệu cần định lượng.');
      return;
    }
    if (!Number.isFinite(quantity) || quantity <= 0) {
      setError('Lượng nguyên liệu phải lớn hơn 0.');
      return;
    }

    setRecipe((current) => {
      const existingIndex = current.findIndex((line) => line.rawMaterialId === material.id);
      if (existingIndex < 0) {
        return [
          ...current,
          {
            rawMaterialId: material.id,
            quantity: String(quantity),
            unit: material.unit,
          },
        ];
      }

      return current.map((line, index) =>
        index === existingIndex
          ? { ...line, quantity: String(quantity), unit: material.unit }
          : line,
      );
    });

    setSelectedMaterialId('');
    setSelectedQuantity('');
    setError('');
  };

  const removeRecipeLine = (rawMaterialId: string) => {
    setRecipe((current) => current.filter((line) => line.rawMaterialId !== rawMaterialId));
  };

  const cancel = () => {
    navigate(isEdit && id ? `/catalog/${id}` : '/catalog');
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');

    const numericPrice = normalizeNumber(price);
    if (!name.trim()) {
      setError('Tên món không được để trống.');
      return;
    }
    if (!Number.isFinite(numericPrice) || numericPrice < 0) {
      setError('Giá bán phải là số không âm.');
      return;
    }

    const invalidTopping = toppings.find((topping) => {
      const toppingPrice = normalizeNumber(topping.price);
      return !Number.isFinite(toppingPrice) || toppingPrice < 0;
    });
    if (invalidTopping) {
      setError(`Giá của topping "${invalidTopping.name}" không hợp lệ.`);
      return;
    }

    const payload: MenuItemInput = {
      name: name.trim(),
      price: numericPrice,
      description: description.trim() || undefined,
      categoryId: categoryId || null,
      barcode: barcode.trim() || undefined,
      imageUrl: imageUrl.trim() || undefined,
      recipe: recipe.map((line) => ({
        rawMaterialId: line.rawMaterialId,
        quantity: normalizeNumber(line.quantity),
        unit: line.unit,
      })),
    };

    setSubmitting(true);
    try {
      const savedItem = isEdit && id
        ? await updateMenuItem(id, payload)
        : await createMenuItem(payload);

      for (const topping of toppings) {
        const toppingPrice = normalizeNumber(topping.price);

        if (topping.isNew) {
          if (topping.linked) {
            await addMenuItemTopping(savedItem.id, {
              name: topping.name,
              price: toppingPrice,
              recipe: [],
              menuItemIds: [],
            });
          }
          continue;
        }

        if (toppingPrice !== normalizeNumber(topping.initialPrice)) {
          await updateMenuItemTopping(savedItem.id, topping.id, {
            name: topping.name,
            price: toppingPrice,
            recipe: topping.recipe.map((line) => ({
              rawMaterialId: line.rawMaterialId,
              quantity: line.quantity,
              unit: line.unit,
            })),
            menuItemIds: [],
          });
        }

        if (topping.linked !== topping.initialLinked) {
          if (topping.linked) {
            await linkMenuItemTopping(savedItem.id, topping.id);
          } else {
            await unlinkMenuItemTopping(savedItem.id, topping.id);
          }
        }
      }

      navigate(`/catalog/${savedItem.id}`);
    } catch (reason: unknown) {
      setError(errorMessage(reason));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="full-center">Đang tải…</div>;

  return (
    <div className="menu-edit-page">
      <div className="catalog-management-page__header menu-edit-page__header">
        <h1 className="catalog-management-page__title">
          {isEdit ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn'}
        </h1>
      </div>

      {error && <div className="alert alert--error menu-edit-page__alert">{error}</div>}

      <form className="menu-edit-card" onSubmit={handleSubmit}>
        <div className="menu-edit-grid">
          <section className="menu-edit-column menu-edit-column--left">
            <label className="menu-edit-field">
              <span>Tên món</span>
              <input
                value={name}
                onChange={(event) => setName(event.target.value)}
                placeholder="Nhập tên món"
                required
              />
            </label>

            <label className="menu-edit-field">
              <span>Danh mục</span>
              <select value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
                <option value="">— Chưa phân loại —</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>{category.name}</option>
                ))}
              </select>
            </label>

            <label className="menu-edit-field">
              <span>Giá bán (VND)</span>
              <input
                type="number"
                min="0"
                step="any"
                value={price}
                onChange={(event) => setPrice(event.target.value)}
                placeholder="0"
                required
              />
            </label>

            <label className="menu-edit-field">
              <span>Mã vạch (SKU/Barcode)</span>
              <input
                value={barcode}
                onChange={(event) => setBarcode(event.target.value)}
                placeholder="Nhập mã vạch"
              />
            </label>

            <label className="menu-edit-field menu-edit-field--description">
              <span>Mô tả món ăn</span>
              <textarea
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                placeholder="Nhập mô tả món ăn"
              />
            </label>
          </section>

          <section className="menu-edit-column menu-edit-column--right">
            <div className="menu-edit-image-section">
              <span className="menu-edit-section-label">Hình ảnh món ăn</span>
              <button
                type="button"
                className="menu-edit-image-picker"
                title="Bấm để nhập URL hình ảnh"
                onClick={changeImageUrl}
              >
                {imageUrl && !imageFailed ? (
                  <img src={imageUrl} alt={name || 'Hình ảnh món ăn'} onError={() => setImageFailed(true)} />
                ) : (
                  <span>w:h</span>
                )}
              </button>
            </div>

            <div className="menu-edit-section">
              <h2>Topping đi kèm được phép sử dụng</h2>
              <div className="menu-edit-topping-box">
                {toppings.length === 0 ? (
                  <p className="menu-edit-empty">Chưa có topping.</p>
                ) : (
                  <div className="menu-edit-topping-grid">
                    {toppings.map((topping) => (
                      <label className="menu-edit-topping-card" key={topping.id}>
                        <input
                          type="checkbox"
                          checked={topping.linked}
                          onChange={() => toggleTopping(topping.id)}
                        />
                        <strong>{topping.name}</strong>
                        <span className="menu-edit-topping-plus">+</span>
                        <input
                          className="menu-edit-topping-price"
                          type="number"
                          min="0"
                          step="any"
                          value={topping.price}
                          onChange={(event) => changeToppingPrice(topping.id, event.target.value)}
                          aria-label={`Giá topping ${topping.name}`}
                        />
                      </label>
                    ))}
                  </div>
                )}
              </div>

              <div className="menu-edit-add-topping">
                <input
                  value={newToppingName}
                  onChange={(event) => setNewToppingName(event.target.value)}
                  placeholder="Tên topping mới..."
                />
                <input
                  type="number"
                  min="0"
                  step="any"
                  value={newToppingPrice}
                  onChange={(event) => setNewToppingPrice(event.target.value)}
                  placeholder="Giá cộng thêm..."
                />
                <button type="button" onClick={addLocalTopping}>+ Thêm</button>
              </div>
            </div>

            <div className="menu-edit-section menu-edit-recipe-section">
              <h2>Công thức định lượng nguyên liệu (Recipe Mappings)</h2>
              <div className="menu-edit-recipe-box">
                {recipe.length === 0 ? (
                  <p className="menu-edit-empty">Chưa có nguyên liệu trong công thức.</p>
                ) : (
                  recipe.map((line) => {
                    const material = materialById.get(line.rawMaterialId);
                    return (
                      <div className="menu-edit-recipe-row" key={line.rawMaterialId}>
                        <strong>{material?.name ?? line.rawMaterialId}</strong>
                        <span>{line.quantity} {line.unit}</span>
                        <button type="button" onClick={() => removeRecipeLine(line.rawMaterialId)}>Xóa</button>
                      </div>
                    );
                  })
                )}
              </div>

              <div className="menu-edit-add-recipe">
                <select
                  value={selectedMaterialId}
                  onChange={(event) => setSelectedMaterialId(event.target.value)}
                >
                  <option value="">— Chọn nguyên liệu —</option>
                  {materials.map((material) => (
                    <option key={material.id} value={material.id}>
                      {material.name} ({material.unit})
                    </option>
                  ))}
                </select>
                <input
                  type="number"
                  min="0"
                  step="any"
                  value={selectedQuantity}
                  onChange={(event) => setSelectedQuantity(event.target.value)}
                  placeholder="Lượng..."
                />
                <button type="button" onClick={addRecipeLine}>+ Định lượng</button>
              </div>
            </div>
          </section>
        </div>

        <div className="menu-edit-actions">
          <button type="submit" className="menu-edit-save" disabled={submitting}>
            {submitting ? 'ĐANG LƯU…' : isEdit ? 'LƯU THAY ĐỔI' : 'TẠO MÓN'}
          </button>
          <button type="button" className="menu-edit-cancel" onClick={cancel} disabled={submitting}>
            HỦY BỎ
          </button>
        </div>
      </form>
    </div>
  );
}
