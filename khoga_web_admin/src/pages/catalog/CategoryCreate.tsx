import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { createCategory } from '../../api/catalog';
import { errorMessage } from '../../api/client';
import './CategoryCreate.css';

export default function CategoryCreate() {
    const navigate = useNavigate();

    const [name, setName] = useState('');
    const [description, setDescription] = useState('');
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();

        const normalizedName = name.trim();
        const normalizedDescription = description.trim();

        if (!normalizedName) {
            setError('Tên danh mục không được để trống.');
            return;
        }

        setSaving(true);
        setError('');

        try {
            await createCategory({
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

    return (
        <div className="category-create-page">
            <header className="category-create-page__header">
                <h1 className="category-create-page__title">
                    Thêm Danh Mục Mới
                </h1>
            </header>

            {error && (
                <div className="category-create-page__error">
                    {error}
                </div>
            )}

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
                        disabled={saving}
                        maxLength={255}
                        placeholder="Nhập tên danh mục (ví dụ: Trà trái cây)"
                        onChange={(event) => setName(event.target.value)}
                        autoFocus
                        required
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
                        disabled={saving}
                        maxLength={255}
                        placeholder="Nhập mô tả danh mục"
                        onChange={(event) => setDescription(event.target.value)}
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
                        value="Đang hiển thị"
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
                        {saving ? 'ĐANG TẠO…' : 'TẠO DANH MỤC'}
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
        </div>
    );
}