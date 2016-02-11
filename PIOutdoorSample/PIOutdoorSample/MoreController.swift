/**
 *  PIOutdoorSample
 *  MoreController.swift
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

enum MoreSections: Int {
    case Settings
}

enum MoreSettings: Int {
    case Privacy
	case TenantCode
	case OrgCode
}



class MoreController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.tableView.registerNib(CellSwitch.nib, forCellReuseIdentifier:CellSwitch.identifier)

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "contentsSizeChanged:",
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
        
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: "orgCodeDidChange:",
			name: kOrgCodeDidChange,
			object: nil)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return maximum(MoreSections)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionEnum = MoreSections(rawValue: section)!
        switch (sectionEnum){
        case .Settings:
            return maximum(MoreSettings)
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionEnum = MoreSections(rawValue: section)!
        switch (sectionEnum){
        case .Settings:
            return NSLocalizedString("More.Section.Settings",comment:"")
            
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        let s = MoreSections(rawValue: section)
        
        if case .Settings? = s {
            let infoDictionary = NSBundle.mainBundle().infoDictionary!
            
            let appBuildNumber = infoDictionary["CFBundleVersion"] as! String
            let appVersionName = infoDictionary["CFBundleShortVersionString"] as! String
            
            let footer = "Copyright ⓒ 2016 IBM \(appVersionName) (\(appBuildNumber))"
            
            return footer
        } else {
            return nil
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let section = MoreSections(rawValue: indexPath.section)
        switch (section!) {
        case .Settings:
            let row = MoreSettings(rawValue: indexPath.row)
            switch row! {
            case .Privacy:
                let cell = tableView.dequeueReusableCellWithIdentifier(CellSwitch.identifier, forIndexPath: indexPath) as! CellSwitch
                cell.updateFonts()
                cell.leftLabel?.text = NSLocalizedString("More.Settings.Privacy",comment:"")
                cell.switchOn.on = Settings.privacy
                cell.switchOn?.addTarget(self, action: "onChanged:", forControlEvents: UIControlEvents.ValueChanged)
                return cell
			case .TenantCode:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.textLabel?.text = NSLocalizedString("More.Settings.TenantCode",comment:"")

				cell.detailTextLabel?.text = piGeofencingManager.service.tenantCode

				return cell
			case .OrgCode:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.textLabel?.text = NSLocalizedString("More.Settings.OrgCode",comment:"")

				cell.detailTextLabel?.text = piGeofencingManager.service.orgCode
				
				return cell
            }
            
            
        }
        
    }
    
	private func dequeueBasicCellForIndexPath(indexPath:NSIndexPath) -> UITableViewCell
	{

		let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCellID", forIndexPath:indexPath) as UITableViewCell

		cell.imageView?.image = nil
		cell.detailTextLabel?.text = nil
		cell.textLabel?.textColor = nil
		Utils.updateBodyTextStyle(cell.textLabel!)
		Utils.updateBodyTextStyle(cell.detailTextLabel!)
		return cell
	}

    func onChanged(sender: UISwitch) {
        Settings.privacy = sender.on
    }
    
    func contentsSizeChanged(notification:NSNotification){
        self.tableView.reloadData()
    }
    
	func orgCodeDidChange(notification:NSNotification){
		self.tableView.reloadData()
	}

}
