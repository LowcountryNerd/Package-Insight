# User Management Edge Function

This Edge Function provides secure user management operations using Supabase's service role key.

## Features

- **List Users**: Get all users in the system
- **Create User**: Create new users with optional admin role
- **Delete User**: Remove users from the system
- **Update Role**: Change user roles (admin/user)

## Deployment

### Prerequisites

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

### Deploy the Function

From the project root directory:

```bash
supabase functions deploy user-management
```

The function will automatically use the `SUPABASE_SERVICE_ROLE_KEY` environment variable from your Supabase project.

## Security

- ✅ Service role key is stored securely in Supabase (never in client)
- ✅ All operations require authentication
- ✅ CORS headers configured for cross-origin requests
- ✅ Input validation on all operations

## API Usage

The function accepts POST requests with the following structure:

```json
{
  "action": "list|create|delete|updateRole",
  "email": "user@example.com",      // Required for create
  "password": "securepassword",     // Required for create
  "user_id": "uuid-string",         // Required for delete/updateRole
  "is_admin": true                  // Optional for create/updateRole
}
```

### Example: Create User

```json
{
  "action": "create",
  "email": "newuser@example.com",
  "password": "SecurePassword123!",
  "is_admin": false
}
```

### Example: List Users

```json
{
  "action": "list"
}
```

### Example: Delete User

```json
{
  "action": "delete",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

### Example: Update Role

```json
{
  "action": "updateRole",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "is_admin": true
}
```

## Response Format

All responses follow this structure:

```json
{
  "success": true,
  "users": [...],      // For list action
  "user": {...},       // For create/updateRole actions
  "error": "..."       // Only present on error
}
```

## Testing

After deployment, test the function:

```bash
curl -X POST https://your-project.supabase.co/functions/v1/user-management \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "list"}'
```

