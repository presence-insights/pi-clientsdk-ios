//
//  CellSwitch.swift
//  PIOutdoorSample
//
//  Created by slizeray on 18/01/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class CellSwitch: UITableViewCell {

    @IBOutlet weak var leftLabel: UILabel!
    
    @IBOutlet weak var switchOn: UISwitch!
    
    /// Returns the default string used to identify instances of `CellSwitch`.
    class var identifier: String {
        get {
            return String(CellSwitch.self)
        }
    }
    
    /// Returns the `UINib` object initialized for the view.
    class var nib: UINib {
        get {
            return UINib(nibName: "CellSwitch", bundle: NSBundle(forClass: CellSwitch.self))
        }
    }
    
    func updateFonts() {
        Utils.updateBodyTextStyle(leftLabel)
        
    }
    
    
}
