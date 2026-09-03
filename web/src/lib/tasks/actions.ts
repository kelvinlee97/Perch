"use server";

import { revalidatePath } from "next/cache";

import { taskFromRow } from "./mapper";
import { authenticatedTaskClient, taskSelect } from "./server";
import { statusForReminder } from "./selectors";
import type { TaskActionResult } from "./types";
import { normalizeTaskTitle } from "./validation";

function value(formData: FormData, key: string) {
    const entry = formData.get(key);
    return typeof entry === "string" ? entry.trim() : "";
}

function parseReminder(value: string | null | undefined) {
    if (!value) {
        return null;
    }

    const timestamp = Date.parse(value);
    if (Number.isNaN(timestamp)) {
        throw new Error("提醒时间无效。");
    }

    return new Date(timestamp).toISOString();
}

function actionError(message = "操作没有完成，请稍后再试。"): TaskActionResult {
    return { ok: false, message };
}

async function currentTaskClient() {
    const result = await authenticatedTaskClient();
    if (!result.user) {
        return null;
    }
    return { client: result.client, user: result.user };
}

export async function createTask(formData: FormData): Promise<TaskActionResult> {
    try {
        const current = await currentTaskClient();
        if (!current) {
            return actionError("请先登录。");
        }

        const title = normalizeTaskTitle(value(formData, "title"));
        const reminderAt = parseReminder(value(formData, "reminderAt"));
        const { data, error } = await current.client
            .from("tasks")
            .insert({
                user_id: current.user.id,
                title,
                reminder_at: reminderAt,
                status: statusForReminder(reminderAt),
            })
            .select(taskSelect)
            .single();

        if (error) {
            return actionError();
        }

        revalidatePath("/app");
        return { ok: true, task: taskFromRow(data) };
    } catch (error) {
        if (error instanceof Error && error.message === "请输入待办内容。") {
            return actionError(error.message);
        }
        if (error instanceof Error && error.message === "提醒时间无效。") {
            return actionError(error.message);
        }
        return actionError("任务服务尚未配置，请先完成 Supabase 设置。");
    }
}

export async function completeTask(id: string): Promise<TaskActionResult> {
    try {
        const current = await currentTaskClient();
        if (!current) {
            return actionError("请先登录。");
        }

        const { data, error } = await current.client
            .from("tasks")
            .update({ status: "completed" })
            .eq("id", id)
            .eq("user_id", current.user.id)
            .select(taskSelect)
            .maybeSingle();

        if (error || !data) {
            return actionError();
        }

        revalidatePath("/app");
        return { ok: true, task: taskFromRow(data) };
    } catch {
        return actionError();
    }
}

export async function restoreTask(id: string): Promise<TaskActionResult> {
    try {
        const current = await currentTaskClient();
        if (!current) {
            return actionError("请先登录。");
        }

        const { data: existing, error: readError } = await current.client
            .from("tasks")
            .select(taskSelect)
            .eq("id", id)
            .eq("user_id", current.user.id)
            .maybeSingle();

        if (readError || !existing) {
            return actionError();
        }

        const { data, error } = await current.client
            .from("tasks")
            .update({ status: statusForReminder(existing.reminder_at) })
            .eq("id", id)
            .eq("user_id", current.user.id)
            .select(taskSelect)
            .single();

        if (error) {
            return actionError();
        }

        revalidatePath("/app");
        return { ok: true, task: taskFromRow(data) };
    } catch {
        return actionError();
    }
}

export async function updateTaskReminder(
    id: string,
    reminderAt: string | null,
): Promise<TaskActionResult> {
    try {
        const current = await currentTaskClient();
        if (!current) {
            return actionError("请先登录。");
        }

        const parsedReminder = parseReminder(reminderAt);
        const { data, error } = await current.client
            .from("tasks")
            .update({
                reminder_at: parsedReminder,
                status: statusForReminder(parsedReminder),
            })
            .eq("id", id)
            .eq("user_id", current.user.id)
            .neq("status", "completed")
            .select(taskSelect)
            .maybeSingle();

        if (error || !data) {
            return actionError();
        }

        revalidatePath("/app");
        return { ok: true, task: taskFromRow(data) };
    } catch (error) {
        if (error instanceof Error && error.message === "提醒时间无效。") {
            return actionError(error.message);
        }
        return actionError();
    }
}

export async function deleteTask(id: string): Promise<TaskActionResult> {
    try {
        const current = await currentTaskClient();
        if (!current) {
            return actionError("请先登录。");
        }

        const { error } = await current.client
            .from("tasks")
            .delete()
            .eq("id", id)
            .eq("user_id", current.user.id);

        if (error) {
            return actionError();
        }

        revalidatePath("/app");
        return { ok: true };
    } catch {
        return actionError();
    }
}
