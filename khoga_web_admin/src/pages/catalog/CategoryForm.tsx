import { useEffect, useState, type FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  createCategory,
  updateCategory,
  listCategories,
  type Category,
} from '../../api/catalog';
import { errorMessage } from '../../api/client';

export default function CategoryForm() {
  const { id } = useParams();
  const isEdit = Boolean(id && id !== 'new');
  const navigate = useNavigate();

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [active, setActive] = useState(true);
  const [loading, setLoading] = useState(isEdit);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!isEdit || !id) return;
    setLoading(true);
    setError('');
    listCategories()
      .then((cats) => {
        const found = cats.find((c) => c.id === id);
        if (found) {
          setName(found.name);
          setDescription(found.description || '');
          setActive(found.active);
        } else {
          setError('Không tìm thấy danh mục');
        }
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  }, [id, isEdit]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên danh mục');
      return;
    }
    setError('');
    setSubmitting(true);

    try {
      if (isEdit && id) {
        await updateCategory(id, { name: name.trim(), description: description.trim() || undefined });
      } else {
        await createCategory({ name: name.trim(), description: description.trim() || undefined });
      }
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
        Đang tải thông tin danh mục…
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', fontFamily: 'Segoe UI, Roboto, sans-serif' }}>
      
      {/* ── Page Header (#149:531) ── */}
      <div
        style={{
          borderBottom: '1px solid #EADDD3',
          paddingBottom: '14px',
        }}
      >
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 700, color: '#2C1A11' }}>
          {isEdit ? 'Chỉnh Sửa Danh Mục' : 'Thêm Danh Mục Mới'}
        </h1>
      </div>

      {error && <div className="alert alert--error" style={{ maxWidth: '662px' }}>{error}</div>}

      {/* ── Form Card (#149:533) ── */}
      <form
        onSubmit={handleSubmit}
        style={{
          width: '662px',
          background: '#FFFFFF',
          border: '1px solid #EADDD3',
          borderRadius: '12px',
          padding: '31px',
          boxShadow: '0px 4px 12px 0px rgba(0, 0, 0, 0.02)',
          display: 'flex',
          flexDirection: 'column',
          gap: '24px',
          boxSizing: 'border-box',
        }}
      >
        {/* Field 1: Tên danh mục (#149:534) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
            Tên danh mục *
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Nhập tên danh mục (ví dụ: Trà trái cây)"
            required
            style={{
              height: '39px',
              padding: '0 10px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#2C1A11',
              outline: 'none',
              width: '100%',
              boxSizing: 'border-box',
            }}
          />
        </div>

        {/* Field 2: Mô tả chi tiết (#149:538) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
            Mô tả chi tiết
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Nhập mô tả danh mục"
            rows={3}
            style={{
              height: '90px',
              padding: '10px',
              background: '#FFFFFF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#2C1A11',
              outline: 'none',
              resize: 'vertical',
              width: '100%',
              boxSizing: 'border-box',
            }}
          />
        </div>

        {/* Field 3: Trạng thái hiển thị (#149:542) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          <label style={{ fontSize: '16px', fontWeight: 700, color: '#5C3826' }}>
            Trạng thái hiển thị
          </label>
          <select
            aria-label="Trạng thái hiển thị"
            value={active ? 'ACTIVE' : 'INACTIVE'}
            onChange={(e) => setActive(e.target.value === 'ACTIVE')}
            style={{
              height: '41px',
              padding: '0 10px',
              background: '#EFEFEF',
              border: '1px solid #E5DBCF',
              borderRadius: '8px',
              fontSize: '15px',
              color: '#2C1A11',
              outline: 'none',
              cursor: 'pointer',
              width: '100%',
              boxSizing: 'border-box',
            }}
          >
            <option value="ACTIVE">Hoạt động (Hiển thị trong menu)</option>
            <option value="INACTIVE">Lưu trữ (Ẩn khỏi menu)</option>
          </select>
        </div>

        {/* Action Buttons (#149:545) */}
        <div style={{ display: 'flex', gap: '15px', marginTop: '10px' }}>
          <button
            type="submit"
            disabled={submitting}
            style={{
              width: '152px',
              height: '41px',
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
            {submitting ? 'ĐANG LƯU…' : isEdit ? 'LƯU DANH MỤC' : 'TẠO DANH MỤC'}
          </button>

          <button
            type="button"
            onClick={() => navigate('/catalog')}
            style={{
              width: '101px',
              height: '41px',
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
