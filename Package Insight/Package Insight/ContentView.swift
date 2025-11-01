import SwiftUI
struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Route based on user role
                if authManager.userRole == .admin {
                    AdminDashboardView()
                } else {
                    UserDashboardView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            authManager.checkAuthStatus()
        }
        .onOpenURL { url in
            Task {
                await authManager.handleDeepLink(url)
            }
        }
    }
}
#Preview {
    ContentView()
}