import Foundation
// MARK: - Barcode Parser
struct BarcodeParser {
    // MARK: - GS1-128 Application Identifiers
    private struct ApplicationIdentifiers {
        static let trackingNumber = "00" // Serial Shipping Container Code (SSCC)
        static let accountNumber = "420" // Ship to / Deliver to Postal Code
        static let address = "410" // Ship to / Deliver to Company Name
        static let street = "411" // Ship to / Deliver to Address Line 1
    }
    // MARK: - Parse Barcode Data
    static func parse(_ rawData: String) -> ParsedBarcode {
        let cleanData = cleanBarcodeData(rawData)
        var trackingNumber: String?
        var ani: String?
        var adi: String?
        var rsi: String?
        // Try GS1-128 parsing first
        if let gs1Data = parseGS1128(cleanData) {
            trackingNumber = gs1Data.trackingNumber
            ani = gs1Data.ani
            adi = gs1Data.adi
            rsi = gs1Data.rsi
        }
        // Try PDF417 parsing if GS1-128 didn't yield results
        if trackingNumber == nil {
            if let pdf417Data = parsePDF417(cleanData) {
                trackingNumber = pdf417Data.trackingNumber
                ani = pdf417Data.ani
                adi = pdf417Data.adi
                rsi = pdf417Data.rsi
            }
        }
        return ParsedBarcode(
            trackingNumber: trackingNumber,
            ani: ani,
            adi: adi,
            rsi: rsi,
            rawData: rawData
        )
    }
    // MARK: - Clean Barcode Data
    private static func cleanBarcodeData(_ data: String) -> String {
        return data
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }
    // MARK: - GS1-128 Parser
    private static func parseGS1128(_ data: String) -> ParsedBarcode? {
        var trackingNumber: String?
        var ani: String?
        var adi: String?
        var rsi: String?
        var index = data.startIndex
        while index < data.endIndex {
            // Look for Application Identifier (2-4 digits)
            let aiEnd = findAIEnd(data, start: index)
            guard aiEnd > index else { break }
            let ai = String(data[index..<aiEnd])
            let valueStart = aiEnd
            let valueEnd = findValueEnd(data, start: valueStart, ai: ai)
            if valueEnd > valueStart {
                let value = String(data[valueStart..<valueEnd])
                switch ai {
                case ApplicationIdentifiers.trackingNumber:
                    trackingNumber = value
                case ApplicationIdentifiers.accountNumber:
                    ani = value
                case ApplicationIdentifiers.address:
                    adi = value
                case ApplicationIdentifiers.street:
                    rsi = value
                default:
                    break
                }
            }
            index = valueEnd
        }
        // Return result if we found at least one field
        if trackingNumber != nil || ani != nil || adi != nil || rsi != nil {
            return ParsedBarcode(
                trackingNumber: trackingNumber,
                ani: ani,
                adi: adi,
                rsi: rsi,
                rawData: data
            )
        }
        return nil
    }
    // MARK: - PDF417 Parser (Simplified)
    private static func parsePDF417(_ data: String) -> ParsedBarcode? {
        // PDF417 parsing is more complex and format-specific
        // This is a simplified implementation for common FedEx/UPS formats
        // Look for common tracking number patterns
        let trackingPatterns = [
            "\\d{12}", // 12-digit tracking
            "\\d{18}", // 18-digit tracking
            "1Z[0-9A-Z]{16}", // UPS tracking
            "[0-9]{4}\\s[0-9]{4}\\s[0-9]{4}", // FedEx format
        ]
        var trackingNumber: String?
        for pattern in trackingPatterns {
            if let match = data.range(of: pattern, options: .regularExpression) {
                trackingNumber = String(data[match])
                break
            }
        }
        // Extract account number (usually 9-10 digits)
        if let accountMatch = data.range(of: "\\d{9,10}", options: .regularExpression) {
            let ani = String(data[accountMatch])
            return ParsedBarcode(
                trackingNumber: trackingNumber,
                ani: ani,
                adi: nil,
                rsi: nil,
                rawData: data
            )
        }
        return trackingNumber != nil ? ParsedBarcode(
            trackingNumber: trackingNumber,
            ani: nil,
            adi: nil,
            rsi: nil,
            rawData: data
        ) : nil
    }
    // MARK: - Helper Methods
    private static func findAIEnd(_ data: String, start: String.Index) -> String.Index {
        var index = start
        var digitCount = 0
        while index < data.endIndex && digitCount < 4 {
            if data[index].isNumber {
                digitCount += 1
            } else {
                break
            }
            index = data.index(after: index)
        }
        return index
    }
    private static func findValueEnd(_ data: String, start: String.Index, ai: String) -> String.Index {
        // Value length depends on the Application Identifier
        // This is simplified - real implementation would use AI specifications
        let maxLength = ai == ApplicationIdentifiers.trackingNumber ? 18 : 20
        var index = start
        var length = 0
        while index < data.endIndex && length < maxLength {
            if data[index].isLetter || data[index].isNumber {
                length += 1
                index = data.index(after: index)
            } else {
                break
            }
        }
        return index
    }
}