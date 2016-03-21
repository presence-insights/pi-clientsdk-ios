/**
*  IBMPIGeofenceSample
*  ViewController.swift
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
import IBMPIGeofence

class ViewController: UIViewController {

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

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(ViewController.seedDidComplete(_:)),
			name: kGeofenceManagerDidSynchronize,
			object: nil)

		self.zoomToFitMapOverlays(self.mapView)
		self.first = false

		let buttonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)

		self.navigationItem.leftBarButtonItem = buttonItem
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

	func addFences(){
		guard let geofences = piGeofencingManager?.queryAllGeofences() else {
			return
		}

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



}

extension ViewController:CLLocationManagerDelegate {
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

extension ViewController:MKMapViewDelegate {
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

	private func showError(title:String,message:String) {

		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.showAlert(title, message: message)
	}

}





