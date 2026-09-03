export type TaskStatus = "inbox" | "today" | "completed";

export type ReminderOption =
    | "none"
    | "tenMinutes"
    | "tonight"
    | "tomorrow";

export type Task = {
    id: string;
    title: string;
    createdAt: string;
    reminderAt: string | null;
    status: TaskStatus;
};

export type TaskActionResult =
    | {
          ok: true;
          task?: Task;
          message?: string;
      }
    | {
          ok: false;
          message: string;
          field?: "title" | "reminder";
      };
