import { useState, type ReactNode } from 'react';
import type { DateRange } from '../api/reports';

/** yyyy-MM-dd for a Date in local time. */
function iso(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** Default reporting window: first day of the current month → today. */
export function defaultRange(): DateRange {
  const now = new Date();
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
}

interface Props {
  initial: DateRange;
  onApply: (range: DateRange) => void;
  /** Extra controls rendered on the right (e.g. an export button). */
  children?: ReactNode;
}

/** From/To date pickers + an Apply button, shared across the report pages. */
export default function DateRangeBar({ initial, onApply, children }: Props) {
  const [from, setFrom] = useState(initial.from);
  const [to, setTo] = useState(initial.to);

  return (
    <div className="toolbar" style={{ alignItems: 'flex-end', gap: '0.75rem', flexWrap: 'wrap' }}>
      <label className="field" style={{ margin: 0 }}>
        <span className="label">Từ ngày</span>
        <input className="input" type="date" aria-label="Từ ngày" value={from} max={to}
          onChange={(e) => setFrom(e.target.value)} />
      </label>
      <label className="field" style={{ margin: 0 }}>
        <span className="label">Đến ngày</span>
        <input className="input" type="date" aria-label="Đến ngày" value={to} min={from}
          onChange={(e) => setTo(e.target.value)} />
      </label>
      <button type="button" className="btn btn--primary" onClick={() => onApply({ from, to })}>
        Áp dụng
      </button>
      <div className="toolbar__spacer" style={{ flex: 1 }} />
      {children}
    </div>
  );
}
