//
//  WebBluetooth.swift
//  BleBrowser
//
//  Created by Paul Theriault on 7/03/2016.
//  Copyright © 2016-2017 Paul Theriault & David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import CoreBluetooth
import WebKit


open class WBDevice: NSObject, Jsonifiable, CBPeripheralDelegate {
    // MARK: - Embedded types
    enum DeviceRequests: String {
        case connectGATT, disconnectGATT, getPrimaryServices,
        getCharacteristic, getCharacteristics, readCharacteristicValue, startNotifications,
        stopNotifications,
        writeCharacteristicValue
    }
    // MARK: Transaction views
    class DeviceTransactionView: WBTransaction.View {
        let externalDeviceUUID: UUID

        override init?(transaction: WBTransaction) {
            guard
                let uuidstr = transaction.messageData["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidstr)
                else {
                    return nil
            }
            self.externalDeviceUUID = uuid
            super.init(transaction: transaction)
        }
    }
    
    class ServicesTransactionView: DeviceTransactionView {
        let serviceUUID: CBUUID?
        
        override init?(transaction: WBTransaction) {
            if let pservStr = transaction.messageData["serviceUUID"] as? String {
                guard let pservUUID = UUID(uuidString: pservStr) else {
                    return nil
                }
                self.serviceUUID = CBUUID(nsuuid: pservUUID)
            } else {
                self.serviceUUID = nil
            }
            super.init(transaction: transaction)
        }
        func resolveFromServices(_ services: [CBService]) {
            let uuids = services.map{$0.uuid}.filter{
                self.serviceUUID == nil || self.serviceUUID == $0
            }
            if uuids.count > 0 {
                self.transaction.resolveAsSuccess(withObject: uuids)
            } else {
                self.transaction.resolveAsFailure(withMessage: self.serviceUUID != nil ? "Service \(self.serviceUUID!.uuidString) not known on device" : "No services found")
            }
        }
    }
    
    class ServiceTransactionView: DeviceTransactionView {
        let serviceUUID: CBUUID

        override init?(transaction: WBTransaction) {
            guard
                let pservStr = transaction.messageData["serviceUUID"] as? String,
                let pservUUID = UUID(uuidString: pservStr)
                else {
                    return nil
            }
            self.serviceUUID = CBUUID(nsuuid: pservUUID)
            super.init(transaction: transaction)
        }

        func resolveUnknownService() {
            self.transaction.resolveAsFailure(withMessage: "Service \(self.serviceUUID.uuidString) not known on device")
        }
    }
    
    class CharacteristicView: ServiceTransactionView {
        let characteristicUUID: CBUUID

        override init?(transaction: WBTransaction) {
            guard
                let charStr = transaction.messageData["characteristicUUID"] as? String,
                let charUUID = UUID(uuidString: charStr)
                else {
                    return nil
            }
            self.characteristicUUID = CBUUID(nsuuid: charUUID)
            super.init(transaction: transaction)
        }
        func matchesCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
            guard
                let serviceUUID = characteristic.service?.uuid else {
                    return false;
                }
            return (
                self.serviceUUID == serviceUUID
                && self.characteristicUUID == characteristic.uuid
            )
        }
        func resolveUnknownCharacteristic() {
            self.transaction.resolveAsFailure(withMessage: "Characteristic \(self.characteristicUUID.uuidString) not known for service \(self.serviceUUID.uuidString) on device")
        }
    }
    
    class CharacteristicsView: ServiceTransactionView {
        override init?(transaction: WBTransaction) {
            super.init(transaction: transaction)
        }
    }
    
    class WriteCharacteristicView: CharacteristicView {
        enum ResponseMode: String {
            case optional, required, never
        }

        let responseMode: ResponseMode
        let data: Data

        override init?(transaction: WBTransaction) {
            guard
                let bytes = transaction.messageData["value"] as? [UInt8],
                let rmstr = transaction.messageData["responseMode"] as? String,
                let responseMode = ResponseMode(rawValue: rmstr)
            else {
                NSLog("Invalid WriteCharacteristic message \(transaction.messageData)")
                return nil
            }
            self.data = Data(bytes)
            self.responseMode = responseMode
            super.init(transaction: transaction)
        }
    }
    
    struct ServicesTransactionKey: Hashable {
        
    }

    struct CharacteristicTransactionKey: Hashable {
        let serviceUUID: CBUUID
        let characteristicUUID: CBUUID

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.serviceUUID)
            hasher.combine(self.characteristicUUID)
        }
        static func == (left: CharacteristicTransactionKey, right: CharacteristicTransactionKey) -> Bool {
            return left.serviceUUID == right.serviceUUID && left.characteristicUUID == right.characteristicUUID
        }
    }
    
    struct CharacteristicsTransactionKey: Hashable {
        let serviceUUID: CBUUID

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.serviceUUID)
        }
    }

    // MARK: - Properties
    let debug = false
    var deviceId = UUID() // generated ID used instead of internal iOS name
    var peripheral: CBPeripheral
    var adData: BluetoothAdvertisingData
    var name: String? {
        get {
            return self.peripheral.name
        }
    }
    var internalUUID: UUID {
        get {
            return self.peripheral.identifier
        }
    }

    weak var manager: WBManager?

    /*! @abstract The view should be set when the device is selected by a particular web view. */
    weak var view: WKWebView? = nil

    /*! @abstract The current transactions to connect to this device. There can be multiple outstanding at any one time and they are all resolved together. */
    var connectTransactions = [WBTransaction]()
    var disconnectTM = WBTransactionManager<UUID>()
    var getPrimaryServicesTM = WBTransactionManager<CBUUID?>()
    var getCharacteristicTM = WBTransactionManager<CharacteristicTransactionKey>()
    var getCharacteristicsTM = WBTransactionManager<CharacteristicsTransactionKey>()
    var readCharacteristicTM = WBTransactionManager<CharacteristicTransactionKey>()
    /*! @abstract Outstanding transactions for characteristic write requests */
    var writeCharacteristicTM = WBTransactionManager<CharacteristicTransactionKey>()

    // MARK: - Constructor and equality
    init(peripheral: CBPeripheral, advertisementData: [String: Any] = [:], RSSI: NSNumber = 0, manager: WBManager) {
        self.peripheral = peripheral
        self.adData = BluetoothAdvertisingData(advertisementData:advertisementData,RSSI: RSSI)
        self.manager = manager
        super.init()
        self.peripheral.delegate = self
    }
    static func ==(left: WBDevice, right: WBDevice) -> Bool {
        return left.peripheral == right.peripheral
    }

    // MARK: - API
    func clearState() {
        self.manager?.centralManager.cancelPeripheralConnection(self.peripheral)
        for var ta in [self.connectTransactions] {
            for trans in ta {
                trans.abandon()
            }
            ta.removeAll()
        }
        self.disconnectTM.abandonAll()
        self.sendDisconnectEvent()
        self.getPrimaryServicesTM.abandonAll()
        self.getCharacteristicTM.abandonAll()
        self.getCharacteristicsTM.abandonAll()
        self.readCharacteristicTM.abandonAll()
    }
    func didConnect() {
        self.connectTransactions.forEach{$0.resolveAsSuccess()}
    }
    func didFailToConnect() {
        self.connectTransactions.forEach{
            $0.resolveAsFailure(withMessage: "Unable to connect to device")
        }
    }
    func didDisconnect(error: Error?) {
        NSLog("\(self) did disconnect \(error?.localizedDescription ?? "<no error>")")
        defer {
            self.sendDisconnectEvent()
        }

        let failTrans: (WBTransaction) -> Void = {
            $0.resolveAsFailure(withMessage: "Device disconnected\(error != nil ? ": \(error!.localizedDescription)" : "")")
        }
        self.writeCharacteristicTM.apply(failTrans)
        self.readCharacteristicTM.apply(failTrans)
        self.getCharacteristicTM.apply(failTrans)
        self.getPrimaryServicesTM.apply(failTrans)
        self.connectTransactions.forEach(failTrans)
        if let err = error {
            NSLog("Spontaneous device disconnect. \(err)")
            self.disconnectTM.apply(failTrans)
            return
        }
        self.disconnectTM.apply{$0.resolveAsSuccess()}
    }

    func triage(_ tview: DeviceTransactionView) {
        let transaction = tview.transaction
        let tc = transaction.key.typeComponents
        guard
            tc.count > 1,
            let deviceMessageType = DeviceRequests(rawValue: tc[1])
        else {
            transaction.resolveAsFailure(withMessage: "Unknown request type \(tc.joined(separator: ":"))")
            return
        }

        switch deviceMessageType {
        case .connectGATT:
            guard let man = self.manager else {
                transaction.resolveAsFailure(withMessage: "Failed due to internal inconsistency likely related to a recent page navigation (device's manager was released)")
                return
            }

            if self.debug {
                NSLog("Connecting to GATT on device \(self)")
            }

            man.centralManager.connect(self.peripheral)
            // async, so save transaction to resolve when connected
            transaction.addCompletionHandler({
                transaction, _ in
                if let ind = self.connectTransactions.firstIndex(of: transaction) {
                    self.connectTransactions.remove(at: ind)
                }
            })
            self.connectTransactions.append(transaction)

        case .disconnectGATT:
            NSLog("Disconnect GATT requested \(self)")
            self.handleDisconnect(tview)

        case .getPrimaryServices:
            guard let tview = ServicesTransactionView(transaction: transaction)
            else {
                transaction.resolveAsFailure(withMessage: "Invalid request")
                return
            }

            self.handleGetPrimaryServices(tview)

        case .getCharacteristic:
            guard
                let view = CharacteristicView(transaction: transaction)
            else {
                transaction.resolveAsFailure(withMessage: "Invalid message")
                break
            }

            guard let service = self.getService(withUUID: view.serviceUUID)
            else {
                view.resolveUnknownService()
                return
            }

            if let chars = service.characteristics {
                // Have already discovered characteristics for this device.
                if chars.contains(where: {$0.uuid == view.characteristicUUID}) {
                    transaction.resolveAsSuccess()
                } else {
                    view.resolveUnknownCharacteristic()
                }
                break
            }

            self.getCharacteristicTM.addTransaction(transaction, atPath: CharacteristicTransactionKey(serviceUUID: service.uuid, characteristicUUID: view.characteristicUUID))
            NSLog("Start discovering characteristics for service \(service.uuid)")
            self.peripheral.discoverCharacteristics(nil, for: service)

        case .getCharacteristics:
            guard let view = CharacteristicsView(transaction: transaction)
            else {
                transaction.resolveAsFailure(withMessage: "Invalid getCharacteristics message")
                break
            }

            guard let service = self.getService(withUUID: view.serviceUUID)
            else {
                view.resolveUnknownService()
                return
            }

            if let chars = service.characteristics {
                self.getCharacteristicsTM.apply({
                    var characteristicUUIDs: [String] = []
                    chars.forEach({ (characteristic) in
                        characteristicUUIDs.append(characteristic.uuid.uuidString)
                    })
                    $0.resolveAsSuccess(withObject: characteristicUUIDs)
                })
                
                break
            }

            self.getCharacteristicsTM.addTransaction(transaction, atPath: CharacteristicsTransactionKey(serviceUUID: view.serviceUUID))
            NSLog("Start discovering characteristics for service \(service.uuid)")
            self.peripheral.discoverCharacteristics(nil, for: service)

        case .readCharacteristicValue:
            guard
                let view = CharacteristicView(transaction: transaction)
            else {
                transaction.resolveAsFailure(withMessage: "Invalid message")
                break
            }
            guard let service = self.getService(withUUID: view.serviceUUID) else {
                view.resolveUnknownService()
                break
            }
            guard let chars = service.characteristics else {
                transaction.resolveAsFailure(withMessage: "Characteristics have not yet been retrieved for service \(service.uuid.uuidString)")
                break
            }
            guard let char = chars.first(where: {$0.uuid == view.characteristicUUID}) else {
                view.resolveUnknownCharacteristic()
                break
            }

            self.readCharacteristicTM.addTransaction(transaction, atPath: CharacteristicTransactionKey(serviceUUID: view.serviceUUID, characteristicUUID: view.characteristicUUID))
            self.peripheral.readValue(for: char)

        case .writeCharacteristicValue:
            guard
                let view = WriteCharacteristicView(transaction: transaction)
            else {
                transaction.resolveAsFailure(withMessage: "Invalid write characteristic message")
                break
            }

            guard
                let char = self.getCharacteristic(view.serviceUUID, uuid: view.characteristicUUID)
            else {
                view.resolveUnknownCharacteristic()
                break
            }

            self.writeCharacteristicValue(char, view)

        case .startNotifications:
            guard let view = CharacteristicView(transaction: transaction) else {
                transaction.resolveAsFailure(withMessage: "Invalid start notifications message")
                break
            }

            guard let char = self.getCharacteristic(view.serviceUUID, uuid: view.characteristicUUID) else {
                view.resolveUnknownCharacteristic()
                break
            }
            NSLog("Starting notifications for characteristic \(view.characteristicUUID.uuidString) on device \(self.peripheral.name ?? "<no-name>")")

            self.peripheral.setNotifyValue(true, for: char)
            transaction.resolveAsSuccess()

        case .stopNotifications:
            guard let view = CharacteristicView(transaction: transaction) else {
                transaction.resolveAsFailure(withMessage: "Invalid start notifications message")
                break
            }

            guard let char = self.getCharacteristic(view.serviceUUID, uuid: view.characteristicUUID) else {
                view.resolveUnknownCharacteristic()
                break
            }
            NSLog("Stopping notifications for characteristic \(view.characteristicUUID.uuidString) on device \(self.peripheral.name ?? "<no-name>")")

            self.peripheral.setNotifyValue(false, for: char)
            transaction.resolveAsSuccess()
        }
    }
    
    func jsonify() -> String {
        let props: [String: Any] = [
            "id": self.deviceId.uuidString,
            "name": (self.peripheral.name ?? NSNull()) as Any,
            "adData": self.adData.toDict(),
            "deviceClass": 0,
            "vendorIDSource": 0,
            "vendorID": 0,
            "productID": 0,
            "productVersion": 0,
            "uuids": [] as [String],
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: props)
            return String(data: jsonData, encoding: String.Encoding.utf8)!
        } catch let error {
            assert(false, "error converting to json: \(error)")
            return ""
        }
    }

    // MARK: - CBPeripheralDelegate
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        var resolve: (WBTransaction) -> Void
        if let err = error {
            resolve = {
                $0.resolveAsFailure(withMessage: "An error occurred discovering services for the device: \(err)")
            }
        } else {
            resolve = {
                ServicesTransactionView(transaction: $0)!.resolveFromServices(self.peripheral.services!)
            }
        }
        
        /* All outstanding requests for a primary service can be resolved. */
        if (self.getPrimaryServicesTM.transactions.count > 0) {
            self.getPrimaryServicesTM.apply(resolve)
        }
    }

    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        if let error_ = error {
            // speculative avoid crash judging by potential bug
            // in error as per https://forums.developer.apple.com/thread/84866
            NSLog("Error discovering characteristics: \(error_)")
            return
        }
        
        // Handle multiple characteristics
        if (self.getCharacteristicsTM.transactions.count > 0) {
            self.getCharacteristicsTM.apply({
                var characteristicUUIDs: [String] = []
                service.characteristics?.forEach({ (characteristic) in
                    characteristicUUIDs.append(characteristic.uuid.uuidString)
                })
                $0.resolveAsSuccess(withObject: characteristicUUIDs)
            },
            iff: { CharacteristicsView(transaction: $0)?.serviceUUID == service.uuid })
        }
        
        // Handle single characteristic
        if (self.getCharacteristicTM.transactions.count > 0) {
            self.getCharacteristicTM.apply({
                let cview = CharacteristicView(transaction: $0)!
                guard service.characteristics?.first(where: {$0.uuid == cview.characteristicUUID}) != nil else {
                    cview.resolveUnknownCharacteristic()
                    return
                }
                $0.resolveAsSuccess()
            },
            iff: {CharacteristicView(transaction: $0)?.serviceUUID == service.uuid})
        }
    }

    open func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            NSLog("Error \(err) adding notifications to device \(peripheral.name ?? "<no-name>") for characteristic \(characteristic.uuid.uuidString)")
        } else {
            NSLog("Notifications \(characteristic.isNotifying ? "enabled" : "disabled") on device \(peripheral.name ?? "<no-name>") for characteristic \(characteristic.uuid.uuidString)")
        }
    }

    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.readCharacteristicTM.transactions.count > 0 {
            // We have read transactions outstanding, which means that this is a response after a read request, so complete those transactions.
            self.readCharacteristicTM.apply({
                if let err = error {
                    $0.resolveAsFailure(withMessage: "Error reading characteristic: \(err.localizedDescription)")
                    return
                }
                $0.resolveAsSuccess(withObject: characteristic.value!)
            },
                iff: {CharacteristicView(
                    transaction: $0
                )!.matchesCharacteristic(
                    characteristic
                )}
            )
        }
        // If we're doing notifications on the characteristic send them up.
        if characteristic.isNotifying {
            self.evaluateJavaScript(
                "receiveCharacteristicValueNotification(" +
                "\(self.deviceId.uuidString.jsonify()), " +
                "\(characteristic.uuid.uuidString.lowercased().jsonify()), " +
                "\(characteristic.value!.jsonify())" +
                ")")
        }
    }

    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.writeCharacteristicTM.apply({
            if let err = error {
                $0.resolveAsFailure(withMessage: "Error writing characteristic: \(err.localizedDescription)")
                return
            }
            $0.resolveAsSuccess()
        },
            iff: {CharacteristicView(
                transaction: $0
                )!.matchesCharacteristic(
                    characteristic
                )}
        )
    }

    // MARK: - CustomStringConvertible
    public override var description: String {
        return "\(self.name ?? "<no-name>") (\(self.internalUUID))"
    }

    // MARK: - Private
    func handleDisconnect(_ tview: DeviceTransactionView) {
        guard let man = self.manager else {
            tview.transaction.resolveAsFailure(withMessage: "Failed due to internal inconsistency likely related to a recent page navigation (device's manager was released)")
            return
        }
        self.disconnectTM.addTransaction(tview.transaction, atPath: self.deviceId)
        man.centralManager.cancelPeripheralConnection(self.peripheral)
    }

    private func getService(withUUID uuid: CBUUID) -> CBService?{
        guard
            let pservs = self.peripheral.services,
            let ind = pservs.firstIndex(where: {$0.uuid == uuid})
        else {
            return nil
        }
        return pservs[ind]
    }
    private func hasService(withUUID uuid: CBUUID) -> Bool {
        return self.getService(withUUID: uuid) != nil
    }
    
    private func getCharacteristic(_ serviceUUID:CBUUID, uuid:CBUUID) -> CBCharacteristic? {
        if(self.peripheral.services == nil){
            return nil
        }
        var service:CBService? = nil
        for s in self.peripheral.services!{
            if(s.uuid == serviceUUID){
                service = s
                break
            }
        }
        
        guard let chars = service?.characteristics else {
            return nil
        }
        
        for char in chars{
            if(char.uuid == uuid){
                return char
            }
        }
        return nil
    }

    private func handleGetPrimaryServices(_ tview: ServicesTransactionView) {
        let transaction = tview.transaction
        
        // check peripherals.services first to see if we already discovered services
        guard let services = self.peripheral.services else {
            self.getPrimaryServicesTM.addTransaction(transaction, atPath: tview.serviceUUID)
            NSLog("Starting discovering for services on peripheral \(self.peripheral.name ?? "<unknown name>")")
            self.peripheral.discoverServices(nil)
            return
        }
        tview.resolveFromServices(services)
    }

    private func evaluateJavaScript(_ script: String) {
        guard let wv = self.view else {
            NSLog("Can't evaluate javascript as have no webview")
            return
        }
        wv.evaluateJavaScript(
            script,
            completionHandler: {
                _, error in
                if let err = error {
                    NSLog("Error evaluating \(script): \(err)")
                }
            }
        )
    }

    private func sendDisconnectEvent() {
        /* Don't lower case the deviceId string because we rely on the web page not to touch it. */
        let commandString = "window.receiveDeviceDisconnectEvent(\(self.deviceId.uuidString.jsonify()));\n"
        NSLog("Send disconnect event for \(self.deviceId.uuidString)")
        self.evaluateJavaScript(commandString)
    }

    private func writeCharacteristicValue(_ char: CBCharacteristic, _ view: WriteCharacteristicView) {

        switch view.responseMode {
        case .required:
                guard char.properties.contains(.write) else {
                    view.transaction.resolveAsFailure(withMessage: "Write with response not supported")
                    return
                }

                self.peripheral.writeValue(view.data, for: char, type: .withResponse)
                self.writeCharacteristicTM.addTransaction(
                    view.transaction,
                    atPath: CharacteristicTransactionKey(
                        serviceUUID: view.serviceUUID, characteristicUUID: view.characteristicUUID
                    )
                )
        case .never:
                guard char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse)
                else {
                    view.transaction.resolveAsFailure(
                        withMessage: "Characteristic does not support writing"
                    )
                    return
                }
                self.peripheral.writeValue(view.data, for: char, type: .withoutResponse)
                view.transaction.resolveAsSuccess()
        case .optional:
            // optional is in fact deprecated and the instructions are "Use any combination of the
            // sub procedures" in webbluetoothcg.github.io/web-bluetooth/#writecharacteristicvalue
            // so we do a write with response if possible else without.
            if char.properties.contains(.write) {
                self.peripheral.writeValue(view.data, for: char, type: .withResponse)
                self.writeCharacteristicTM.addTransaction(
                    view.transaction,
                    atPath: CharacteristicTransactionKey(
                        serviceUUID: view.serviceUUID, characteristicUUID: view.characteristicUUID
                    )
                )
            } else if char.properties.contains(.writeWithoutResponse) {
                self.peripheral.writeValue(view.data, for: char, type: .withoutResponse)
                view.transaction.resolveAsSuccess()
            } else {
                view.transaction.resolveAsFailure(withMessage: "Characteristic does not support writing")
            }
        }
    }
}

/*!
 *  @class BluetoothAdvertisingData
 *
 *  @discussion This encapsulates the data required for a BluetoothAdvertisingEvent as per https://webbluetoothcg.github.io/web-bluetooth/#advertising-events .
 */
class BluetoothAdvertisingData{
    var appearance:String
    var txPower:NSNumber
    var rssi: String
    var manufacturerData:String
    var serviceData:[String]
    
    init(advertisementData: [String: Any], RSSI: NSNumber){
        self.appearance = "fakeappearance"
        self.txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber ?? 0)
        self.rssi = String(describing: RSSI)
        let data = advertisementData[CBAdvertisementDataManufacturerDataKey]
        self.manufacturerData = ""
        if data != nil {
            if let dataString = NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue) as String? {
                self.manufacturerData = dataString
            } else {
                NSLog("Error parsing advertisement data: not a valid UTF-8 sequence, was \(data as! Data)")
            }
        }
        
        var uuids = [String]()
        if advertisementData["kCBAdvDataServiceUUIDs"] != nil {
            uuids = (advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID]).map{$0.uuidString.lowercased()}
        }
        self.serviceData = uuids
    }
    
    func toDict()->[String:AnyObject]{
        let dict:[String:AnyObject] = [
            "appearance": self.appearance as AnyObject,
            "txPower": self.txPower,
            "rssi": self.rssi as AnyObject,
            "manufacturerData": self.manufacturerData as AnyObject,
            "serviceData": self.serviceData as AnyObject
        ]
        return dict
    }
}
