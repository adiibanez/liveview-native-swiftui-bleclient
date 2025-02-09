import XCTest
@testable import LiveViewNativeBleClient // Replace with your project's name
import CoreBluetooth

class BLEClientCoordinatorTests: XCTestCase {
    
    var coordinator: BLEClientCoordinator!
    //var mockBluetoothManager: BluetoothManager!
    var testSettings: [String: Any]?

    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let testpath = Bundle(for: type(of: self)).path(forResource: "TestInfo", ofType: "plist")   
        print("Path: \(testpath)")
        
        if let path = Bundle(for: type(of: self)).path(forResource: "TestInfo", ofType: "plist"),
                   let xml = FileManager.default.contents(atPath: path) {
                    do {
                        testSettings = try PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any]
                    } catch {
                        XCTFail("Failed to load TestInfo.plist: \(error)")
                        testSettings = nil
                    }
                } else {
                    XCTFail("TestSettings.plist not found")
                    testSettings = nil
                }
        
        
        
        //mockBluetoothManager = BluetoothManager()
        coordinator = BLEClientCoordinator()
        
        
        
        
    }
    
    override func tearDownWithError() throws {
        coordinator = nil
        //mockBluetoothManager = nil
        try super.tearDownWithError()
    }
    
    
    func testStartScan() {
        
        let expectation = XCTestExpectation(description: "Asynchronous operation completion")
        
        // Start your asynchronous operation
        DispatchQueue.global().async {
            // Perform your asynchronous task (e.g., network request, timer)
            Thread.sleep(forTimeInterval: 1.0) // Simulate a 1-second delay
            
            // Fulfill the expectation when the operation is complete
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled (or timeout)
        wait(for: [expectation], timeout: 2.0) // Timeout after 2 seconds
        
        coordinator.startScan()
        
        
        let expectation2 = XCTestExpectation(description: "Asynchronous operation completion")
        
        // Start your asynchronous operation
        DispatchQueue.global().async {
            // Perform your asynchronous task (e.g., network request, timer)
            Thread.sleep(forTimeInterval: 1.0) // Simulate a 1-second delay
            
            // Fulfill the expectation when the operation is complete
            expectation2.fulfill()
        }
        
        // Wait for the expectation to be fulfilled (or timeout)
        wait(for: [expectation2], timeout: 2.0) // Timeout after 2 seconds
        
        
        
        //XCTAssertTrue(mockBluetoothManager.scanForPeripheralsCalled, "startScan should call scanForPeripherals on bleManager")
    }
    
    func testStopScan() {
        //coordinator.stopScan()
        //XCTAssertTrue(mockBluetoothManager.stopScanCalled, "stopScan should call stopScan on bleManager")
    }
    
    
    /*
     func testPeripheralDiscovered() {
     // Create a mock CBPeripheral
     let mockPeripheral = MockCBPeripheral()
     mockPeripheral.name = "Test Peripheral"
     let mockRSSI = -60
     
     // Simulate BluetoothManager discovering the peripheral
     mockBluetoothManager.simulatePeripheralDiscovery(peripheral: mockPeripheral, rssi: mockRSSI)
     
     // Verify that the coordinator's peripheralDiscovered property is updated
     XCTAssertNotNil(coordinator.peripheralDiscovered, "peripheralDiscovered should be updated")
     XCTAssertEqual(coordinator.peripheralDiscovered?.name, "Test Peripheral", "peripheralDiscovered name should match")
     XCTAssertEqual(coordinator.peripheralDiscovered?.rssi, mockRSSI, "peripheralDiscovered rssi should match")
     }*/
    /*
     func testDataReceived() {
     // Create a mock CBPeripheral
     let mockPeripheral = MockCBPeripheral()
     mockPeripheral.name = "Test Peripheral"
     
     // Create a mock CBUUID
     let mockCharacteristicUUID = CBUUID(string: "1234")
     
     // Simulate BluetoothManager receiving data
     let testValue = "Test Data"
     mockBluetoothManager.simulateDataReceived(peripheral: mockPeripheral, characteristicUUID: mockCharacteristicUUID, value: testValue)
     
     // Verify that the coordinator's valueChanged property is updated
     XCTAssertNotNil(coordinator.valueChanged, "valueChanged should be updated")
     XCTAssertEqual(coordinator.valueChanged?.value, testValue, "valueChanged value should match")
     XCTAssertEqual(coordinator.valueChanged?.characteristicUUID.uuidString, mockCharacteristicUUID.uuidString, "valueChanged uuid should match")
     }*/
}


/*
 // MARK: - MockBluetoothManager
 
 class MockBluetoothManager: BluetoothManager {
 var scanForPeripheralsCalled = false
 var stopScanCalled = false
 
 override init() {
 super.init()
 }
 
 override func scanForPeripherals() {
 scanForPeripheralsCalled = true
 }
 
 override func stopScan() {
 stopScanCalled = true
 }
 
 // Simulate peripheral discovery
 func simulatePeripheralDiscovery(peripheral: CBPeripheral, rssi: Int) {
 centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: NSNumber(value: rssi))
 }
 
 // Simulate data received
 func simulateDataReceived(peripheral: CBPeripheral, characteristicUUID: CBUUID, value: String) {
 if let data = value.data(using: .utf8) {
 let mockCharacteristic = MockCharacteristic(uuid: characteristicUUID, properties: [.read, .write, .notify], value: data, descriptors: nil)
 peripheral(centralManager as! CBPeripheral, didUpdateValueFor: mockCharacteristic, error: nil)
 }
 }
 }
 
 // MARK: - Mock CBPeripheral
 
 class MockCBPeripheral: CBPeripheral {
 override var name: String? {
 get {
 return mockName
 }
 set {
 mockName = newValue
 }
 }
 
 private var mockName: String?
 
 init(name: String? = nil) {
 mockName = name
 super.init()
 }
 }
 
 class MockCharacteristic: CBCharacteristic {
 private let mockUuid: CBUUID
 private let mockProperties: CBCharacteristicProperties
 private let mockValue: Data?
 private let mockDescriptors: [CBDescriptor]?
 
 override var uuid: CBUUID {
 return mockUuid
 }
 
 override var properties: CBCharacteristicProperties {
 return mockProperties
 }
 
 override var value: Data? {
 return mockValue
 }
 
 override var descriptors: [CBDescriptor]? {
 return mockDescriptors
 }
 
 init(uuid: CBUUID, properties: CBCharacteristicProperties, value: Data?, descriptors: [CBDescriptor]?) {
 self.mockUuid = uuid
 self.mockProperties = properties
 self.mockValue = value
 self.mockDescriptors = descriptors
 super.init()
 }
 }
 
 // MARK: - Helper
 extension BluetoothManager {
 func inject(centralManager: CBCentralManager){
 self.centralManager = centralManager
 }
 }
 */
