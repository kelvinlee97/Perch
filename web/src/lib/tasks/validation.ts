export function normalizeTaskTitle(title: string): string {
    const normalized = title.trim();

    if (!normalized) {
        throw new Error("请输入待办内容。");
    }

    return normalized;
}
