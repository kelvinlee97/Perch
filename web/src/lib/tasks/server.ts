import type { SupabaseClient, User } from "@supabase/supabase-js";

import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/lib/supabase/database.types";

export const taskSelect = "id,user_id,title,created_at,reminder_at,status";

export type TaskClient = SupabaseClient<Database>;

export async function authenticatedTaskClient(): Promise<{
    client: TaskClient;
    user: User | null;
}> {
    const client = await createClient();
    const {
        data: { user },
    } = await client.auth.getUser();

    return { client, user };
}
