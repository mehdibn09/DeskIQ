import type { ActivityDTO, DocumentDTO } from "@/types/document";
import type { Profile, Role } from "@/types/database";

export interface UserStats {
  total_documents: number;
  total_folders: number;
  storage_used: number;
  storage_limit: number;
  documents_this_month: number;
  type_breakdown: { label: string; count: number; size: number }[];
}

export interface AdminStats {
  total_users: number;
  total_documents: number;
  total_folders: number;
  total_storage: number;
  admins: number;
  new_users_this_month: number;
  documents_this_month: number;
  recent_activity: ActivityDTO[];
}

export interface UserWithStats extends Profile {
  document_count: number;
  storage_used: number;
}

export interface SessionUser {
  id: string;
  email: string;
  full_name: string;
  avatar_url: string | null;
  role: Role;
}

export interface AdminDocumentRow extends DocumentDTO {
  owner_name: string | null;
  owner_email: string;
}

export type RecentDocuments = DocumentDTO[];
