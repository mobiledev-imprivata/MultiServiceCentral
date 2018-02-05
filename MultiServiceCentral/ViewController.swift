//
//  ViewController.swift
//  MultiServiceCentral
//
//  Created by Jay Tucker on 2/5/18.
//  Copyright © 2018 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let bluetoothManager = BluetoothManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func readService0(_ sender: Any) {
        bluetoothManager.readService(index: 0)
    }
    
    @IBAction func readService1(_ sender: Any) {
        bluetoothManager.readService(index: 1)
    }
    
}

