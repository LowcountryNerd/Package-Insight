import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { action, ...params } = await req.json()

    switch (action) {
      case 'list':
        const { data: users, error: listError } = await supabaseClient.auth.admin.listUsers()
        if (listError) throw listError
        return new Response(
          JSON.stringify({ success: true, users }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

      case 'create':
        const { email, password, isAdmin } = params
        if (!email || !password) {
          return new Response(
            JSON.stringify({ success: false, error: 'Email and password are required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        
        const { data: newUser, error: createError } = await supabaseClient.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          app_metadata: { role: isAdmin ? 'admin' : 'user' }
        })
        
        if (createError) throw createError
        return new Response(
          JSON.stringify({ success: true, user: newUser.user }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

      case 'delete':
        const { userId } = params
        if (!userId) {
          return new Response(
            JSON.stringify({ success: false, error: 'User ID is required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        
        const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(userId)
        if (deleteError) throw deleteError
        return new Response(
          JSON.stringify({ success: true }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

      case 'updateRole':
        const { userId: updateUserId, isAdmin: updateIsAdmin } = params
        if (!updateUserId) {
          return new Response(
            JSON.stringify({ success: false, error: 'User ID is required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        
        const { data: existingUser } = await supabaseClient.auth.admin.getUserById(updateUserId)
        if (!existingUser) {
          return new Response(
            JSON.stringify({ success: false, error: 'User not found' }),
            { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        
        const { data: updatedUser, error: updateError } = await supabaseClient.auth.admin.updateUserById(
          updateUserId,
          { app_metadata: { ...existingUser.user.app_metadata, role: updateIsAdmin ? 'admin' : 'user' } }
        )
        
        if (updateError) throw updateError
        return new Response(
          JSON.stringify({ success: true, user: updatedUser.user }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

      default:
        return new Response(
          JSON.stringify({ success: false, error: 'Invalid action' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

