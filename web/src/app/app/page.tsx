import type { Metadata } from "next";

import { TaskWorkspace } from "./task-workspace";
import { getTasksForCurrentUser } from "@/lib/tasks/queries";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "工作区",
};

export default async function AppPage() {
  const result = await getTasksForCurrentUser();

  return <TaskWorkspace initialTasks={result.tasks} error={result.error} />;
}
