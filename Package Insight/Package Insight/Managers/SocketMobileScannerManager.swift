import Foundation
import Combine
import CaptureSDK
enum ScannerStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    var displayName: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    var color: String {
        switch self {
        case .disconnected:
            return "gray"
        case .connecting:
            return "orange"
        case .connected:
            return "green"
        case .error:
            return "red"
        }
    }
}
struct ScannedBarcodeData {
    let rawData: String
    let timestamp: Date
    let deviceInfo: String?
    let symbology: String?
    let dataLength: Int
    let dataType: String
    init(rawData: String, deviceInfo: String? = nil, symbology: String? = nil) {
        self.rawData = rawData
        self.timestamp = Date()
        self.deviceInfo = deviceInfo
        self.symbology = symbology
        self.dataLength = rawData.count
        self.dataType = symbology ?? "Unknown"
    }
    var displayString: String {
        return "Data: \(rawData)\nSymbology: \(symbology ?? "Unknown")\nLength: \(dataLength) chars"
    }
}
protocol SocketMobileScannerManagerDelegate: AnyObject {
    func scannerDidConnect(_ deviceInfo: String)
    func scannerDidDisconnect()
    func scannerDidReceiveData(_ data: ScannedBarcodeData)
    func scannerDidEncounterError(_ error: Error)
    func scannerDidDiscoverDevice(_ deviceInfo: String)
}
class SocketMobileScannerManager: NSObject, ObservableObject {
    @Published var scannerStatus: ScannerStatus = .disconnected
    @Published var connectedDeviceInfo: String?
    @Published var lastScannedData: ScannedBarcodeData?
    @Published var isInitialized = false
    @Published var discoveredDevices: [String] = []
    @Published var logMessages: [String] = []
    private let captureHelper = CaptureHelper.sharedInstance
    private weak var delegate: SocketMobileScannerManagerDelegate?
    private var connectedDevice: CaptureHelperDevice?
    private var isDelegatePushed = false
    private var reconnectTimer: Timer?
    private let appInfo: SKTAppInfo = {
        let info = SKTAppInfo()
        info.appKey = "MC0CFBf5DveM7YTzBkRG7x20RbI6q87TAhUAjjDVV9UeUy/TmR+aemQkAXljDfo="
        info.appID = "ios:ai.packageinsight.packageinsight"
        info.developerID = "25d91908-3883-f011-b4cc-000d3a332a84"
        return info
    }()
    static let shared = SocketMobileScannerManager()
    private override init() {
        super.init()
    }
    deinit {
        reconnectTimer?.invalidate()
    }
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        DispatchQueue.main.async { [weak self] in
            self?.logMessages.append(logEntry)
            if let count = self?.logMessages.count, count > 200 {
                self?.logMessages.removeFirst(count - 200)
            }
        }
        print(message)
    }
    func initializeScanner() {
        addLog("[Scanner] Initializing Socket Mobile CaptureSDK")
        ensureDelegateSetup()
        guard !isInitialized else {
            addLog("[Scanner] CaptureSDK already initialized")
            return
        }
        captureHelper.openWithAppInfo(appInfo) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .E_NOERROR:
                    self?.addLog("[Scanner] CaptureSDK initialized successfully")
                    self?.isInitialized = true
                    self?.scannerStatus = .connecting
                default:
                    let errorMessage = "Failed to initialize CaptureSDK: \(result.rawValue)"
                    self?.addLog("[Scanner] ERROR: \(errorMessage)")
                    self?.isInitialized = false
                    self?.scannerStatus = .error(errorMessage)
                }
            }
        }
    }
    func reinitializeScanner() {
        addLog("[Scanner] Reinitializing...")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        connectedDevice = nil
        connectedDeviceInfo = nil
        discoveredDevices.removeAll()
        scannerStatus = .connecting
        ensureDelegateSetup()
        if isInitialized {
            startScanning()
        } else {
            initializeScanner()
        }
    }
    func startScanning() {
        guard isInitialized else {
            addLog("[Scanner] ERROR: Not initialized")
            initializeScanner()
            return
        }
        addLog("[Scanner] Starting device scanning...")
        ensureDelegateSetup()
        scannerStatus = .connecting
    }
    func stopScanning() {
        addLog("[Scanner] Stopping device scanning...")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        scannerStatus = .disconnected
    }
    func disconnectDevice() {
        addLog("[Scanner] Disconnecting...")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        connectedDevice = nil
        DispatchQueue.main.async {
            self.connectedDeviceInfo = nil
            self.scannerStatus = .disconnected
            self.delegate?.scannerDidDisconnect()
        }
    }
    func forceRefreshDevices() {
        addLog("[Scanner] Force refreshing devices...")
        guard isInitialized else {
            initializeScanner()
            return
        }
        discoveredDevices.removeAll()
        connectedDevice = nil
        connectedDeviceInfo = nil
        scannerStatus = .connecting
    }
    func setDelegate(_ delegate: SocketMobileScannerManagerDelegate?) {
        self.delegate = delegate
    }
    func getDiscoveredDevices() -> [String] {
        return discoveredDevices
    }
    func simulateBarcodeScan(_ barcodeData: String, symbology: String? = "CODE128") {
        let scannedData = ScannedBarcodeData(
            rawData: barcodeData,
            deviceInfo: connectedDeviceInfo ?? "Simulated Device",
            symbology: symbology
        )
        self.lastScannedData = scannedData
        self.delegate?.scannerDidReceiveData(scannedData)
        print("[Scanner] Simulated scan: \(barcodeData)")
    }
    func simulateFedExScan() {
        let sampleFedExTracking = "1Z999AA1234567890"
        simulateBarcodeScan(sampleFedExTracking, symbology: "CODE128")
    }
    private func ensureDelegateSetup() {
        guard !isDelegatePushed else {
            return
        }
        captureHelper.pushDelegate(self)
        captureHelper.dispatchQueue = DispatchQueue.main
        isDelegatePushed = true
        print("[Scanner] Delegate pushed to CaptureHelper")
    }
    private func startReconnectionTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if case .disconnected = self.scannerStatus, self.isInitialized {
                print("[Scanner] Attempting to reconnect...")
                self.startScanning()
            }
        }
    }
    private func isSocketCamDevice(_ device: CaptureHelperDevice) -> Bool {
        let deviceName = device.deviceInfo.name?.lowercased() ?? ""
        return deviceName.contains("socketcam")
    }
    private func handleScannedData(_ rawData: String, deviceInfo: String?, symbology: String?) {
        let scannedData = ScannedBarcodeData(
            rawData: rawData,
            deviceInfo: deviceInfo,
            symbology: symbology
        )
        DispatchQueue.main.async {
            self.lastScannedData = scannedData
            self.delegate?.scannerDidReceiveData(scannedData)
        }
        print("[Scanner] Scanned: \(rawData), Device: \(deviceInfo ?? "Unknown")")
    }
}
extension SocketMobileScannerManager: CaptureHelperDeviceDecodedDataDelegate,
                                      CaptureHelperDevicePresenceDelegate,
                                      CaptureHelperErrorDelegate,
                                      CaptureHelperDeviceManagerPresenceDelegate {
    func didReceiveDecodedData(_ decodedData: SKTCaptureDecodedData?,
                               fromDevice device: CaptureHelperDevice,
                               withResult result: SKTResult) {
        guard result == .E_NOERROR, let decodedData = decodedData else {
            print("[Scanner] Failed to decode data: \(result.rawValue)")
            return
        }
        if isSocketCamDevice(device) {
            print("[Scanner] Ignoring SocketCam virtual device data")
            return
        }
        let rawData = decodedData.stringFromDecodedData() ?? ""
        let symbology = "Barcode"
        handleScannedData(rawData, deviceInfo: device.deviceInfo.name, symbology: symbology)
    }
    func didNotifyArrivalForDevice(_ device: CaptureHelperDevice, withResult result: SKTResult) {
        let deviceName = device.deviceInfo.name ?? "Unknown Device"
        let deviceType = device.deviceInfo.deviceType.rawValue
        addLog("[Scanner] Device arrival - Name: '\(deviceName)', Type: \(deviceType), Result: \(result.rawValue)")
        guard result == .E_NOERROR else {
            addLog("[Scanner] Device arrival failed: \(result.rawValue)")
            return
        }
        if isSocketCamDevice(device) {
            addLog("[Scanner] Filtering out SocketCam virtual device")
            return
        }
        addLog("[Scanner] Processing physical scanner: \(deviceName)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.connectedDevice = device
            self.connectedDeviceInfo = deviceName
            if !self.discoveredDevices.contains(deviceName) {
                self.discoveredDevices.append(deviceName)
                addLog("[Scanner] Added to discovered: \(deviceName)")
            }
            self.scannerStatus = .connected
            self.delegate?.scannerDidConnect(deviceName)
            self.delegate?.scannerDidDiscoverDevice(deviceName)
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = nil
            addLog("[Scanner] Scanner connected: \(deviceName)")
        }
    }
    func didNotifyRemovalForDevice(_ device: CaptureHelperDevice, withResult result: SKTResult) {
        let deviceName = device.deviceInfo.name ?? "Unknown"
        if isSocketCamDevice(device) {
            return
        }
        print("[Scanner] Device removed: \(deviceName)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.connectedDevice === device {
                self.connectedDevice = nil
                self.connectedDeviceInfo = nil
                self.scannerStatus = .disconnected
                self.delegate?.scannerDidDisconnect()
                self.discoveredDevices.removeAll { $0 == deviceName }
                self.startReconnectionTimer()
                print("[Scanner] Scanner disconnected, will attempt reconnect")
            } else {
                self.discoveredDevices.removeAll { $0 == deviceName }
            }
        }
    }
    func didNotifyArrivalForDeviceManager(_ deviceManager: CaptureHelperDeviceManager,
                                          withResult result: SKTResult) {
        addLog("[Scanner] Device Manager arrived - Result: \(result.rawValue)")
    }
    func didNotifyRemovalForDeviceManager(_ deviceManager: CaptureHelperDeviceManager,
                                          withResult result: SKTResult) {
        addLog("[Scanner] Device Manager removed - Result: \(result.rawValue)")
    }
    func didReceiveError(_ error: SKTResult) {
        let errorMessage = "Scanner error: \(error.rawValue)"
        print("[Scanner] ERROR: \(errorMessage)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.scannerStatus = .error(errorMessage)
            self.delegate?.scannerDidEncounterError(NSError(domain: "SocketMobileScanner",
                                                           code: error.rawValue,
                                                           userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            if error.rawValue != -15 {
                self.startReconnectionTimer()
            }
        }
    }
}