import SwiftUI
struct ScannerTestView: View {
    @StateObject private var scannerManager = SocketMobileScannerManager.shared
    @State private var scanHistory: [ScannedBarcodeData] = []
    @State private var showingClearAlert = false
    @State private var showingLogs = false
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Scanner Status Section
                scannerStatusSection
                // Discovered Devices Section
                discoveredDevicesSection
                // Scanner Controls Section
                scannerControlsSection
                // Scan Results Section
                scanResultsSection
                // Action Buttons Row
                HStack(spacing: 12) {
                    // Refresh Devices Button
                    Button(action: {
                        scannerManager.forceRefreshDevices()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Devices")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(!scannerManager.isInitialized)
                    // Logs Button
                    Button(action: {
                        showingLogs = true
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                            Text("View Logs (\(scannerManager.logMessages.count))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(8)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Scanner Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Clear Scan History", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    scanHistory.removeAll()
                }
            } message: {
                Text("This will clear all scan history. This action cannot be undone.")
            }
            .sheet(isPresented: $showingLogs) {
                LogViewerView(logMessages: scannerManager.logMessages)
            }
        }
        .onAppear {
            setupScannerDelegate()
            if !scannerManager.isInitialized {
                scannerManager.initializeScanner()
            }
        }
        .onReceive(scannerManager.$lastScannedData) { data in
            if let data = data {
                scanHistory.insert(data, at: 0)
            }
        }
    }
    // MARK: - Scanner Status Section
    private var scannerStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Scanner Status")
                    .font(.headline)
                Spacer()
            }
            HStack {
                Circle()
                    .fill(Color(scannerManager.scannerStatus.color))
                    .frame(width: 16, height: 16)
                Text(scannerManager.scannerStatus.displayName)
                    .font(.subheadline)
                    .foregroundColor(Color(scannerManager.scannerStatus.color))
                Spacer()
                if let deviceInfo = scannerManager.connectedDeviceInfo {
                    Text(deviceInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    // MARK: - Discovered Devices Section
    private var discoveredDevicesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Discovered Devices")
                    .font(.headline)
                Spacer()
                Text("\(scannerManager.discoveredDevices.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if scannerManager.discoveredDevices.isEmpty {
                Text("No devices discovered")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(scannerManager.discoveredDevices, id: \.self) { device in
                        HStack {
                            Image(systemName: "scanner")
                                .foregroundColor(.blue)
                            Text(device)
                                .font(.subheadline)
                            Spacer()
                            if scannerManager.connectedDeviceInfo == device {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    // MARK: - Scanner Controls Section
    private var scannerControlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Scanner Controls")
                    .font(.headline)
                Spacer()
            }
            HStack(spacing: 12) {
                Button(action: {
                    if scannerManager.scannerStatus == .connecting || scannerManager.scannerStatus == .connected {
                        scannerManager.stopScanning()
                    } else {
                        scannerManager.startScanning()
                    }
                }) {
                    HStack {
                        Image(systemName: scannerManager.scannerStatus == .connecting || scannerManager.scannerStatus == .connected ? "stop.circle" : "play.circle")
                        Text(scannerManager.scannerStatus == .connecting || scannerManager.scannerStatus == .connected ? "Stop Scanning" : "Start Scanning")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(scannerManager.scannerStatus == .connecting || scannerManager.scannerStatus == .connected ? Color.red : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(!scannerManager.isInitialized)
                Button(action: {
                    scannerManager.disconnectDevice()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Disconnect")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .disabled(scannerManager.scannerStatus != .connected)
                Spacer()
            }
        }
    }
    // MARK: - Scan Results Section
    private var scanResultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Scan Results")
                    .font(.headline)
                Spacer()
                Text("\(scanHistory.count) scans")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if scanHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No scans yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start scanning to see results here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(scanHistory.enumerated()), id: \.offset) { index, scanData in
                            ScanResultCard(scanData: scanData, index: index + 1)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    // MARK: - Helper Methods
    private func setupScannerDelegate() {
        scannerManager.setDelegate(ScannerTestDelegate(scannerTestView: self))
    }
    func onScannerDataReceived(_ data: ScannedBarcodeData) {
        print(" Scanner test received data: \(data.rawData)")
    }
    func onScannerConnected(_ deviceInfo: String) {
        print(" Scanner connected: \(deviceInfo)")
    }
    func onScannerDisconnected() {
        print(" Scanner disconnected")
    }
    func onScannerError(_ error: Error) {
        print(" Scanner error: \(error.localizedDescription)")
    }
    func onScannerDiscovered(_ deviceInfo: String) {
        print(" Device discovered: \(deviceInfo)")
    }
}
// MARK: - Scan Result Card
struct ScanResultCard: View {
    let scanData: ScannedBarcodeData
    let index: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scan #\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(scanData.timestamp, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Raw Data:")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(scanData.rawData)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Type: \(scanData.dataType)")
                        .font(.caption)
                    Text("Length: \(scanData.dataLength) bytes")
                        .font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let symbology = scanData.symbology {
                        Text("Symbology: \(symbology)")
                            .font(.caption)
                    }
                    if let device = scanData.deviceInfo {
                        Text("Device: \(device)")
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
}
// MARK: - Scanner Test Delegate
class ScannerTestDelegate: SocketMobileScannerManagerDelegate {
    private var scannerTestView: ScannerTestView?
    init(scannerTestView: ScannerTestView) {
        self.scannerTestView = scannerTestView
    }
    func scannerDidConnect(_ deviceInfo: String) {
        scannerTestView?.onScannerConnected(deviceInfo)
    }
    func scannerDidDisconnect() {
        scannerTestView?.onScannerDisconnected()
    }
    func scannerDidReceiveData(_ data: ScannedBarcodeData) {
        scannerTestView?.onScannerDataReceived(data)
    }
    func scannerDidEncounterError(_ error: Error) {
        scannerTestView?.onScannerError(error)
    }
    func scannerDidDiscoverDevice(_ deviceInfo: String) {
        scannerTestView?.onScannerDiscovered(deviceInfo)
    }
}
#Preview {
    ScannerTestView()
}