interface CupIconProps {
  size?: number;
  stroke?: string;
  className?: string;
}

/** Khoga coffee-cup mark (matches the Figma login badge). */
export default function CupIcon({ size = 48, stroke = '#ffffff', className }: CupIconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      stroke={stroke}
      strokeWidth={3.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <path d="M16 24h26v13a13 13 0 0 1-13 13h0a13 13 0 0 1-13-13z" />
      <path d="M42 28h4.5a6.5 6.5 0 0 1 0 13H42" />
      <path d="M23 11c-1.6 2.6-1.6 4.2 0 6.8M32 11c-1.6 2.6-1.6 4.2 0 6.8" />
    </svg>
  );
}
