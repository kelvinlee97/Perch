# Perch Web

Perch Web 是 Perch macOS companion 的独立云端 Web 工作区。它使用自己的 Supabase 数据库，不读取或同步 macOS 应用的本地 JSON 数据。

## 技术栈

- Next.js App Router、React、TypeScript、Tailwind CSS v4
- shadcn/ui base-nova 组件
- Supabase Auth、Postgres、RLS
- Vercel 部署

## 本地运行

```bash
npm install
cp .env.example .env.local
npm run dev
```

没有 Supabase 环境变量时，Landing、登录和注册页面仍可查看；需要任务读写或认证时，请先完成下面的 Supabase 设置。

## Supabase 设置

1. 创建一个 Supabase project，并在 Authentication 中启用 Email provider。
2. 在 Supabase SQL Editor 中执行 [`supabase/migrations/0001_create_tasks.sql`](supabase/migrations/0001_create_tasks.sql)。它会创建任务表、索引和用户级 RLS policies。
3. 在 Authentication → URL Configuration 中设置：
   - Site URL：本地开发时为 `http://localhost:3000`。
   - Redirect URL：`http://localhost:3000/auth/callback`。
   - 部署到 Vercel 后，将生产域名和对应的 `/auth/callback` 一并加入允许列表。
4. 将 Project URL 和 Publishable key 写入 `.env.local`：

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## 验证命令

```bash
npm run lint
npm run typecheck
npm run test:unit
npm run build
```

任务的提醒选项是：不提醒、10 分钟后、今晚、明天。MVP 只在打开的工作区内展示到期提醒，并每 30 秒刷新一次；暂不实现 Web Push、邮件或后台通知。

## Vercel 部署

在 Vercel 项目中配置与 `.env.local` 相同的两个公开 Supabase 环境变量，然后部署。Supabase 的 Site URL 和 Redirect URL 也必须改为 Vercel 的正式域名。
