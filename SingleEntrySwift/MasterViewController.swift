//
//  MasterViewController.swift
//  SingleEntrySwift
//
//  IN ORDER TO USE SCANAPIHELPER IN YOUR SWIFT CODE, YOU WILL NEED TO ADD:
//  #import "ScanApiHelper.h"
//  IN YOUR SWIFT BRIDGING HEADER .H FILE
//  AND MAKE SURE THIS BRIDGING HEADER .H FILE IS SET IN YOUR PROJECT SETTINGS:
//  "OBJECTIVE C BRIDGING HEADER"
//
//  DON'T FORGET TO ADD com.socketmobile.chs in the Supported external accessory protocols
//  IN THE PROJECT INFO
//  AND TO ADD THE FOLLOWING FRAMEWORKS:
//  ExternalAccessory.framework
//  AudioToolbox.framework
//  AVFoundation.framework
//  And of course libScanAPI.a
//
//  NOTE ABOUT THE HOST ACKNOWLEDGMENT
//  This sample app shows how the Host application can Acknowledge the decoded data
//  To activate this feature go to the project settings and in the "Other Swift Flags"
//  rename this "-DNO_HOST_ACKNOWLEDGMENT" to this "-DHOST_ACKNOWLEDGMENT"
//  If your application does not require Acknowledgment then every thing that is related
//  to configuring ScanAPI or the Scanner for Local Acknowledgment can be safely ignored
//  because the Scanner comes setup to Local Acknowledgment by default. (Local Acknowledgment
//  means the decoded data gets acknowledged in the Scanner, and then they are sent to the host).
//
//  Created by Eric Glaenzer on 11/17/14.
// Copyright 2015 Socket Mobile, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
import UIKit
import ScanAPI

class MasterViewController: UITableViewController,ScanApiHelperDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = NSMutableArray()

    // ScanAPI Helper members initialization
    // WE WANT TO SHARE SCANAPIHELPER WITH ANOTHER VIEW
    // SO WE USE THE SHARED SCANAPIHELPER STATIC METHOD
    // OTHERWISE WE COULD HAVE JUST USE:
    // scanApiHelper = ScanApiHelper()
    // IF WE DON'T NEED ScanApiHelper IN OTHER VIEWS
    var scanApiHelper = ScanApiHelper.shared()
    var scanApiHelperConsumer = Timer()


    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // setup ScanAPI
        scanApiHelperConsumer=Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(MasterViewController.onScanApiHelperConsumer), userInfo: nil, repeats: true)
        // there is now a stack of delegates the last push is the
        // delegate active, when a new view requiring notifications from the
        // scanner, then push its delegate and pop its delegate when the
        // view is done
        scanApiHelper?.push(self)
        scanApiHelper?.open()

        // add SingleEntry item from the begining in the main list
        objects.insert("SingleEntry", at: 0);
        let indexPath=IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: AnyObject) {
        objects.insert(Date(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let object = objects[(indexPath as NSIndexPath).row] as? NSString {
                    let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                    controller.detailItem = object
                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell

        var description = "dont know"
        if let object = objects[(indexPath as NSIndexPath).row] as? NSString {
            description=object as String;
        }
        cell.textLabel?.text = description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.removeObject(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MARK: - ScanApiHelper Consumer
    func onScanApiHelperConsumer(){
        scanApiHelper?.doScanApiReceive()
    }

    // MARK: - ScanApiHelperDelegate

    func onDeviceArrival(_ result: SKTRESULT, device deviceInfo: DeviceInfo!) {
        print("Main view device arrival:\(deviceInfo.getName() as String)")
        // These few lines are only for the Host Acknowledgment feature,
        // if your application does not use this feature they can be removed
        // from the #if to the #endif
        #if HOST_ACKNOWLEDGMENT
            scanApiHelper?.postGetLocalAcknowledgmentDevice(deviceInfo, target: self, response: #selector(onGetLocalAcknowledgment(_:)))
            scanApiHelper?.postGetDecodeActionDevice(deviceInfo, target: self, response: #selector(onGetDecodeAction(_:)))
        #else // to remove the Host Acknowledgment if it was set before
            scanApiHelper?.postGetLocalAcknowledgmentDevice(deviceInfo, target: self, response: #selector(onGetLocalAcknowledgmentLocalAck(_:)))
            scanApiHelper?.postGetDecodeActionDevice(deviceInfo, target: self, response: #selector(onGetDecodeActionLocalAck(_:)))
        #endif
    }

    func onDeviceRemoval(_ deviceRemoved: DeviceInfo!) {
        print("Main view device removal:\(deviceRemoved.getName() as String)")
    }

    // if the onDecodedDataResult is used then this onDecodedData
    // won't be called by ScanApiHelper.
//    func onDecodedData(device: DeviceInfo!, decodedData: ISktScanDecodedData!) {
//        let rawData = decodedData.getData()
//        let rawDataSize = decodedData.getDataSize()
//        let data = NSData(bytes: rawData, length: Int(rawDataSize))
//        let str = NSString(data: data, encoding: NSUTF8StringEncoding)
//        let string = str as String
//        println("Decoded Data \(string)")
//    }

    // This is the new onDecodedDataResult to retrieve the decoded data received
    // from the scanner. This one has a result field that should be checked before
    // using the decoded data. It would be set to ESKT_CANCEL if the user
    // taps on the cancel button in the SoftScan View Finder
    func onDecodedDataResult(_ result: Int, device: DeviceInfo!, decodedData: ISktScanDecodedData!) {
        if result==ESKT_NOERROR {
            let rawData = decodedData.getData()
            let rawDataSize = decodedData.getSize()
            let data = Data(bytes: UnsafePointer<UInt8>(rawData!), count: Int(rawDataSize))
            print("Size: \(rawDataSize)")
            print("data: \(data)")
            let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            let string = str as! String
            print("Decoded Data \(string)")
            #if HOST_ACKNOWLEDGMENT
                scanApiHelper?.postSetDataConfirmation(device, goodData: true, target: self, response: #selector(onSetDataConfirmation(_:)));
            #endif
        }
    }

    func onError(_ result: SKTRESULT) {
        print("Receive a ScanApi error: \(result)")
    }

    func onErrorRetrievingScanObject(_ result: SKTRESULT) {
        print("Receive a ScanApi error while retrieving a ScanObject: \(result)")
    }

    func onScanApiInitializeComplete(_ result: SKTRESULT) {
        print("Result of ScanAPI initialization: \(result)")
        // if you don't need host Acknowledgment, and use the
        // scanner acknowledgment, then these few lines can be 
        // removed (from the #if to the #endif)
        #if HOST_ACKNOWLEDGMENT
            let mode = UInt8(kSktScanDataConfirmationModeApp.rawValue)
             scanApiHelper?.postSetConfirmationMode(mode, target: self, response: #selector(onSetDataConfirmationMode(_ :)))
        #else  // to remove the Host Acknowledgment if it was set before
            // put back to the default Scanner Acknowledgment also called Local Acknowledgment
            let mode = UInt8(kSktScanDataConfirmationModeDevice.rawValue)
            scanApiHelper?.postSetConfirmationMode(mode, target: self, response: #selector(onSetDataConfirmationMode(_ :)))
        #endif
    }

    func onScanApiTerminated() {
        print("ScanAPI has terminated")
    }
    
    // the following lines are only for the case of a host Acknowledgment
    // If your application does not use this feature, then they can be removed
    // from the #if to the #endif
    #if HOST_ACKNOWLEDGMENT
    
    func onSetDataConfirmationMode(_ scanObject:ISktScanObject) {
        let result = scanObject.msg().result()
        print("Data Confirmation Mode returns : \(result)")
    }
    
    func onSetDataConfirmation(_ scanObject:ISktScanObject) {
        let result = scanObject.msg().result()
        if(result != ESKT_NOERROR){
            print("Set Data Confirmation returns: \(result)")
        }
    }
    
    func onGetLocalAcknowledgment(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result == ESKT_NOERROR){
            let deviceInfo = scanApiHelper?.getDeviceInfo(from: scanObject)
            var localAck = scanObject.property().getByte()
            if localAck == UInt8(kSktScanDeviceDataAcknowledgmentOn.rawValue) {
                localAck = UInt8(kSktScanDeviceDataAcknowledgmentOff.rawValue)
                scanApiHelper?.postSetLocalAcknowledgmentDevice(deviceInfo, localAcknowledgment: localAck, target: self, response: #selector(onSetLocalAcknowledgment(_:)))
            }
        }
    }

    func onSetLocalAcknowledgment(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result != ESKT_NOERROR){
            print("Set Local Acknowledgment returs: \(result)")
        }
    }
    
    func onGetDecodeAction(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result == ESKT_NOERROR){
            let deviceInfo = scanApiHelper?.getDeviceInfo(from: scanObject)
            var decodeAction = scanObject.property().getByte()
            if decodeAction != UInt8(kSktScanLocalDecodeActionNone){
                decodeAction = UInt8(kSktScanLocalDecodeActionNone)
                scanApiHelper?.postSetDecodeActionDevice(deviceInfo, decodeAction: Int32(decodeAction), target: self, response: #selector(onSetDecodeAction(_:)))
            }
        }
    }
    
    func onSetDecodeAction(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result != ESKT_NOERROR){
            print("Set Decode Action returs: \(result)")
        }
    }
    
#else // to remove the Host Acknowledgment if it was set before
    func onSetDataConfirmationMode(_ scanObject:ISktScanObject) {
        let result = scanObject.msg().result()
        print("Data Confirmation Mode returns : \(result)")
    }
    
    func onSetDecodeAction(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result != ESKT_NOERROR){
            print("Set Decode Action returs: \(result)")
        }
    }
    
    func onGetDecodeActionLocalAck(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result == ESKT_NOERROR){
            let deviceInfo = scanApiHelper?.getDeviceInfo(from: scanObject)
            var decodeAction = scanObject.property().getByte()
            if decodeAction == UInt8(kSktScanLocalDecodeActionNone){
                decodeAction = UInt8(kSktScanLocalDecodeActionBeep|kSktScanLocalDecodeActionFlash|kSktScanLocalDecodeActionRumble)
                scanApiHelper?.postSetDecodeActionDevice(deviceInfo, decodeAction: Int32(decodeAction), target: self, response: #selector(onSetDecodeAction(_:)))
            }
        }
    }
    
    func onSetLocalAcknowledgment(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result != ESKT_NOERROR){
            print("Set Local Acknowledgment returs: \(result)")
        }
    }
    
    func onGetLocalAcknowledgmentLocalAck(_ scanObject: ISktScanObject) {
        let result = scanObject.msg().result()
        if(result == ESKT_NOERROR){
            let deviceInfo = scanApiHelper?.getDeviceInfo(from: scanObject)
            var localAck = scanObject.property().getByte()
            if localAck == UInt8(kSktScanDeviceDataAcknowledgmentOff.rawValue) {
                localAck = UInt8(kSktScanDeviceDataAcknowledgmentOn.rawValue)
                scanApiHelper?.postSetLocalAcknowledgmentDevice(deviceInfo, localAcknowledgment: localAck, target: self, response: #selector(onSetLocalAcknowledgment(_:)))
            }
        }
    }
    
#endif
}
