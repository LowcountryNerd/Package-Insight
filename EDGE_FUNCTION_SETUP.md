# Edge Function Setup Guide

## Production-Ready User Management

This project uses **Supabase Edge Functions** for secure user management. This is the **best practice for production** because:

✅ **Service role key stays on the server** (never exposed to clients)  
✅ **Secure API endpoints** with proper authentication  
✅ **Scalable serverless architecture**  
✅ **No backend server required**  

## Quick Setup

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link Your Project

Get your project reference ID from your Supabase dashboard, then:

```bash
cd "/Users/ak/Documents/Package Insight"
supabase link --project-ref savkvcxocobpwsyzrpcj
```

### 4. Deploy the Function

```bash
supabase functions deploy user-management
```

That's it! The function is now live and your iOS app can use it.

## What Gets Deployed

The Edge Function (`supabase/functions/user-management/index.ts`) provides:

- **List Users** - Get all users
- **Create User** - Create new users with admin/user roles
- **Delete User** - Remove users
- **Update Role** - Change user roles

## How It Works

1. iOS app calls `supabaseService.createUser(...)`
2. Request goes to Edge Function (not directly to Supabase)
3. Edge Function uses service role key (secure, server-side)
4. Edge Function performs the operation
5. Response sent back to iOS app

## Security Benefits

- ✅ Service role key never leaves Supabase servers
- ✅ All operations are authenticated
- ✅ Input validation prevents malicious requests
- ✅ CORS properly configured

## Troubleshooting

### Function Not Found

Make sure you've deployed:
```bash
supabase functions deploy user-management
```

### Authentication Errors

The Edge Function automatically uses your project's service role key. No configuration needed.

### Testing Locally

You can test locally before deploying:
```bash
supabase functions serve user-management
```

## Next Steps

1. Deploy the function (see Quick Setup above)
2. Test user management in the iOS app
3. All CRUD operations should work now!

## Support

If you encounter issues:
- Check Supabase dashboard → Functions → Logs
- Verify the function is deployed
- Ensure your project reference is correct

