import Foundation
import Supabase
import Combine
// MARK: - Supabase Service
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    @Published var isConnected = false
    @Published var connectionError: String?
    private init() {
        // Test connection on initialization
        Task {
            await testConnection()
        }
    }
    // MARK: - Connection Testing
    func testConnection() async {
        do {
            // Simple test query to verify connection
            let _: [PackageRecord] = try await supabase
                .from("packages")
                .select()
                .limit(1)
                .execute()
                .value
            await MainActor.run {
                self.isConnected = true
                self.connectionError = nil
            }
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.connectionError = error.localizedDescription
            }
        }
    }
    // MARK: - Package Operations
    func createPackage(_ package: PackageRecord) async throws -> PackageRecord {
        let response: PackageRecord = try await supabase
            .from("packages")
            .insert(package)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    func fetchPackages() async throws -> [PackageRecord] {
        let response: [PackageRecord] = try await supabase
            .from("packages")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    func fetchPackage(by id: UUID) async throws -> PackageRecord {
        let response: PackageRecord = try await supabase
            .from("packages")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return response
    }
    func updatePackage(_ package: PackageRecord) async throws -> PackageRecord {
        let response: PackageRecord = try await supabase
            .from("packages")
            .update(package)
            .eq("id", value: package.id)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    // MARK: - Admin Operations
    func fetchANIWatchlist() async throws -> [ANIWatchlistItem] {
        let response: [ANIWatchlistItem] = try await supabase
            .from("ani_watchlist")
            .select()
            .execute()
            .value
        return response
    }
    func fetchVAISafeAccounts() async throws -> [VAISafeAccount] {
        let response: [VAISafeAccount] = try await supabase
            .from("vai_safe_accounts")
            .select()
            .execute()
            .value
        return response
    }
    func fetchCIIRanges() async throws -> [CIIRange] {
        let response: [CIIRange] = try await supabase
            .from("cii_ranges")
            .select()
            .execute()
            .value
        return response
    }
    func fetchOSIRules() async throws -> [OSIRule] {
        let response: [OSIRule] = try await supabase
            .from("osi_rules")
            .select()
            .execute()
            .value
        return response
    }
    func fetchRSIRules() async throws -> [RSIRule] {
        let response: [RSIRule] = try await supabase
            .from("rsi_rules")
            .select()
            .execute()
            .value
        return response
    }
    
    // MARK: - ANI Watchlist CRUD
    func createANIWatchlistItem(accountNumber: String, notes: String?, createdBy: UUID) async throws -> ANIWatchlistItem {
        struct InsertItem: Codable {
            let accountNumber: String
            let notes: String?
            let createdBy: String
            enum CodingKeys: String, CodingKey {
                case accountNumber = "account_number"
                case notes
                case createdBy = "created_by"
            }
        }
        let item = InsertItem(accountNumber: accountNumber, notes: notes, createdBy: createdBy.uuidString)
        let response: ANIWatchlistItem = try await supabase
            .from("ani_watchlist")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func deleteANIWatchlistItem(id: UUID) async throws {
        try await supabase
            .from("ani_watchlist")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - VAI Safe Accounts CRUD
    func createVAISafeAccount(accountNumber: String, notes: String?, createdBy: UUID) async throws -> VAISafeAccount {
        struct InsertAccount: Codable {
            let accountNumber: String
            let notes: String?
            let createdBy: String
            enum CodingKeys: String, CodingKey {
                case accountNumber = "account_number"
                case notes
                case createdBy = "created_by"
            }
        }
        let account = InsertAccount(accountNumber: accountNumber, notes: notes, createdBy: createdBy.uuidString)
        let response: VAISafeAccount = try await supabase
            .from("vai_safe_accounts")
            .insert(account)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func deleteVAISafeAccount(id: UUID) async throws {
        try await supabase
            .from("vai_safe_accounts")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - CII Ranges CRUD
    func createCIIRange(minValue: Double, maxValue: Double, points: Int, notes: String?, createdBy: UUID) async throws -> CIIRange {
        struct InsertRange: Codable {
            let minValue: Double
            let maxValue: Double
            let points: Int
            let notes: String?
            let createdBy: String
            enum CodingKeys: String, CodingKey {
                case minValue = "min_value"
                case maxValue = "max_value"
                case points
                case notes
                case createdBy = "created_by"
            }
        }
        let range = InsertRange(minValue: minValue, maxValue: maxValue, points: points, notes: notes, createdBy: createdBy.uuidString)
        let response: CIIRange = try await supabase
            .from("cii_ranges")
            .insert(range)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func deleteCIIRange(id: UUID) async throws {
        try await supabase
            .from("cii_ranges")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - OSI Rules CRUD
    func createOSIRule(pattern: String, points: Int, notes: String?, createdBy: UUID) async throws -> OSIRule {
        struct InsertRule: Codable {
            let pattern: String
            let points: Int
            let active: Bool
            let notes: String?
            let createdBy: String
            enum CodingKeys: String, CodingKey {
                case pattern, points, active, notes
                case createdBy = "created_by"
            }
        }
        let rule = InsertRule(pattern: pattern, points: points, active: true, notes: notes, createdBy: createdBy.uuidString)
        let response: OSIRule = try await supabase
            .from("osi_rules")
            .insert(rule)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func deleteOSIRule(id: UUID) async throws {
        try await supabase
            .from("osi_rules")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - RSI Rules CRUD
    func createRSIRule(pattern: String, points: Int, notes: String?, createdBy: UUID) async throws -> RSIRule {
        struct InsertRule: Codable {
            let pattern: String
            let points: Int
            let active: Bool
            let notes: String?
            let createdBy: String
            enum CodingKeys: String, CodingKey {
                case pattern, points, active, notes
                case createdBy = "created_by"
            }
        }
        let rule = InsertRule(pattern: pattern, points: points, active: true, notes: notes, createdBy: createdBy.uuidString)
        let response: RSIRule = try await supabase
            .from("rsi_rules")
            .insert(rule)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func deleteRSIRule(id: UUID) async throws {
        try await supabase
            .from("rsi_rules")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - User Management (via Edge Function)
    struct UserManagementRequest: Codable {
        let action: String
        let email: String?
        let password: String?
        let userId: String?
        let isAdmin: Bool?
        
        enum CodingKeys: String, CodingKey {
            case action, email, password, userId, isAdmin
        }
    }
    
    struct UserManagementResponse: Codable {
        let success: Bool
        let users: [User]?
        let user: User?
        let error: String?
    }
    
    func fetchUsers() async throws -> [User] {
        let request = UserManagementRequest(action: "list", email: nil, password: nil, userId: nil, isAdmin: nil)
        let response: UserManagementResponse = try await supabase.functions
            .invoke("user-management", options: .init(body: request))
        guard response.success, let users = response.users else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: response.error ?? "Failed to fetch users"])
        }
        return users
    }
    
    func createUser(email: String, password: String, isAdmin: Bool = false) async throws -> User {
        let request = UserManagementRequest(action: "create", email: email, password: password, userId: nil, isAdmin: isAdmin)
        let response: UserManagementResponse = try await supabase.functions
            .invoke("user-management", options: .init(body: request))
        guard response.success, let user = response.user else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: response.error ?? "Failed to create user"])
        }
        return user
    }
    
    func deleteUser(userId: UUID) async throws {
        let request = UserManagementRequest(action: "delete", email: nil, password: nil, userId: userId.uuidString, isAdmin: nil)
        let response: UserManagementResponse = try await supabase.functions
            .invoke("user-management", options: .init(body: request))
        guard response.success else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: response.error ?? "Failed to delete user"])
        }
    }
    
    func updateUserRole(userId: UUID, isAdmin: Bool) async throws -> User {
        let request = UserManagementRequest(action: "updateRole", email: nil, password: nil, userId: userId.uuidString, isAdmin: isAdmin)
        let response: UserManagementResponse = try await supabase.functions
            .invoke("user-management", options: .init(body: request))
        guard response.success, let user = response.user else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: response.error ?? "Failed to update user role"])
        }
        return user
    }
    
    // MARK: - Edge Function Calls
    func callFedExTrack(trackingNumber: String) async throws -> FedExTrackResponse {
        let parameters = FedExTrackRequest(trackingNumber: trackingNumber)
        return try await supabase.functions
            .invoke("fedex-track", options: .init(body: parameters))
    }
    func createScan(data: CreateScanRequest) async throws -> CreateScanResponse {
        let parameters = CreateScanFunctionRequest(
            rawBarcode: data.rawBarcode,
            parsed: CreateScanParsedData(
                tracking: data.parsed.trackingNumber ?? "",
                ani: data.parsed.ani ?? "",
                adi: data.parsed.adi ?? "",
                rsi: data.parsed.rsi ?? ""
            ),
            userId: data.userId.uuidString
        )
        return try await supabase.functions
            .invoke("create-scan", options: .init(body: parameters))
    }
    func runRiskEngine(scanId: UUID) async throws -> RiskEngineResponse {
        let parameters = RiskEngineRequest(scanId: scanId.uuidString)
        return try await supabase.functions
            .invoke("risk-engine", options: .init(body: parameters))
    }
}
// MARK: - Supporting Types
// MARK: - Edge Function Request/Response Types
struct CreateScanRequest: Codable {
    let rawBarcode: String
    let parsed: ParsedBarcode
    let userId: UUID
    enum CodingKeys: String, CodingKey {
        case parsed
        case rawBarcode = "raw_barcode"
        case userId = "user_id"
    }
}
struct CreateScanResponse: Codable {
    let success: Bool
    let scanId: UUID
    let status: String
    enum CodingKeys: String, CodingKey {
        case success, status
        case scanId = "scan_id"
    }
}
struct FedExTrackResponse: Codable {
    let success: Bool
    let trackingNumber: String
    let dimensions: PackageDimensions?
    let weight: PackageWeight?
    let originCity: String?
    let originState: String?
    let originCountry: String?
    let addressType: String?
    let shippingType: String?
    enum CodingKeys: String, CodingKey {
        case success, dimensions, weight
        case trackingNumber = "tracking_number"
        case originCity = "origin_city"
        case originState = "origin_state"
        case originCountry = "origin_country"
        case addressType = "address_type"
        case shippingType = "shipping_type"
    }
}
struct RiskEngineResponse: Codable {
    let scanId: UUID
    let totalScore: Int
    let triggeredIndices: [String]
    let package: PackageRecord
    enum CodingKeys: String, CodingKey {
        case package
        case scanId = "scan_id"
        case totalScore = "total_score"
        case triggeredIndices = "triggered_indices"
    }
}
// MARK: - Edge Function Request Types
struct FedExTrackRequest: Codable {
    let trackingNumber: String
    enum CodingKeys: String, CodingKey {
        case trackingNumber = "tracking_number"
    }
}
struct CreateScanFunctionRequest: Codable {
    let rawBarcode: String
    let parsed: CreateScanParsedData
    let userId: String
    enum CodingKeys: String, CodingKey {
        case parsed
        case rawBarcode = "raw_barcode"
        case userId = "user_id"
    }
}
struct CreateScanParsedData: Codable {
    let tracking: String
    let ani: String
    let adi: String
    let rsi: String
}
struct RiskEngineRequest: Codable {
    let scanId: String
    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
    }
}