//
//  SettingsViewController.swift
//  SingleEntrySwift
//
//  Created by Eric Glaenzer on 10/27/15.
//  Copyright © 2015 Socket Mobile, Inc. All rights reserved.
//

import UIKit
import ScanAPI

class SettingsViewController: UIViewController, ScanApiHelperDelegate{
    var detailItem: AnyObject?

    @IBOutlet weak var softscan: UISwitch!
    @IBOutlet weak var scanApiVersion: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ScanApiHelper.shared().push(self)
        // Do any additional setup after loading the view.
        
        // retrieve the current status of SoftScan
        ScanApiHelper.shared().postGetSoftScanStatus(self, response: #selector(SettingsViewController.onGetSoftScanStatus(_:)))
        
        // ask for the ScanAPI version
        ScanApiHelper.shared().postGetScanApiVersion(self, response: #selector(SettingsViewController.onGetScanApiVersion(_:)))
    }

    override func viewDidDisappear(_ animated: Bool) {
        ScanApiHelper.shared().pop(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func changeSoftScan(_ sender: AnyObject) {
        if(!softscan.isOn){
            print("disabling SoftScan...")
            ScanApiHelper.shared().postSetSoftScanStatus(UInt8(kSktScanDisableSoftScan), target: self, response: #selector(SettingsViewController.onSetSoftScanStatus(_:)))
        }
        else{
            print("enabling SoftScan...")
            ScanApiHelper.shared().postSetSoftScanStatus(UInt8(kSktScanEnableSoftScan), target: self, response: #selector(SettingsViewController.onSetSoftScanStatus(_:)))
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - ScanApiHelper results
    func onGetSoftScanStatus(_ scanObj: ISktScanObject!) {
        print("onGetSoftScanStatus received!")
        let result = scanObj.msg().result()
        print("Result:", result)
        if(result == ESKT_NOERROR){
            let status = Int(scanObj.property().getByte())
            print("receive SoftScan status:",status)
            if ( status == kSktScanEnableSoftScan){
                softscan.isOn = true
            }
            else{
                softscan.isOn = false
                if(status == kSktScanSoftScanNotSupported){
                    ScanApiHelper.shared().postSetSoftScanStatus(UInt8(kSktScanSoftScanSupported), target: self, response: #selector(SettingsViewController.onSetSoftScanStatus(_:)))
                }
            }
        }
    }
    
    func onSetSoftScanStatus(_ scanObj: ISktScanObject){
        
    }
    
    func onGetScanApiVersion(_ scanObj: ISktScanObject!) {
        print("onGetScanApiVersion received!")
        let result = scanObj.msg().result()
        print("Result:", result)
        if(result == ESKT_NOERROR){
            let version = scanObj.property().version()!
            let major = String(format:"%x",version.getMajor())
            let middle = String(format:"%x",version.getMiddle())
            let minor = String(format:"%x",version.getMinor())
            let build = String(format:"%x",version.getBuild())
            print("receive ScanAPI version: \(major).\(middle).\(minor)")
            scanApiVersion.text = "ScanAPI: \(major).\(middle).\(minor).\(build)"
        }
    }
    
    // MARK: - ScanApiHelper Delegates
    /**
    * called each time a device connects to the host
    * @param result contains the result of the connection
    * @param newDevice contains the device information
    */
    func onDeviceArrival(_ result: SKTRESULT, device deviceInfo: DeviceInfo!) {
        print("Settings: Device Arrival")
    }
    
    /**
    * called each time a device disconnect from the host
    * @param deviceRemoved contains the device information
    */
    func onDeviceRemoval(_ deviceRemoved: DeviceInfo!) {
        print("Settings: Device Removal")
    }
    

}
