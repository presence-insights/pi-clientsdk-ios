/**
 *  PIOutdoorSample
 *  NewGeofenceController.swift
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

protocol NewGeofenceDelegate:class {
    func newGeofence(newGeofence:NewGeofenceController,center:CLLocationCoordinate2D,name:String,radius:Int)
}

class NewGeofenceController: UITableViewController,GeofenceRadiusPickerCellDelegate,MapCellDelegate {

    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var visibleRegion:MKCoordinateRegion! {
        didSet {
            self.fenceCenter = visibleRegion.center
        }
    }
    
    var fenceCenter:CLLocationCoordinate2D!
    var fenceRadius = 100
    var fenceName:String!
    
    weak var delegate:NewGeofenceDelegate?
    
    enum Sections: Int {
        case MapSection
        case FenceAttributesSection
    }
    
    enum MapSection: Int {
        case Map
    }
    
    enum FenceAttributesSection: Int {
        case GeofenceName
        case GeofenceRadius
        case GeofenceRadiusPicker
    }
    
    var editingRadius = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addButton.enabled = false
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.tableView.registerNib(UINib(nibName: "MapCell", bundle: nil), forCellReuseIdentifier: "MapCellID")
        self.tableView.registerNib(UINib(nibName: "GeofenceNameCell", bundle: nil), forCellReuseIdentifier: "GeofenceNameCellID")
        self.tableView.registerNib(UINib(nibName: "GeofenceRadiusCell", bundle: nil), forCellReuseIdentifier: "GeofenceRadiusCellID")
        self.tableView.registerNib(UINib(nibName: "GeofenceRadiusPickerCell", bundle: nil), forCellReuseIdentifier: "GeofenceRadiusPickerCellID")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentsSizeChanged:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange:", name: UITextFieldTextDidChangeNotification, object: nil)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return maximum(Sections)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionEnum = Sections(rawValue: section)
        switch (sectionEnum!){
        case .MapSection:
            return maximum(MapSection)
        case .FenceAttributesSection:
            let max = maximum(FenceAttributesSection)
            return editingRadius ? max : max - 1
            
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = Sections(rawValue: indexPath.section)
        switch (section!) {
        case .MapSection:
            let mapRows = MapSection(rawValue: indexPath.row)
            switch (mapRows!){
            case .Map:
                let cell = tableView.dequeueReusableCellWithIdentifier("MapCellID", forIndexPath: indexPath) as!  MapCell
                cell.externalEditing = editingRadius
                cell.region = self.visibleRegion
                cell.delegate = self
                return cell
            }
        case .FenceAttributesSection:
            let fenceRows = FenceAttributesSection(rawValue: indexPath.row)
            switch (fenceRows!){
            case .GeofenceName:
                let cell = tableView.dequeueReusableCellWithIdentifier("GeofenceNameCellID", forIndexPath: indexPath) as!  GeofenceNameCell
                cell.externalEditing = editingRadius
                return cell
            case .GeofenceRadius:
                let cell = tableView.dequeueReusableCellWithIdentifier("GeofenceRadiusCellID", forIndexPath: indexPath) as!  GeofenceRadiusCell
                cell.editingRadius = editingRadius
                cell.radius = fenceRadius
                return cell
            case .GeofenceRadiusPicker:
            let cell = tableView.dequeueReusableCellWithIdentifier("GeofenceRadiusPickerCellID", forIndexPath: indexPath) as!  GeofenceRadiusPickerCell
            cell.delegate = self
            return cell
            }
            
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        self.tableView.endEditing(true)
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = Sections(rawValue: indexPath.section)!
        switch (section) {
        case .MapSection:
            let mapRows = MapSection(rawValue: indexPath.row)
            switch (mapRows!){
            case .Map: break
            }
        case .FenceAttributesSection:
            let fenceRows = FenceAttributesSection(rawValue: indexPath.row)!
            switch (fenceRows){
            case .GeofenceName:
                break
            case .GeofenceRadius:
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.switchGeofenceRadiusEditing()
                return
            case .GeofenceRadiusPicker:
                break
            }
        }
        
        if editingRadius {
            switchGeofenceRadiusEditing()
        }
        
    }
    
    func switchGeofenceRadiusEditing() {
        let oldEditingRadius = editingRadius
        editingRadius = !editingRadius
        self.tableView.beginUpdates()
        if oldEditingRadius {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: FenceAttributesSection.GeofenceRadius.rawValue + 1, inSection: Sections.FenceAttributesSection.rawValue)], withRowAnimation: .Fade)
            
        } else {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: FenceAttributesSection.GeofenceRadius.rawValue + 1, inSection: Sections.FenceAttributesSection.rawValue)], withRowAnimation: .Fade)
        }
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: FenceAttributesSection.GeofenceRadius.rawValue, inSection: Sections.FenceAttributesSection.rawValue)], withRowAnimation: .Fade)
        self.tableView.endUpdates()
        let geofenceNameCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: FenceAttributesSection.GeofenceName.rawValue, inSection: Sections.FenceAttributesSection.rawValue)) as? GeofenceNameCell
        if let geofenceNameCell = geofenceNameCell {
            geofenceNameCell.externalEditing = editingRadius
        }
        let mapCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: MapSection.Map.rawValue, inSection: Sections.MapSection.rawValue)) as? MapCell
        if let mapCell = mapCell {
            mapCell.externalEditing = editingRadius
        }
        
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Actions
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func add(sender: AnyObject) {
        self.delegate?.newGeofence(self, center: fenceCenter, name: fenceName, radius: fenceRadius)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - GeofenceRadiusPickerCellDelegate
    
    func radiusPicker(radiusPicker:GeofenceRadiusPickerCell,radius:Int) {
        self.fenceRadius = radius
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: FenceAttributesSection.GeofenceRadius.rawValue, inSection: Sections.FenceAttributesSection.rawValue)], withRowAnimation: .Fade)
    }
    
    // MARK: - MapCellDelegate
    
    func mapCell(mapCell:MapCell,center:CLLocationCoordinate2D) {
        self.fenceCenter = center
    }

    // MARK: - Notifications
    
    func contentsSizeChanged(notification:NSNotification){
        self.tableView.reloadData()
    }

    func textDidChange(notification:NSNotification){
        if let textField = notification.object as? UITextField{
            if textField.text?.isEmpty == true {
                self.addButton.enabled = false
            } else {
                self.fenceName = textField.text
                self.addButton.enabled = true
            }
        }
    }
    
}
