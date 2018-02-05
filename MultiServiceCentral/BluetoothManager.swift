//
//  BluetoothManager.swift
//  MultiServiceCentral
//
//  Created by Jay Tucker on 2/5/18.
//  Copyright © 2018 Imprivata. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BluetoothManager: NSObject {
    
    private let serviceUUIDs = [
        CBUUID(string: "A85E0941-9312-43E0-9DF1-AA553F8D1DCC"),
        CBUUID(string: "F1DB91CA-E679-4B74-BB44-64F547E586B5"),
        ]
    
    private let timeoutInSecs = 5.0
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    private var index = 0
    
    private var isPoweredOn = false
    private var scanTimer: Timer!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    func readService(index: Int) {
        log("readService \(index)")
        self.index = index
        startScanForPeripheral(serviceUuid: serviceUUIDs[index])
    }
    
    private func startScanForPeripheral(serviceUuid: CBUUID) {
        log("startScanForPeripheral \(serviceUuid.uuidString)")
        centralManager.stopScan()
        scanTimer = Timer.scheduledTimer(timeInterval: timeoutInSecs, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        centralManager.scanForPeripherals(withServices: [serviceUuid], options: nil) // [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    // can't be private because called by timer
    @objc func timeout() {
        log("timed out")
        centralManager.stopScan()
    }
    
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var caseString: String!
        switch central.state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        log("centralManagerDidUpdateState \(caseString!)")
        isPoweredOn = centralManager.state == .poweredOn
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log("centralManager didDiscoverPeripheral \(RSSI.intValue) \(peripheral.name ?? "none")")
        scanTimer.invalidate()
        central.stopScan()
        central.cancelPeripheralConnection(peripheral) // <-- this line
        central.connect(peripheral, options: nil)
        self.peripheral = peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("centralManager didConnectPeripheral")
        self.peripheral.delegate = self
        peripheral.discoverServices([serviceUUIDs[index]])
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let message = "peripheral didDiscoverServices " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for service in peripheral.services! {
            log("service \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let invalidatedUuids = invalidatedServices.map { $0.uuid }
        let message = "peripheral didModifyServices invalidatedServices: \(invalidatedServices.count) \(invalidatedUuids)"
        log(message)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let message = "peripheral didDiscoverCharacteristicsFor service " + (error == nil ? "\(service.uuid.uuidString) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for characteristic in service.characteristics! {
            log("characteristic \(characteristic.uuid.uuidString)")
            peripheral.readValue(for: characteristic)
        }
        // centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let message = "peripheral didUpdateValueFor characteristic " + (error == nil ? "\(characteristic.uuid.uuidString) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        let response = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
        log(response)
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
}
