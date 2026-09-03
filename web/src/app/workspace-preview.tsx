"use client";

import { useState, type FormEvent } from "react";
import {
  Check,
  CheckCircle2,
  Circle,
  Clock3,
  Inbox,
  Moon,
  Plus,
  RotateCcw,
  Sun,
} from "lucide-react";

import { Brand } from "@/components/brand";
import type { Locale } from "@/lib/locale";

type DemoSection = "inbox" | "today" | "completed";
type DemoReminder = "tenMinutes" | "tonight" | "tomorrow" | null;
type SampleTask = "due" | "evening";

type DemoTask = {
  id: string;
  title: string;
  sampleTask?: SampleTask;
  reminder: DemoReminder;
  completed: boolean;
};

type PreviewCopy = {
  reminderLabels: Record<Exclude<DemoReminder, null>, string>;
  sampleTasks: Record<SampleTask, string>;
  sectionLabels: Record<DemoSection, string>;
  emptyCopy: Record<DemoSection, string>;
  brandLabel: string;
  demoLabel: string;
  windowLabel: string;
  navigationLabel: string;
  modeNote: string;
  invitation: string;
  capture: string;
  taskLabel: string;
  placeholder: string;
  reminderPrefix: string;
  add: string;
  cancel: string;
  dueHeading: string;
  dueMinutes: string;
  complete: string;
  later: string;
  restore: string;
  quickActionsLabel: string;
  tonight: string;
  tomorrow: string;
  emptyReminder: string;
  actionSeparator: string;
  formError: string;
  feedback: {
    added: string;
    completed: string;
    postponed: string;
    restored: string;
  };
};

const previewCopy: Record<Locale, PreviewCopy> = {
  en: {
    reminderLabels: {
      tenMinutes: "in 10 minutes",
      tonight: "Tonight",
      tomorrow: "Tomorrow",
    },
    sampleTasks: {
      due: "Send a project update",
      evening: "Organize this week's ideas",
    },
    sectionLabels: {
      inbox: "Inbox",
      today: "Today",
      completed: "Completed",
    },
    emptyCopy: {
      inbox: "Your inbox is empty.",
      today: "Nothing is scheduled for today.",
      completed: "No completed tasks yet.",
    },
    brandLabel: "Perch home",
    demoLabel: "Demo",
    windowLabel: "Perch workspace preview",
    navigationLabel: "Workspace navigation",
    modeNote: "Demo mode · Nothing is saved",
    invitation: "Try it: add one thing",
    capture: "Add one thing",
    taskLabel: "What do you want to remember?",
    placeholder: "Write something to remember",
    reminderPrefix: "Reminder: ",
    add: "Add",
    cancel: "Cancel",
    dueHeading: "To be reminded",
    dueMinutes: "10 minutes",
    complete: "Complete",
    later: "Later",
    restore: "Restore",
    quickActionsLabel: "Quick reminders",
    tonight: "Tonight",
    tomorrow: "Tomorrow",
    emptyReminder: "Inbox",
    actionSeparator: ": ",
    formError: "Write something you want to remember first.",
    feedback: {
      added: "Added to the demo inbox",
      completed: "Moved to the demo completed list",
      postponed: "Reminder moved to tonight",
      restored: "Restored to the demo inbox",
    },
  },
  zh: {
    reminderLabels: {
      tenMinutes: "10 分钟后",
      tonight: "今晚",
      tomorrow: "明天",
    },
    sampleTasks: {
      due: "给项目发一条更新",
      evening: "整理本周的想法",
    },
    sectionLabels: {
      inbox: "收件箱",
      today: "今天",
      completed: "已完成",
    },
    emptyCopy: {
      inbox: "收件箱还是空的。",
      today: "今天没有提醒。",
      completed: "还没有完成的事。",
    },
    brandLabel: "Perch 首页",
    demoLabel: "演示",
    windowLabel: "Perch 工作区预览",
    navigationLabel: "工作区导航",
    modeNote: "演示模式 · 不会保存真实数据",
    invitation: "试试看：添加一件事",
    capture: "添加一件事",
    taskLabel: "待办内容",
    placeholder: "写下你想记住的事",
    reminderPrefix: "提醒：",
    add: "添加",
    cancel: "取消",
    dueHeading: "待提醒",
    dueMinutes: "10 分钟",
    complete: "完成",
    later: "稍后",
    restore: "恢复",
    quickActionsLabel: "快速添加提醒",
    tonight: "今晚",
    tomorrow: "明天",
    emptyReminder: "收件箱",
    actionSeparator: "：",
    formError: "请先写下要记住的事。",
    feedback: {
      added: "已添加到演示收件箱",
      completed: "已移到演示的已完成列表",
      postponed: "已改为今晚提醒",
      restored: "已恢复到演示收件箱",
    },
  },
};

const initialTasks: DemoTask[] = [
  {
    id: "demo-due",
    title: "",
    sampleTask: "due",
    reminder: "tenMinutes",
    completed: false,
  },
  {
    id: "demo-evening",
    title: "",
    sampleTask: "evening",
    reminder: "tonight",
    completed: false,
  },
];

function taskTitle(task: DemoTask, content: PreviewCopy) {
  return task.sampleTask ? content.sampleTasks[task.sampleTask] : task.title;
}

function reminderLabel(reminder: DemoReminder, content: PreviewCopy) {
  return reminder ? content.reminderLabels[reminder] : content.emptyReminder;
}

function previewDate(locale: Locale) {
  return new Intl.DateTimeFormat(locale === "zh" ? "zh-CN" : "en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  }).format(new Date(2025, 7, 25));
}

export function WorkspacePreview({ locale }: { locale: Locale }) {
  const content = previewCopy[locale];
  const [tasks, setTasks] = useState<DemoTask[]>(initialTasks);
  const [section, setSection] = useState<DemoSection>("inbox");
  const [captureOpen, setCaptureOpen] = useState(false);
  const [draftTitle, setDraftTitle] = useState("");
  const [draftReminder, setDraftReminder] = useState<DemoReminder>(null);
  const [draftError, setDraftError] = useState("");
  const [feedback, setFeedback] = useState("");

  const visibleTasks = tasks.filter((task) => {
    if (section === "completed") {
      return task.completed;
    }

    return !task.completed && (section === "inbox" || task.reminder !== null);
  });
  const dueTask =
    section === "completed"
      ? undefined
      : visibleTasks.find((task) => task.reminder === "tenMinutes");
  const listTasks = visibleTasks.filter((task) => task.id !== dueTask?.id);
  const count =
    section === "completed"
      ? visibleTasks.length
      : visibleTasks.filter((task) => task.reminder === "tenMinutes").length;

  function beginCapture(reminder: DemoReminder = null) {
    setCaptureOpen(true);
    setDraftReminder(reminder);
    setDraftTitle("");
    setDraftError("");
  }

  function cancelCapture() {
    setCaptureOpen(false);
    setDraftReminder(null);
    setDraftTitle("");
    setDraftError("");
  }

  function addTask(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const title = draftTitle.trim();

    if (!title) {
      setDraftError(content.formError);
      return;
    }

    setTasks((current) => [
      ...current,
      {
        id: crypto.randomUUID(),
        title,
        reminder: draftReminder,
        completed: false,
      },
    ]);
    setSection("inbox");
    setFeedback(content.feedback.added);
    cancelCapture();
  }

  function completeTask(id: string) {
    setTasks((current) =>
      current.map((task) =>
        task.id === id ? { ...task, completed: true } : task,
      ),
    );
    setFeedback(content.feedback.completed);
  }

  function postponeTask(id: string) {
    setTasks((current) =>
      current.map((task) =>
        task.id === id ? { ...task, reminder: "tonight" } : task,
      ),
    );
    setFeedback(content.feedback.postponed);
  }

  function restoreTask(id: string) {
    setTasks((current) =>
      current.map((task) =>
        task.id === id ? { ...task, completed: false } : task,
      ),
    );
    setFeedback(content.feedback.restored);
  }

  return (
    <section className="preview-window" aria-label={content.windowLabel} role="region">
      <aside className="preview-sidebar">
        <div className="preview-sidebar-brand">
          <Brand compact homeLabel={content.brandLabel} />
          <span className="preview-demo-label">{content.demoLabel}</span>
        </div>
        <nav className="preview-nav" aria-label={content.navigationLabel}>
          <button
            type="button"
            className={`preview-nav-item${section === "inbox" ? " is-active" : ""}`}
            aria-pressed={section === "inbox"}
            onClick={() => setSection("inbox")}
          >
            <Inbox aria-hidden="true" />
            {content.sectionLabels.inbox}
          </button>
          <button
            type="button"
            className={`preview-nav-item${section === "today" ? " is-active" : ""}`}
            aria-pressed={section === "today"}
            onClick={() => setSection("today")}
          >
            <Sun aria-hidden="true" />
            {content.sectionLabels.today}
          </button>
          <button
            type="button"
            className={`preview-nav-item${section === "completed" ? " is-active" : ""}`}
            aria-pressed={section === "completed"}
            onClick={() => setSection("completed")}
          >
            <Check aria-hidden="true" />
            {content.sectionLabels.completed}
          </button>
        </nav>
      </aside>

      <div className="preview-content">
        <p className="preview-date">{previewDate(locale)}</p>
        <h2>{content.sectionLabels[section]}</h2>
        <p className="preview-demo-note">{content.modeNote}</p>

        {captureOpen ? (
          <form className="preview-capture-form" onSubmit={addTask}>
            <div className="preview-capture-form-heading">
              <Plus aria-hidden="true" />
              <span>{content.capture}</span>
            </div>
            <label htmlFor="demo-task-input">{content.taskLabel}</label>
            <input
              id="demo-task-input"
              aria-label={content.taskLabel}
              value={draftTitle}
              onChange={(event) => {
                setDraftTitle(event.target.value);
                setDraftError("");
              }}
              placeholder={content.placeholder}
              autoFocus
            />
            {draftReminder && (
              <span className="preview-draft-reminder">
                <Clock3 aria-hidden="true" />
                {content.reminderPrefix}{content.reminderLabels[draftReminder]}
              </span>
            )}
            {draftError && (
              <p className="preview-form-error" role="alert">
                {draftError}
              </p>
            )}
            <div className="preview-capture-actions">
              <button type="submit" className="preview-submit-button">
                {content.add}
              </button>
              <button
                type="button"
                className="preview-cancel-button"
                onClick={cancelCapture}
              >
                {content.cancel}
              </button>
            </div>
          </form>
        ) : (
          <button
            type="button"
            className="preview-capture"
            aria-label={content.capture}
            aria-expanded={captureOpen}
            onClick={() => beginCapture()}
          >
            <Plus aria-hidden="true" />
            <span>{content.invitation}</span>
          </button>
        )}

        {feedback && (
          <p className="preview-feedback" role="status" aria-live="polite">
            {feedback}
          </p>
        )}

        <div className="preview-section-heading">
          <span>
            {section === "completed" ? content.sectionLabels.completed : content.dueHeading}
          </span>
          <span className="preview-section-count">{count}</span>
        </div>

        {dueTask && (
          <article className="preview-due-task" aria-labelledby="preview-due-title">
            <div className="preview-task-meta">
              <span className="preview-orange-dot" />
              <span>{content.dueMinutes}</span>
              <span className="preview-task-reminder">
                <Clock3 aria-hidden="true" />
                {reminderLabel(dueTask.reminder, content)}
              </span>
            </div>
            <p id="preview-due-title">{taskTitle(dueTask, content)}</p>
            <div className="preview-task-actions">
              <button
                type="button"
                className="preview-complete-button"
                aria-label={`${content.complete}${content.actionSeparator}${taskTitle(dueTask, content)}`}
                onClick={() => completeTask(dueTask.id)}
              >
                <Check aria-hidden="true" />
                {content.complete}
              </button>
              <button
                type="button"
                className="preview-later-button"
                aria-label={`${content.later}${content.actionSeparator}${taskTitle(dueTask, content)}`}
                onClick={() => postponeTask(dueTask.id)}
              >
                {content.later}
              </button>
            </div>
          </article>
        )}

        {listTasks.length > 0 ? (
          <ul className="preview-task-list">
            {listTasks.map((task) => (
              <li
                className={`preview-task-row${task.completed ? " is-completed" : ""}`}
                key={task.id}
              >
                {task.completed ? (
                  <CheckCircle2 aria-hidden="true" />
                ) : (
                  <button
                    type="button"
                    className="preview-task-check"
                    aria-label={`${content.complete}${content.actionSeparator}${taskTitle(task, content)}`}
                    onClick={() => completeTask(task.id)}
                  >
                    <Circle aria-hidden="true" />
                  </button>
                )}
                <span>{taskTitle(task, content)}</span>
                <span className="preview-task-time">
                  {task.completed
                    ? content.sectionLabels.completed
                    : reminderLabel(task.reminder, content)}
                </span>
                {task.completed && (
                  <button
                    type="button"
                    className="preview-restore-button"
                    aria-label={`${content.restore}${content.actionSeparator}${taskTitle(task, content)}`}
                    onClick={() => restoreTask(task.id)}
                  >
                    <RotateCcw aria-hidden="true" />
                  </button>
                )}
              </li>
            ))}
          </ul>
        ) : (
          <p className="preview-empty-state">{content.emptyCopy[section]}</p>
        )}

        {section !== "completed" && (
          <div className="preview-quick-actions" aria-label={content.quickActionsLabel}>
            <button
              type="button"
              onClick={() => beginCapture("tonight")}
              aria-label={`${content.capture} ${content.tonight}`}
            >
              <Moon aria-hidden="true" />
              {content.tonight}
            </button>
            <button
              type="button"
              onClick={() => beginCapture("tomorrow")}
              aria-label={`${content.capture} ${content.tomorrow}`}
            >
              <Sun aria-hidden="true" />
              {content.tomorrow}
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
