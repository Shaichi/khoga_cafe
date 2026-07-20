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
    listCategories,
    updateCategory,
    type Category,
} from '../../api/catalog';

import { errorMessage } from '../../api/client';
import './CategoryCreate.css';

export default function CategoryEdit() {
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();

    const [category, setCategory] =
        useState<Category | null>(null);

    const [name, setName] = useState('');
    const [description, setDescription] =
        useState('');

    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        const loadCategory = async () => {
            if (!id) {
                setError('Không tìm thấy mã danh mục.');
                setLoading(false);
                return;
            }

            setLoading(true);
            setError('');

            try {
                const categories = await listCategories();

                const foundCategory = categories.find(
                    (item) => item.id === id,
                );

                if (!foundCategory) {
                    setError('Danh mục không tồn tại.');
                    return;
                }

                setCategory(foundCategory);
                setName(foundCategory.name);
                setDescription(
                    foundCategory.description ?? '',
                );
            } catch (err) {
                setError(errorMessage(err));
            } finally {
                setLoading(false);
            }
        };

        void loadCategory();
    }, [id]);

    const handleSubmit = async (
        event: FormEvent<HTMLFormElement>,
    ) => {
        event.preventDefault();

        if (!id || !category) return;

        const normalizedName = name.trim();
        const normalizedDescription =
            description.trim();

        if (!normalizedName) {
            setError(
                'Tên danh mục không được để trống.',
            );
            return;
        }

        setSaving(true);
        setError('');

        try {
            await updateCategory(id, {
                name: normalizedName,
                description: normalizedDescription,
            });

            navigate('/catalog', {
                replace: true,
            });
        } catch (err) {
            setError(errorMessage(err));
        } finally {
            setSaving(false);
        }
    };

    const handleCancel = () => {
        if (saving) return;

        navigate('/catalog');
    };

    if (loading) {
        return (
            <div className="category-create-page">
                <header className="category-create-page__header">
                    <h1 className="category-create-page__title">
                        Chỉnh Sửa Danh Mục
                    </h1>
                </header>

                <div className="category-create-card">
                    Đang tải dữ liệu danh mục…
                </div>
            </div>
        );
    }

    return (
        <div className="category-create-page">
            <header className="category-create-page__header">
                <h1 className="category-create-page__title">
                    Chỉnh Sửa Danh Mục
                </h1>
            </header>

            {error && (
                <div className="category-create-page__error">
                    {error}
                </div>
            )}

            {category && (
                <form
                    className="category-create-card"
                    onSubmit={handleSubmit}
                >
                    <div className="category-create-field">
                        <label
                            className="category-create-field__label"
                            htmlFor="category-name"
                        >
                            Tên danh mục
                        </label>

                        <input
                            id="category-name"
                            className="category-create-field__input"
                            type="text"
                            value={name}
                            maxLength={255}
                            disabled={saving}
                            onChange={(event) =>
                                setName(event.target.value)
                            }
                            required
                            autoFocus
                        />
                    </div>

                    <div className="category-create-field">
                        <label
                            className="category-create-field__label"
                            htmlFor="category-description"
                        >
                            Mô tả chi tiết
                        </label>

                        <textarea
                            id="category-description"
                            className="category-create-field__textarea"
                            value={description}
                            maxLength={255}
                            disabled={saving}
                            onChange={(event) =>
                                setDescription(
                                    event.target.value,
                                )
                            }
                        />
                    </div>

                    <div className="category-create-field">
                        <label
                            className="category-create-field__label"
                            htmlFor="category-status"
                        >
                            Trạng thái hiển thị
                        </label>

                        <input
                            id="category-status"
                            className="category-create-field__input category-create-field__input--readonly"
                            type="text"
                            value={
                                category.active
                                    ? 'Đang hiển thị'
                                    : 'Tạm ẩn'
                            }
                            disabled
                            readOnly
                        />
                    </div>

                    <div className="category-create-actions">
                        <button
                            type="submit"
                            className="category-create-button category-create-button--primary"
                            disabled={saving}
                        >
                            {saving
                                ? 'ĐANG LƯU…'
                                : 'LƯU THAY ĐỔI'}
                        </button>

                        <button
                            type="button"
                            className="category-create-button category-create-button--cancel"
                            disabled={saving}
                            onClick={handleCancel}
                        >
                            HỦY BỎ
                        </button>
                    </div>
                </form>
            )}
        </div>
    );
}