import type { Database } from "@/lib/supabase/database.types";

import type { Task } from "./types";

type TaskRow = Database["public"]["Tables"]["tasks"]["Row"];

export function taskFromRow(row: TaskRow): Task {
    return {
        id: row.id,
        title: row.title,
        createdAt: row.created_at,
        reminderAt: row.reminder_at,
        status: row.status,
    };
}

export function tasksFromRows(rows: TaskRow[]): Task[] {
    return rows.map(taskFromRow);
}
