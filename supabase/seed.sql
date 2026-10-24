-- ============================================================
-- NovaDesk — demo seed data
--
-- Run AFTER schema.sql. Inserts realistic folders, documents and
-- activity for the first signed-up profile (or the account you pass
-- in the psql variable). Safe to run more than once.
-- ============================================================

do $$
declare
  v_user uuid;
  v_contracts uuid;
  v_invoices uuid;
  v_reports uuid;
  v_policies uuid;
  v_doc uuid;
begin
  select id into v_user from public.profiles order by created_at asc limit 1;

  if v_user is null then
    raise notice 'No profile found — sign up once, then re-run seed.sql.';
    return;
  end if;

  insert into public.folders (user_id, name)
  values
    (v_user, 'Contracts'),
    (v_user, 'Invoices'),
    (v_user, 'Reports'),
    (v_user, 'Policies')
  on conflict (user_id, name) do nothing;

  select id into v_contracts from public.folders where user_id = v_user and name = 'Contracts';
  select id into v_invoices  from public.folders where user_id = v_user and name = 'Invoices';
  select id into v_reports   from public.folders where user_id = v_user and name = 'Reports';
  select id into v_policies  from public.folders where user_id = v_user and name = 'Policies';

  insert into public.documents
    (user_id, folder_id, name, description, file_path, file_type, file_size, created_at, updated_at)
  values
    (v_user, v_contracts, 'Contract_2026.pdf',      'Signed master services agreement with Northwind Studio for FY2026.', v_user || '/contract-2026.pdf',      'application/pdf',    245760, now() - interval '12 days', now() - interval '12 days'),
    (v_user, v_invoices,  'Invoice_September.pdf',  'September retainer invoice for Halcyon Media, due on the 30th.',    v_user || '/invoice-september.pdf',  'application/pdf',    190464, now() - interval '4 days',  now() - interval '4 days'),
    (v_user, v_reports,   'Project_Report.docx',    'Quarterly delivery report covering scope, risks and burn rate.',    v_user || '/project-report.docx',    'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 98304, now() - interval '9 days', now() - interval '9 days'),
    (v_user, v_policies,  'Company_Policy.pdf',     'Employee handbook: time off, remote work and device security.',      v_user || '/company-policy.pdf',     'application/pdf',    327680, now() - interval '47 days', now() - interval '47 days'),
    (v_user, v_reports,   'Research_Notes.txt',     'Raw notes from 14 customer interviews about document search.',       v_user || '/research-notes.txt',     'text/plain',         12288,  now() - interval '6 days',  now() - interval '6 days'),
    (v_user, null,        'Presentation.pdf',       'Investor deck — Q3 growth, retention and roadmap.',                   v_user || '/presentation.pdf',       'application/pdf',    1835008, now() - interval '1 day',  now() - interval '1 day'),
    (v_user, v_policies,  'Team_Handbook.pdf',      'Onboarding handbook with checklists for the first 30 days.',         v_user || '/team-handbook.pdf',      'application/pdf',    2516582, now() - interval '63 days', now() - interval '63 days'),
    (v_user, v_reports,   'Meeting_Minutes.txt',    'Minutes from the weekly operations sync with action items.',         v_user || '/meeting-minutes.txt',    'text/plain',         8192,   now(), now())
  on conflict do nothing;

  for v_doc in
    select id from public.documents where user_id = v_user order by created_at desc limit 8
  loop
    insert into public.activity_logs (user_id, action, document_id)
    values (v_user, 'Uploaded a document', v_doc)
    on conflict do nothing;
  end loop;

  raise notice 'Seed data inserted for profile %', v_user;
end;
$$;
