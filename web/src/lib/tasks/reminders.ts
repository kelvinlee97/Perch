import type { ReminderOption } from "./types";

export function reminderDateFor(
    option: ReminderOption,
    now: Date = new Date(),
): Date | null {
    switch (option) {
        case "none":
            return null;
        case "tenMinutes":
            return new Date(now.getTime() + 10 * 60 * 1000);
        case "tonight": {
            const tonight = new Date(now);
            tonight.setHours(19, 0, 0, 0);
            if (tonight < now) {
                tonight.setDate(tonight.getDate() + 1);
            }
            return tonight;
        }
        case "tomorrow": {
            const tomorrow = new Date(now);
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(9, 0, 0, 0);
            return tomorrow;
        }
    }
}
