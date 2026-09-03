export type Database = {
  public: {
    Tables: {
      tasks: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          created_at: string;
          reminder_at: string | null;
          status: "inbox" | "today" | "completed";
        };
        Insert: {
          id?: string;
          user_id: string;
          title: string;
          created_at?: string;
          reminder_at?: string | null;
          status: "inbox" | "today" | "completed";
        };
        Update: {
          id?: string;
          user_id?: string;
          title?: string;
          created_at?: string;
          reminder_at?: string | null;
          status?: "inbox" | "today" | "completed";
        };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
