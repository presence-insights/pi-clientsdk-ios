/**
 *  PIOutdoorSample
 *  MapCell.swift
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
import MapKit


protocol MapCellDelegate:class {
    func mapCell(mapCell:MapCell,center:CLLocationCoordinate2D)
}


class MapCell: UITableViewCell,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    weak var delegate:MapCellDelegate?
    
    var pinAnnotationView:MKPinAnnotationView?
    var widthConstraint:NSLayoutConstraint?
    var heightConstraint:NSLayoutConstraint?
    var xConstraint:NSLayoutConstraint?
    var yConstraint:NSLayoutConstraint?
    
    var region:MKCoordinateRegion! {
        didSet {
            mapView.region = region
            mapView.mapType = .Hybrid
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapView.centerCoordinate
            
            self.pinAnnotationView?.removeFromSuperview()
            widthConstraint?.active = false
            heightConstraint?.active = false
            xConstraint?.active = false
            yConstraint?.active = false
            
            
            let pinAnnotationView = MKPinAnnotationView(annotation:annotation,reuseIdentifier:"GeofencePin")
            pinAnnotationView.translatesAutoresizingMaskIntoConstraints = false
            pinAnnotationView.userInteractionEnabled = false
            pinAnnotationView.pinTintColor = MKPinAnnotationView.purplePinColor()
            
            let size = pinAnnotationView.image?.size
            
            self.contentView.addSubview(pinAnnotationView)
            
            let centerOffset = pinAnnotationView.centerOffset
            
            xConstraint = NSLayoutConstraint(item:pinAnnotationView, attribute:.CenterX, relatedBy:.Equal, toItem:self.mapView,
                attribute:.CenterX, multiplier:1, constant:centerOffset.x)
            yConstraint = NSLayoutConstraint(item:pinAnnotationView, attribute:.CenterY, relatedBy:.Equal, toItem:self.mapView,
                    attribute:.CenterY, multiplier:1, constant:centerOffset.y)
            
            widthConstraint = NSLayoutConstraint(item:pinAnnotationView, attribute:.Width, relatedBy:.Equal, toItem:nil,attribute:.NotAnAttribute, multiplier:1, constant:size!.width)
            heightConstraint = NSLayoutConstraint(item:pinAnnotationView, attribute:.Height, relatedBy:.Equal, toItem:nil,attribute:.NotAnAttribute, multiplier:1, constant:size!.height)
            
            xConstraint?.active = true
            yConstraint?.active = true
            widthConstraint?.active = true
            heightConstraint?.active = true
            
            self.pinAnnotationView = pinAnnotationView
            
        }
    }
    
    var externalEditing = false {
        didSet {
            mapView.userInteractionEnabled = !externalEditing
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        self.delegate?.mapCell(self, center: center)
    }

    /// Returns the default string used to identify instances of `MapCell`.
    static var identifier: String {
        get {
            return String(MapCell.self)
        }
    }
    
    /// Returns the `UINib` object initialized for the view.
    static var nib: UINib {
        get {
            return UINib(nibName: StringFromClass(MapCell), bundle: NSBundle(forClass: MapCell.self))
        }
    }
    
}
