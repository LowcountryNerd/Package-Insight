# Fix Instructions

## Issue 1: Edge Function 500 Error

The Edge Function code has been fixed. You need to **update the function in your Supabase dashboard**:

1. Go to **Edge Functions** in your Supabase dashboard
2. Click on **`user-management`** function
3. **Replace the entire code** with the updated code from `supabase/functions/user-management/index.ts`
4. Click **Deploy** or **Save**

## Issue 2: Permission Denied for Index Tables

The "permission denied" error is because Row Level Security (RLS) policies are blocking inserts. 

**Fix this:**

1. Go to your Supabase dashboard
2. Click on **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. **Copy and paste** the entire contents of `fix_rls_policies.sql`
5. Click **Run** (or press Cmd+Enter)
6. You should see "Success" message

This will allow authenticated users to read, insert, and delete from all index tables.

## Issue 3: Users Not Showing / Empty List

After updating the Edge Function (Issue 1), the users should appear. The fix changes how the user list is returned.

## Issue 4: User Role Assignment

The Edge Function now properly sets the role when creating users. Make sure you:
- Check the "Admin" checkbox when creating an admin user
- Leave it unchecked for regular users

After fixing these, try:
1. Refresh the User Management page - you should see your 2 existing users
2. Try creating a new user - it should work without errors
3. Try adding an index - it should work without permission errors

