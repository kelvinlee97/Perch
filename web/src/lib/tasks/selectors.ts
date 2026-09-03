import type { Task, TaskStatus } from "./types";

export function statusForReminder(reminderAt: string | null): TaskStatus {
    return reminderAt === null ? "inbox" : "today";
}

export function dueTasks(tasks: Task[], now: Date): Task[] {
    return tasks
        .filter(
            (task) =>
                task.status === "today" &&
                task.reminderAt !== null &&
                new Date(task.reminderAt).getTime() <= now.getTime(),
        )
        .sort((left, right) => {
            const reminderDifference =
                new Date(left.reminderAt!).getTime() -
                new Date(right.reminderAt!).getTime();
            if (reminderDifference !== 0) {
                return reminderDifference;
            }

            const createdDifference =
                new Date(left.createdAt).getTime() -
                new Date(right.createdAt).getTime();
            return createdDifference !== 0
                ? createdDifference
                : left.id.localeCompare(right.id);
        });
}

export function workspaceSections(tasks: Task[], now: Date) {
    const due = dueTasks(tasks, now);

    return {
        inbox: tasks.filter((task) => task.status === "inbox"),
        today: tasks.filter((task) => task.status === "today"),
        completed: tasks.filter((task) => task.status === "completed"),
        dueTask: due[0] ?? null,
        additionalDueCount: Math.max(0, due.length - 1),
    };
}
