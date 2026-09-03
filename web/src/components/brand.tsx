import Image from "next/image";
import Link from "next/link";

export function Brand({
  compact = false,
  homeLabel = "Perch 首页",
}: {
  compact?: boolean;
  homeLabel?: string;
}) {
  return (
    <Link href="/" className="brand" aria-label={homeLabel}>
      <Image
        src="/brand/bird-companion.png"
        alt=""
        width={compact ? 36 : 44}
        height={compact ? 36 : 44}
        className="brand-bird"
        priority
      />
      <span>Perch</span>
    </Link>
  );
}
