/**
 *  PIOutdoorSample
 *  GeofenceRadiusCell.swift
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

class GeofenceRadiusCell: UITableViewCell {

    private static let lengthFormatter:NSLengthFormatter = {
        let lengthFormatter = NSLengthFormatter()
        return lengthFormatter
        }()
    
    @IBOutlet weak var radiusLabel: UILabel!
    
    @IBOutlet weak var radiusValueLabel: UILabel!
    
    var editingRadius = false {
        willSet {
            if newValue {
                self.radiusValueLabel.textColor = UIColor.redColor()
            } else {
                self.radiusValueLabel.textColor = UIColor.blackColor()
            }
        }
    }
    
    var radius = 100 {
        didSet {
            self.radiusValueLabel.text = self.dynamicType.lengthFormatter.stringFromValue(Double(radius), unit: .Meter)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        radiusValueLabel.font = font
        radiusLabel.font = font
    }
    
    /// Returns the default string used to identify instances of `GeofenceRadiusCell`.
    static var identifier: String {
        get {
            return String(GeofenceRadiusCell.self)
        }
    }
    
    /// Returns the `UINib` object initialized for the view.
    static var nib: UINib {
        get {
            return UINib(nibName: StringFromClass(GeofenceRadiusCell), bundle: NSBundle(forClass: GeofenceRadiusCell.self))
        }
    }
    

}
