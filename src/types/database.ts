export type Role = "user" | "admin";

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  avatar_url: string | null;
  role: Role;
  created_at: string;
  updated_at: string;
}

export interface Folder {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  document_count?: number;
}

export interface DocumentRecord {
  id: string;
  user_id: string;
  folder_id: string | null;
  name: string;
  description: string | null;
  file_path: string;
  file_type: string;
  file_size: number;
  created_at: string;
  updated_at: string;
}

export interface ActivityLog {
  id: string;
  user_id: string;
  action: string;
  document_id: string | null;
  created_at: string;
}
