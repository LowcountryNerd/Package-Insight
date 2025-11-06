# Easiest Way to Deploy - Using Terminal (Don't Worry, It's Simple!)

The dashboard method has some issues. Let's use the terminal method - it's actually easier and more reliable!

## What You Need to Do

I'll give you **exact commands to copy and paste**. You don't need to understand them, just copy and paste!

## Step 1: Open Terminal on Your Mac

1. Press `Command + Space` (hold both keys)
2. Type: `Terminal`
3. Press Enter
4. A black window will open - that's your terminal!

## Step 2: Install Supabase CLI (One-Time Setup)

Copy and paste this command into the terminal, then press Enter:

```bash
brew install supabase/tap/supabase
```

**If you get an error about "brew not found":**
- Copy and paste this first: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Wait for it to finish (might take a few minutes)
- Then try the brew install command again

## Step 3: Login to Supabase

Copy and paste this command, then press Enter:

```bash
supabase login
```

- It will open your web browser
- Click "Authorize" or "Allow"
- Come back to the terminal - you should see "Successfully logged in"

## Step 4: Go to Your Project Folder

Copy and paste this command, then press Enter:

```bash
cd "/Users/ak/Documents/Package Insight"
```

## Step 5: Link Your Project

Copy and paste this command (I already know your project ID), then press Enter:

```bash
supabase link --project-ref savkvcxocobpwsyzrpcj
```

- It might ask for your database password - enter it if asked
- Or it might just work automatically

## Step 6: Deploy the Function

Copy and paste this command, then press Enter:

```bash
supabase functions deploy user-management
```

**That's it!** You should see "Function deployed successfully"

---

## If You Get Stuck

Just tell me:
1. What command you're on
2. What error message you see (copy and paste it)

I'll help you fix it!

