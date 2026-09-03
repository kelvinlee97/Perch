import { tasksFromRows } from "./mapper";
import { authenticatedTaskClient, taskSelect } from "./server";
import type { Task } from "./types";

export type TaskQueryResult =
    | { tasks: Task[]; error?: undefined }
    | { tasks: Task[]; error: string };

export async function getTasksForCurrentUser(): Promise<TaskQueryResult> {
    try {
        const { client, user } = await authenticatedTaskClient();

        if (!user) {
            return { tasks: [], error: "请先登录。" };
        }

        const { data, error } = await client
            .from("tasks")
            .select(taskSelect)
            .eq("user_id", user.id)
            .order("created_at", { ascending: false });

        if (error) {
            return { tasks: [], error: "暂时无法加载任务，请稍后再试。" };
        }

        return { tasks: tasksFromRows(data ?? []) };
    } catch {
        return { tasks: [], error: "任务服务尚未配置，请先完成 Supabase 设置。" };
    }
}
