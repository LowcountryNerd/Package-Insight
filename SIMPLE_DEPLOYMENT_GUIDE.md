# Simple Deployment Guide - Step by Step

## What We're Doing
We're going to deploy a "user management" function to your Supabase project. This will let you create and delete users from your iOS app.

## Step 1: Get Your Project Information

### In Your Supabase Dashboard:

1. **Look at the top of your screen** - you should see your project name
2. **Click on "Settings"** (gear icon, usually in the left sidebar)
3. **Click on "API"** in the settings menu
4. **Find these two things:**
   - **Project URL**: Should look like `https://xxxxx.supabase.co`
   - **Project Reference ID**: This is the part before `.supabase.co` (for example, if your URL is `https://abc123.supabase.co`, your reference ID is `abc123`)

**Please tell me:**
- What is your Project Reference ID? (the part before `.supabase.co`)

## Step 2: Get Your Service Role Key

Still in the API settings page:

1. Scroll down to find **"service_role" key** (it's a long string that starts with `eyJ...`)
2. **IMPORTANT**: This key is secret! Don't share it publicly.
3. **Click the "Reveal" or "Show" button** to see the full key
4. Copy the entire key

**Please tell me:**
- What is your service_role key? (I'll help you use it securely)

## Step 3: I'll Help You Deploy

Once you give me:
1. Your Project Reference ID
2. Your service_role key

I'll give you simple commands to copy and paste into your computer's terminal.

---

## Alternative: Deploy via Supabase Dashboard (Easier!)

If you prefer, we can also deploy directly from the Supabase website:

1. In your Supabase dashboard, click **"Edge Functions"** in the left sidebar
2. Click **"Create a new function"**
3. Name it: `user-management`
4. I'll give you the code to paste in

**Which method do you prefer?**
- A) Terminal commands (faster, but requires installing a tool)
- B) Supabase Dashboard (easier, no installation needed)

Let me know what you find and which method you prefer!

