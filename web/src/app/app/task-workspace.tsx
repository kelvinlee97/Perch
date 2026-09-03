"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, useTransition } from "react";
import { toast } from "sonner";
import {
  Archive,
  Bell,
  Check,
  CheckCircle2,
  ChevronDown,
  Circle,
  Clock3,
  Inbox,
  LogOut,
  Menu,
  Moon,
  Plus,
  RotateCcw,
  Sun,
  Trash2,
  X,
} from "lucide-react";

import { Brand } from "@/components/brand";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuBadge,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarSeparator,
  SidebarInset,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { Toaster } from "@/components/ui/sonner";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { signOut } from "@/app/(auth)/actions";
import {
  completeTask,
  createTask,
  deleteTask,
  restoreTask,
  updateTaskReminder,
} from "@/lib/tasks/actions";
import { reminderDateFor } from "@/lib/tasks/reminders";
import { workspaceSections } from "@/lib/tasks/selectors";
import type {
  ReminderOption,
  Task,
  TaskActionResult,
  TaskStatus,
} from "@/lib/tasks/types";

type Section = Exclude<TaskStatus, "today"> | "today";

const sectionCopy: Record<
  Section,
  { label: string; emptyTitle: string; emptyDescription: string }
> = {
  inbox: {
    label: "收件箱",
    emptyTitle: "收件箱还是空的。",
    emptyDescription: "把突然想到的事先放进来，不用现在就安排。",
  },
  today: {
    label: "今天",
    emptyTitle: "今天没有提醒。",
    emptyDescription: "给一件事加上提醒，它会在这里等你。",
  },
  completed: {
    label: "已完成",
    emptyTitle: "还没有完成的事。",
    emptyDescription: "做完的事情会安静地留在这里。",
  },
};

const reminderOptions: Array<{
  option: ReminderOption;
  label: string;
  icon: typeof Clock3;
}> = [
  { option: "tenMinutes", label: "10 分钟后", icon: Clock3 },
  { option: "tonight", label: "今晚", icon: Moon },
  { option: "tomorrow", label: "明天", icon: Sun },
  { option: "none", label: "不再提醒", icon: X },
];

function reminderLabel(reminderAt: string | null) {
  if (!reminderAt) {
    return "没有提醒";
  }

  return new Intl.DateTimeFormat("zh-CN", {
    month: "numeric",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(reminderAt));
}

function runTaskResult(
  result: TaskActionResult,
  successMessage: string,
  router: ReturnType<typeof useRouter>,
) {
  if (!result.ok) {
    toast.error(result.message);
    return;
  }

  toast.success(successMessage);
  router.refresh();
}

function ReminderMenu({
  onSelect,
  compact = false,
  disabled = false,
}: {
  onSelect: (option: ReminderOption) => void;
  compact?: boolean;
  disabled?: boolean;
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        type="button"
        className="task-reminder-trigger"
        disabled={disabled}
        aria-label={compact ? "稍后提醒" : "设置提醒"}
      >
        {compact ? <Clock3 aria-hidden="true" /> : <Bell aria-hidden="true" />}
        <span>{compact ? "稍后" : "提醒"}</span>
        <ChevronDown aria-hidden="true" />
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="task-reminder-menu">
        <DropdownMenuLabel>什么时候提醒？</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {reminderOptions.map(({ option, label, icon: Icon }) => (
          <DropdownMenuItem key={option} onClick={() => onSelect(option)}>
            <Icon aria-hidden="true" />
            {label}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function DeleteTaskButton({ task }: { task: Task }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [pending, startTransition] = useTransition();

  function remove() {
    startTransition(async () => {
      const result = await deleteTask(task.id);
      if (!result.ok) {
        toast.error(result.message);
        return;
      }

      setOpen(false);
      toast.success("已删除");
      router.refresh();
    });
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger
        type="button"
        className="task-icon-button task-delete-button"
        aria-label={`删除：${task.title}`}
      >
        <Trash2 aria-hidden="true" />
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>删除这件事？</DialogTitle>
          <DialogDescription>“{task.title}”会从你的工作区移除。</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <DialogClose render={<Button variant="outline" />}>取消</DialogClose>
          <Button variant="destructive" onClick={remove} disabled={pending}>
            {pending ? "删除中…" : "删除"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function TaskRow({ task }: { task: Task }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function perform(
    action: () => Promise<TaskActionResult>,
    successMessage: string,
  ) {
    startTransition(async () => {
      const result = await action();
      runTaskResult(result, successMessage, router);
    });
  }

  function chooseReminder(option: ReminderOption) {
    const reminder = reminderDateFor(option);
    perform(
      () => updateTaskReminder(task.id, reminder?.toISOString() ?? null),
      option === "none" ? "已移到收件箱" : "提醒时间已更新",
    );
  }

  return (
    <li className="task-row">
      <button
        type="button"
        className="task-check-button"
        onClick={() => perform(() => completeTask(task.id), "已完成")}
        disabled={pending}
        aria-label={`完成：${task.title}`}
      >
        <Circle aria-hidden="true" />
      </button>
      <div className="task-row-copy">
        <p>{task.title}</p>
        <span>{reminderLabel(task.reminderAt)}</span>
      </div>
      <div className="task-row-actions">
        {task.status === "completed" ? (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => perform(() => restoreTask(task.id), "已恢复")}
            disabled={pending}
          >
            <RotateCcw aria-hidden="true" />
            恢复
          </Button>
        ) : (
          <ReminderMenu onSelect={chooseReminder} disabled={pending} />
        )}
        <DeleteTaskButton task={task} />
      </div>
    </li>
  );
}

function DueReminderCard({ task, additionalCount }: { task: Task; additionalCount: number }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function chooseReminder(option: ReminderOption) {
    const reminder = reminderDateFor(option);
    startTransition(async () => {
      const result = await updateTaskReminder(task.id, reminder?.toISOString() ?? null);
      runTaskResult(
        result,
        option === "none" ? "已移到收件箱" : "稍后再提醒你",
        router,
      );
    });
  }

  return (
    <section className="due-card" aria-labelledby="due-title">
      <div className="due-card-meta">
        <span className="due-dot" />
        <span>现在提醒</span>
        <span className="due-time">
          <Bell aria-hidden="true" />
          {reminderLabel(task.reminderAt)}
        </span>
      </div>
      <h2 id="due-title">{task.title}</h2>
      <div className="due-card-footer">
        <div className="due-card-note">
          <Clock3 aria-hidden="true" />
          <span>{additionalCount ? `还有 ${additionalCount} 件待处理` : "只提醒这一件"}</span>
        </div>
        <div className="due-card-actions">
          <Button
            type="button"
            className="due-complete-button"
            onClick={() => {
              startTransition(async () => {
                const result = await completeTask(task.id);
                runTaskResult(result, "已完成", router);
              });
            }}
            disabled={pending}
          >
            <Check aria-hidden="true" />
            完成
          </Button>
          <ReminderMenu onSelect={chooseReminder} compact disabled={pending} />
        </div>
      </div>
    </section>
  );
}

function TaskCaptureForm() {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [reminderOption, setReminderOption] = useState<ReminderOption>("none");
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    const formData = new FormData();
    formData.set("title", title);
    const reminder = reminderDateFor(reminderOption);
    formData.set("reminderAt", reminder?.toISOString() ?? "");

    startTransition(async () => {
      const result = await createTask(formData);
      if (!result.ok) {
        setError(result.message);
        return;
      }

      setTitle("");
      setReminderOption("none");
      toast.success("已放进工作区");
      router.refresh();
    });
  }

  return (
    <form className="task-capture" onSubmit={submit}>
      <div className="task-capture-input-row">
        <Plus aria-hidden="true" />
        <input
          name="title"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="添加一件事"
          aria-label="待办内容"
          disabled={pending}
        />
        <Button type="submit" size="sm" disabled={pending || !title.trim()}>
          {pending ? "添加中…" : "添加"}
        </Button>
      </div>
      <div className="task-capture-options">
        <span className="task-capture-label">提醒</span>
        <ToggleGroup
          multiple={false}
          value={[reminderOption]}
          onValueChange={(value) => {
            const nextValue = value[0];
            if (nextValue) {
              setReminderOption(nextValue as ReminderOption);
            }
          }}
          aria-label="选择提醒时间"
          className="task-reminder-toggles"
        >
          <ToggleGroupItem value="none">不提醒</ToggleGroupItem>
          <ToggleGroupItem value="tenMinutes">10 分钟</ToggleGroupItem>
          <ToggleGroupItem value="tonight">今晚</ToggleGroupItem>
          <ToggleGroupItem value="tomorrow">明天</ToggleGroupItem>
        </ToggleGroup>
      </div>
      {error && <p className="task-capture-error" role="alert">{error}</p>}
    </form>
  );
}

function TaskSection({ section, tasks }: { section: Section; tasks: Task[] }) {
  const copy = sectionCopy[section];

  return (
    <section className="task-section" id={section} aria-labelledby={`${section}-title`}>
      <div className="task-section-heading">
        <h2 id={`${section}-title`}>{copy.label}</h2>
        <span>{tasks.length}</span>
      </div>
      {tasks.length ? (
        <ul className="task-list">
          {tasks.map((task) => <TaskRow key={task.id} task={task} />)}
        </ul>
      ) : (
        <Empty className="task-empty">
          <EmptyHeader>
            <EmptyTitle>{copy.emptyTitle}</EmptyTitle>
            <EmptyDescription>{copy.emptyDescription}</EmptyDescription>
          </EmptyHeader>
        </Empty>
      )}
    </section>
  );
}

function WorkspaceSidebar({
  activeSection,
  sections,
  setActiveSection,
}: {
  activeSection: Section;
  sections: ReturnType<typeof workspaceSections>;
  setActiveSection: (section: Section) => void;
}) {
  const navigation: Array<{ section: Section; icon: typeof Inbox }> = [
    { section: "inbox", icon: Inbox },
    { section: "today", icon: Sun },
    { section: "completed", icon: CheckCircle2 },
  ];

  return (
    <Sidebar collapsible="offcanvas" className="workspace-sidebar">
      <SidebarHeader className="workspace-sidebar-header">
        <Brand compact />
        <span className="workspace-sidebar-subtitle">Web 工作区</span>
      </SidebarHeader>
      <SidebarSeparator />
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>我的任务</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navigation.map(({ section, icon: Icon }) => (
                <SidebarMenuItem key={section}>
                  <SidebarMenuButton
                    render={<a href={`#${section}`} />}
                    isActive={activeSection === section}
                    onClick={() => setActiveSection(section)}
                  >
                    <Icon aria-hidden="true" />
                    <span>{sectionCopy[section].label}</span>
                  </SidebarMenuButton>
                  <SidebarMenuBadge>
                    {sections[section].length}
                  </SidebarMenuBadge>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="workspace-sidebar-footer">
        <form action={signOut}>
          <SidebarMenuButton type="submit">
            <LogOut aria-hidden="true" />
            <span>退出登录</span>
          </SidebarMenuButton>
        </form>
      </SidebarFooter>
    </Sidebar>
  );
}

export function TaskWorkspace({
  initialTasks,
  error,
}: {
  initialTasks: Task[];
  error?: string;
}) {
  const router = useRouter();
  const [activeSection, setActiveSection] = useState<Section>("inbox");
  const [now, setNow] = useState(() => new Date());
  const sections = useMemo(() => workspaceSections(initialTasks, now), [initialTasks, now]);

  useEffect(() => {
    const refresh = window.setInterval(() => {
      setNow(new Date());
      router.refresh();
    }, 30_000);

    return () => window.clearInterval(refresh);
  }, [router]);

  const currentTasks = sections[activeSection];

  return (
    <SidebarProvider className="workspace-shell">
      <WorkspaceSidebar
        activeSection={activeSection}
        sections={sections}
        setActiveSection={setActiveSection}
      />
      <SidebarInset className="workspace-inset">
        <header className="workspace-topbar">
          <SidebarTrigger aria-label="打开导航">
            <Menu aria-hidden="true" />
          </SidebarTrigger>
          <div className="workspace-topbar-copy">
            <span>Perch</span>
            <span aria-hidden="true">/</span>
            <span>{sectionCopy[activeSection].label}</span>
          </div>
          <span className="workspace-sync-note">每 30 秒更新</span>
        </header>
        <main className="workspace-main">
          <div className="workspace-heading">
            <div>
              <p className="workspace-date">
                {new Intl.DateTimeFormat("zh-CN", {
                  weekday: "long",
                  month: "long",
                  day: "numeric",
                }).format(now)}
              </p>
              <h1 className="font-display">{sectionCopy[activeSection].label}</h1>
            </div>
            <span className="workspace-count">{currentTasks.length} 件</span>
          </div>

          {error && (
            <Alert variant="destructive" className="workspace-alert">
              <Archive aria-hidden="true" />
              <AlertTitle>工作区暂时不可用</AlertTitle>
              <AlertDescription>
                {error} <Link href="/login">返回登录</Link>
              </AlertDescription>
            </Alert>
          )}

          <TaskCaptureForm />

          {activeSection !== "completed" && sections.dueTask && (
            <DueReminderCard
              task={sections.dueTask}
              additionalCount={sections.additionalDueCount}
            />
          )}

          <TaskSection section={activeSection} tasks={currentTasks} />
        </main>
      </SidebarInset>
      <Toaster position="bottom-right" />
    </SidebarProvider>
  );
}
