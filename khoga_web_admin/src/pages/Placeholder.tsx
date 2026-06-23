interface PlaceholderProps {
  title: string;
  hint?: string;
}

/** Temporary page for modules not yet built (cuốn chiếu: filled in screen by screen). */
export default function Placeholder({ title, hint }: PlaceholderProps) {
  return (
    <div>
      <div className="page-head">
        <h1 className="page-title">{title}</h1>
        {hint && <p className="page-subtitle">{hint}</p>}
      </div>
      <div className="empty-state">
        <p>Màn hình này đang được dựng theo thiết kế Figma.</p>
        <p className="hint">Sẽ nối với API backend tương ứng ở bước cuốn chiếu kế tiếp.</p>
      </div>
    </div>
  );
}
