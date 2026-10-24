export type FileCategory = "pdf" | "docx" | "txt" | "image" | "other";

export interface DocumentDTO {
  id: string;
  user_id: string;
  folder_id: string | null;
  folder_name: string | null;
  name: string;
  description: string | null;
  file_type: string;
  file_size: number;
  created_at: string;
  updated_at: string;
  /** Present for admin/platform-wide listings only. */
  owner_id?: string;
  owner_name?: string | null;
  owner_email?: string;
}

export interface ActivityDTO {
  id: string;
  action: string;
  document_name: string | null;
  created_at: string;
  user_id?: string;
  user_name?: string | null;
}

export interface DocumentQuery {
  search?: string;
  category?: string;
  folder_id?: string;
  /** ISO date (yyyy-mm-dd) — only return documents created on/after it. */
  from?: string;
  sort?: "name" | "date" | "size";
  order?: "asc" | "desc";
  limit?: number;
}
