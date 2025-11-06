import Foundation
// MARK: - Package Record Model
struct PackageRecord: Codable, Identifiable {
    let id: UUID
    let trackingNumber: String
    let ani: String? // Account Number Index
    let vai: Bool? // Vet Account Index (safe account match)
    let adi: String? // Address Detection Index
    let rsi: String? // Receiver Street Index
    let osi: String? // Origin Source Index
    let pdi: PackageDimensions? // Package Dimension Index
    let pwi: PackageWeight? // Package Weight Index
    let cii: Double? // Cubic Inch Index
    let triggeredIndices: [String] // Array of triggered risk indices
    let totalScore: Int // Risk score (0-100)
    let rawBarcode: String
    let userId: UUID
    let status: PackageStatus
    let createdAt: Date
    let updatedAt: Date
    enum CodingKeys: String, CodingKey {
        case id, trackingNumber = "tracking_number"
        case ani, vai, adi, rsi, osi, pdi, pwi, cii
        case triggeredIndices = "triggered_indices"
        case totalScore = "total_score"
        case rawBarcode = "raw_barcode"
        case userId = "user_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
// MARK: - Supporting Models
struct PackageDimensions: Codable {
    let length: Double
    let width: Double
    let height: Double
    let unit: String // "in" or "cm"
    var volume: Double {
        return length * width * height
    }
}
struct PackageWeight: Codable {
    let value: Double
    let unit: String // "LB" or "KG"
}
enum PackageStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case success = "success"
    case error = "error"
}
// MARK: - Parsed Barcode Data
struct ParsedBarcode: Codable {
    let trackingNumber: String?
    let ani: String? // Account Number
    let adi: String? // Full Address
    let rsi: String? // Street Only
    let rawData: String
}
// MARK: - Risk Score Display
struct RiskScoreDisplay {
    let score: Int
    let triggeredIndices: [String]
    let color: RiskColor
    let message: String
    enum RiskColor {
        case green, amber, red
        var systemColor: String {
            switch self {
            case .green: return "green"
            case .amber: return "orange"
            case .red: return "red"
            }
        }
        static func fromScore(_ score: Int) -> RiskColor {
            switch score {
            case 0...25: return .green
            case 26...75: return .amber
            default: return .red
            }
        }
    }
    static func create(from package: PackageRecord) -> RiskScoreDisplay {
        let color = RiskColor.fromScore(package.totalScore)
        let message = package.totalScore == 0 ? "Safe" : "Risk Level: \(package.totalScore)"
        return RiskScoreDisplay(
            score: package.totalScore,
            triggeredIndices: package.triggeredIndices,
            color: color,
            message: message
        )
    }
}
// MARK: - Admin Models
struct ANIWatchlistItem: Codable, Identifiable {
    let id: UUID
    let accountNumber: String
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, accountNumber = "account_number"
        case notes, createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id
        if let idString = try? container.decode(String.self, forKey: .id),
           let idUUID = UUID(uuidString: idString) {
            id = idUUID
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Handle created_by as UUID string or UUID
        if let createdByString = try? container.decode(String.self, forKey: .createdBy),
           let createdByUUID = UUID(uuidString: createdByString) {
            createdBy = createdByUUID
        } else if let createdByUUID = try? container.decode(UUID.self, forKey: .createdBy) {
            createdBy = createdByUUID
        } else {
            // Fallback: use current user or generate new UUID
            print("[ANIWatchlistItem] Warning: created_by missing, using placeholder")
            createdBy = UUID()
        }
        
        // Handle date as ISO string or Date
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            print("[ANIWatchlistItem] Warning: created_at missing, using current date")
            createdAt = Date()
        }
    }
}
struct VAISafeAccount: Codable, Identifiable {
    let id: UUID
    let accountNumber: String
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, accountNumber = "account_number"
        case notes, createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idString = try? container.decode(String.self, forKey: .id),
           let idUUID = UUID(uuidString: idString) {
            id = idUUID
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        if let createdByString = try? container.decode(String.self, forKey: .createdBy),
           let createdByUUID = UUID(uuidString: createdByString) {
            createdBy = createdByUUID
        } else if let createdByUUID = try? container.decode(UUID.self, forKey: .createdBy) {
            createdBy = createdByUUID
        } else {
            print("[VAISafeAccount] Warning: created_by missing, using placeholder")
            createdBy = UUID()
        }
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            print("[VAISafeAccount] Warning: created_at missing, using current date")
            createdAt = Date()
        }
    }
}
struct CIIRange: Codable, Identifiable {
    let id: UUID
    let minValue: Double
    let maxValue: Double
    let points: Int
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, minValue = "min_value"
        case maxValue = "max_value"
        case points, notes, createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idString = try? container.decode(String.self, forKey: .id),
           let idUUID = UUID(uuidString: idString) {
            id = idUUID
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        minValue = try container.decode(Double.self, forKey: .minValue)
        maxValue = try container.decode(Double.self, forKey: .maxValue)
        points = try container.decode(Int.self, forKey: .points)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        if let createdByString = try? container.decode(String.self, forKey: .createdBy),
           let createdByUUID = UUID(uuidString: createdByString) {
            createdBy = createdByUUID
        } else if let createdByUUID = try? container.decode(UUID.self, forKey: .createdBy) {
            createdBy = createdByUUID
        } else {
            print("[CIIRange] Warning: created_by missing, using placeholder")
            createdBy = UUID()
        }
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            print("[CIIRange] Warning: created_at missing, using current date")
            createdAt = Date()
        }
    }
}
struct OSIRule: Codable, Identifiable {
    let id: UUID
    let pattern: String
    let points: Int
    let active: Bool
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, pattern, points, active, notes
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idString = try? container.decode(String.self, forKey: .id),
           let idUUID = UUID(uuidString: idString) {
            id = idUUID
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        pattern = try container.decode(String.self, forKey: .pattern)
        points = try container.decode(Int.self, forKey: .points)
        active = try container.decode(Bool.self, forKey: .active)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        if let createdByString = try? container.decode(String.self, forKey: .createdBy),
           let createdByUUID = UUID(uuidString: createdByString) {
            createdBy = createdByUUID
        } else if let createdByUUID = try? container.decode(UUID.self, forKey: .createdBy) {
            createdBy = createdByUUID
        } else {
            print("[OSIRule] Warning: created_by missing, using placeholder")
            createdBy = UUID()
        }
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            print("[OSIRule] Warning: created_at missing, using current date")
            createdAt = Date()
        }
    }
}
struct RSIRule: Codable, Identifiable {
    let id: UUID
    let pattern: String
    let points: Int
    let active: Bool
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, pattern, points, active, notes
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idString = try? container.decode(String.self, forKey: .id),
           let idUUID = UUID(uuidString: idString) {
            id = idUUID
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        pattern = try container.decode(String.self, forKey: .pattern)
        points = try container.decode(Int.self, forKey: .points)
        active = try container.decode(Bool.self, forKey: .active)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        if let createdByString = try? container.decode(String.self, forKey: .createdBy),
           let createdByUUID = UUID(uuidString: createdByString) {
            createdBy = createdByUUID
        } else if let createdByUUID = try? container.decode(UUID.self, forKey: .createdBy) {
            createdBy = createdByUUID
        } else {
            print("[RSIRule] Warning: created_by missing, using placeholder")
            createdBy = UUID()
        }
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            print("[RSIRule] Warning: created_at missing, using current date")
            createdAt = Date()
        }
    }
}