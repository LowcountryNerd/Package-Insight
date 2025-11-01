import Foundation
import Supabase
// MARK: - Custom URLSession Configuration for Cloudflare SSL Issues
private let customSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 45  // Increased timeout
    config.timeoutIntervalForResource = 90 // Increased timeout
    config.waitsForConnectivity = true
    config.allowsCellularAccess = true
    // Add headers that might help with Cloudflare
    config.httpAdditionalHeaders = [
        "User-Agent": "PackageInsight-iOS/1.0",
        "Accept": "application/json",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive"
    ]
    return URLSession(configuration: config)
}()
// MARK: - Supabase Configuration
// Real Supabase project credentials with custom session for TLS handling
// Supabase URL - New project with fresh SSL configuration
let supabaseURL = URL(string: "https://savkvcxocobpwsyzrpcj.supabase.co")!
let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: "sb_publishable_8yhrOhHpy7VHm-P4GkbjWg_z0rScLAf"
)
// MARK: - SSL Bypass for Development
// This is a temporary solution for SSL issues during development
// In production, proper SSL validation should be implemented
private func configureSSLForDevelopment() {
    // Set URLSession default configuration to handle SSL issues
    URLSessionConfiguration.default.timeoutIntervalForRequest = 30
    URLSessionConfiguration.default.timeoutIntervalForResource = 60
    URLSessionConfiguration.default.waitsForConnectivity = true
}
// MARK: - Test Account Credentials
// Use these credentials to test login functionality
struct TestAccount {
    static let email = "test@packageinsight.com"
    static let password = "TestPassword123!"
}
// MARK: - Configuration Instructions
/*
 TO SET UP SUPABASE:
 1. Go to https://supabase.com and create a new project
 2. Go to Settings > API
 3. Copy your Project URL and Publishable key
 4. Replace the values above:
    - YOUR_SUPABASE_URL: Your project URL (e.g., "https://your-project-id.supabase.co")
    - YOUR_SUPABASE_PUBLISHABLE_KEY: Your publishable key (starts with "sb_publishable_")
 5. Run the SQL schema from database_schema.sql in your Supabase SQL Editor
 6. Enable authentication providers in Authentication > Settings
 */