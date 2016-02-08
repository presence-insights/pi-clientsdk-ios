/**
 *  PIOutdoorSample
 *  MapController.swift
 *
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
import CoreLocation
import MBProgressHUD

class MapController: UIViewController,SegueHandlerType,NewGeofenceDelegate {

    let removeButtonTag = 10
    
    enum SegueIdentifier: String {
        case AddGeofence = "AddGeofenceSegID"
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geofenceCircles  = [String:MKCircle]()
    
    var first = true
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        self.mapView.showsScale = true
        self.mapView.mapType = .Hybrid
        self.mapView.delegate = self

        self.addFences()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "seedDidComplete:", name: kSeedDidComplete, object: nil)
        
        self.zoomToFitMapOverlays(self.mapView)
        self.first = false
        
        let buttonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
        
        self.navigationItem.leftBarButtonItem = buttonItem
        // Do any additional setup after loading the view, typically from a nib.
    }

    func addFences(){
        let geofences = piGeofencingManager.queryAllGeofences()
        for geofence in geofences  {
            let annotation = GeofenceAnnotation(geofence: geofence)
            self.mapView.addAnnotation(annotation)
            
            let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue), radius: CLLocationDistance(geofence.radius.integerValue))
            self.mapView.addOverlay(circle)
            self.geofenceCircles[geofence.code] = circle
            
        }
        
    }
    
    func zoomToFitMapOverlays(mapView:MKMapView) -> MKMapRect {
        
        let overlays = mapView.overlays
        
        // Walk the list of overlays and annotations and create a MKMapRect that
        // bounds all of them and store it into flyTo.
        var flyTo = MKMapRectNull
        for overlay in overlays {
            if overlay is MKTileOverlay {
                continue
            }
            
            let r = mapView.mapRectThatFits(overlay.boundingMapRect)
            if MKMapRectIsNull(flyTo) {
                flyTo = r
            } else {
                flyTo = MKMapRectUnion(flyTo, r)
            }
        }
        
        if MKMapRectEqualToRect(flyTo, MKMapRectNull) {
            return MKMapRectNull
        }
        
        mapView.setVisibleMapRect(flyTo, edgePadding:UIEdgeInsets(top: 50, left: 100, bottom: 50, right: 100),animated: true)
        
        return flyTo
    }
    
    func zoomToFitMapOverlay(mapView:MKMapView,overlay:MKOverlay) -> MKMapRect {
        
        let flyTo = mapView.mapRectThatFits(overlay.boundingMapRect)
        
        mapView.setVisibleMapRect(flyTo, edgePadding:UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),animated: true)
        
        return flyTo
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if first {
            self.zoomToFitMapOverlays(self.mapView)
            first = false
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segueIdentifierForSegue(segue) {
        case .AddGeofence:
            let nc = segue.destinationViewController as! UINavigationController
            let newGeofenceVC = nc.topViewController as! NewGeofenceController
            newGeofenceVC.visibleRegion = self.mapView.region
            newGeofenceVC.delegate = self
        }
    }
    
    // MARK: - NewGeofenceDelegate
    func newGeofence(newGeofence:NewGeofenceController,center:CLLocationCoordinate2D,name:String,radius:Int) {
        MBProgressHUD.showHUDAddedTo(self.view,animated:true)
        
        piGeofencingManager.addGeofence(name, center: center, radius: radius) { geofence in
            
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            
            guard let geofence = geofence else {
                let alertController = UIAlertController(
                    title: NSLocalizedString("Alert.GeofenceCreation.Error.Title",comment:""),
                    message: NSLocalizedString("Alert.GeofenceCreation.Error.Message",comment:""),
                    preferredStyle: .Alert)
                
                let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
                }
                alertController.addAction(okAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            
            let annotation = GeofenceAnnotation(geofence: geofence)
            
            self.mapView.addAnnotation(annotation)
            
            let circle = MKCircle(centerCoordinate: center, radius: CLLocationDistance(radius))
            self.mapView.addOverlay(circle)
            
            self.geofenceCircles[geofence.code] = circle
            
            self.zoomToFitMapOverlay(self.mapView, overlay: circle)
            self.mapView.selectAnnotation(annotation, animated: true)
            
        }
        
    }
    
    func seedDidComplete(notification:NSNotification) {
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        
        let overlays = self.mapView.overlays.filter {
            if let _ = $0 as? MKCircle {
                return true
            } else {
                return false
            }
        }
        
        self.mapView.removeOverlays(overlays)
        
        self.addFences()
    }
    
        
}

extension MapController:CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways:
            fallthrough
        case .AuthorizedWhenInUse:
            break
        case .Denied:
            fallthrough
        case .Restricted:
            fallthrough
        case .NotDetermined:
            self.mapView.userTrackingMode = .None
            self.mapView.showsUserLocation = false
            
        }
    }
}

extension MapController:MKMapViewDelegate {
    func mapViewWillStartLocatingUser(mapView: MKMapView) {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .AuthorizedAlways:
            fallthrough
        case .AuthorizedWhenInUse:
            break
        case .Restricted, .Denied:
            let alertController = UIAlertController(
                title: NSLocalizedString("Alert.Location.Title",comment:""),
                message: NSLocalizedString("Alert.Location.Message",comment:""),
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel",comment:""), style: .Cancel){ (action) in
                self.mapView.userTrackingMode = .None
                self.mapView.showsUserLocation = false
            }
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: NSLocalizedString("Alert.Location.OpenAction",comment:""), style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func mapViewDidStopLocatingUser(mapView: MKMapView) {
        
        self.mapView.showsUserLocation = false
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
    }
    
    func mapView(mapView: MKMapView,viewForAnnotation annotation: MKAnnotation)-> MKAnnotationView? {
        
        if let annotation = annotation as? MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation:annotation,reuseIdentifier:"GeofencePin")
            pinAnnotationView.pinTintColor = MKPinAnnotationView.purplePinColor()
            pinAnnotationView.annotation = annotation
            pinAnnotationView.draggable = false
            pinAnnotationView.selected = false
            pinAnnotationView.canShowCallout = true
            let removeButton = UIButton(type: .System)
            removeButton.setImage(UIImage(named: "trash"), forState: .Normal)
            removeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            removeButton.sizeToFit()
            removeButton.tag = removeButtonTag
            
            pinAnnotationView.leftCalloutAccessoryView = removeButton
            
            return pinAnnotationView
        } else {
            return nil
        }
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circle = MKCircleRenderer(circle: overlay)
            circle.fillColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
            circle.strokeColor = UIColor.redColor()
            circle.lineWidth = 1
            return circle
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,calloutAccessoryControlTapped control: UIControl) {
        
        if let geofenceAnnotation = view.annotation as? GeofenceAnnotation where control.tag == removeButtonTag {
            
            let geofenceCode = geofenceAnnotation.geofenceCode
            self.mapView.removeAnnotation(geofenceAnnotation)
            let circle = geofenceCircles[geofenceCode] as! MKOverlay
            self.mapView.removeOverlay(circle)
            
            MBProgressHUD.showHUDAddedTo(self.view,animated:true)
            
            piGeofencingManager.removeGeofence(geofenceCode) {
                success in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                if success == false {
                    let alertController = UIAlertController(
                        title: NSLocalizedString("Alert.GeofenceDeletion.Error.Title",comment:""),
                        message: NSLocalizedString("Alert.GeofenceDeletion.Error.Message",comment:""),
                        preferredStyle: .Alert)
                    
                    let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
                    }
                    alertController.addAction(okAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                
                }
            }
        }
        
    }
    
    
}



