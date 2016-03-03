/**
 *  PIOutdoorSample
 *  GeofenceRadiusPickerCell.swift
 *
 *  Performs all communication to the PI Rest API.
 *
 *  © Copyright 2016 IBM Corp.
 *
 *  Licensed under the Presence Insights Client iOS Framework License (the "License");
 *  you may not use this file except in compliance with the License. You may find
 *  a copy of the license in the license.txt file in this package.
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 **/


import UIKit

protocol GeofenceRadiusPickerCellDelegate:class {
    func radiusPicker(radiusPicker:GeofenceRadiusPickerCell,radius:Int)
}


let allRadius = [
    100,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    600,
    700,
    800,
    900,
    1000,
    1250,
    1500,
    1750,
    2000,
    2500,
    3000,
    3500,
    4000,
    4500,
    5000,
    10000
]
class GeofenceRadiusPickerCell: UITableViewCell,UIPickerViewDataSource,UIPickerViewDelegate {

    weak var delegate:GeofenceRadiusPickerCellDelegate?
    
    private static let lengthFormatter:NSLengthFormatter = {
        let lengthFormatter = NSLengthFormatter()
        return lengthFormatter
        }()
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allRadius.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        let radius = allRadius[row]
        return self.dynamicType.lengthFormatter.stringFromValue(Double(radius), unit: .Meter)
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let radius = allRadius[row]
        self.delegate?.radiusPicker(self, radius: radius)
    }

    /// Returns the default string used to identify instances of `GeofenceRadiusPickerCell`.
    static var identifier: String {
        get {
            return String(GeofenceRadiusPickerCell.self)
        }
    }
    
    /// Returns the `UINib` object initialized for the view.
    static var nib: UINib {
        get {
            return UINib(nibName: StringFromClass(GeofenceRadiusPickerCell), bundle: NSBundle(forClass: GeofenceRadiusPickerCell.self))
        }
    }
    
}
