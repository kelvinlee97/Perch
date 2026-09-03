create table public.tasks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null check (char_length(btrim(title)) > 0),
    created_at timestamptz not null default now(),
    reminder_at timestamptz,
    status text not null check (status in ('inbox', 'today', 'completed')),
    constraint tasks_status_reminder_consistency check (
        (status = 'inbox' and reminder_at is null)
        or (status = 'today' and reminder_at is not null)
        or status = 'completed'
    )
);

create index tasks_user_status_reminder_idx
    on public.tasks (user_id, status, reminder_at);

alter table public.tasks enable row level security;

revoke all on table public.tasks from anon;
grant select, insert, update, delete on table public.tasks to authenticated;

create policy "Users can read their own tasks"
    on public.tasks for select
    to authenticated
    using ((select auth.uid()) = user_id);

create policy "Users can create their own tasks"
    on public.tasks for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

create policy "Users can update their own tasks"
    on public.tasks for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

create policy "Users can delete their own tasks"
    on public.tasks for delete
    to authenticated
    using ((select auth.uid()) = user_id);
