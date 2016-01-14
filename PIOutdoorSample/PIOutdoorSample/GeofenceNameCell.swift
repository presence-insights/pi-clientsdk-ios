/**
 *  PIOutdoorSample
 *  GeofenceNameCell.swift
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



class GeofenceNameCell: UITableViewCell,UITextFieldDelegate {

    @IBOutlet weak var geofenceName: UITextField!
    
    var externalEditing = false {
        didSet {
            geofenceName.enabled = !externalEditing
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
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return !externalEditing
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        geofenceName.font = font
    }
    
    
    /// Returns the default string used to identify instances of `GeofenceNameCell`.
    static var identifier: String {
        get {
            return String(GeofenceNameCell.self)
        }
    }
    
    /// Returns the `UINib` object initialized for the view.
    static var nib: UINib {
        get {
            return UINib(nibName: StringFromClass(GeofenceNameCell), bundle: NSBundle(forClass: GeofenceNameCell.self))
        }
    }
    
}
