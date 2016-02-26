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
import MessageUI
import CocoaLumberjack
import PIOutdoorSDK
import MBProgressHUD
import SSKeychain

public let kDidResetOrganization = "com.ibm.PI.DidResetOrganization"

enum MoreSections: Int {
    case Settings
	case PIOutdoorSample
	case Reset
}

enum MoreSettings: Int {
    case Privacy
	case TenantCode
	case OrgCode
}

enum MorePIOutdoorSample: Int {
	case ContactUs
}

enum MoreReset: Int {
	case Reset
}


class MoreController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.tableView.registerNib(CellSwitch.nib, forCellReuseIdentifier:CellSwitch.identifier)

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(MoreController.contentsSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
        
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(MoreController.protectedDataDidBecomeAvailable(_:)),
			name: kProtectedDataDidBecomeAvailable,
			object: nil)

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(MoreController.orgCodeDidChange(_:)),
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
		case .PIOutdoorSample:
			return maximum(MorePIOutdoorSample)
		case .Reset:
			return maximum(MoreReset)

        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionEnum = MoreSections(rawValue: section)!
        switch (sectionEnum){
        case .Settings:
            return NSLocalizedString("More.Section.Settings",comment:"")
		case .PIOutdoorSample:
			return NSLocalizedString("More.Section.PIOutdoorSample",comment:"")
		case .Reset:
			return ""

        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        let s = MoreSections(rawValue: section)
        
        if case .Reset? = s {

            let footer = "Copyright ⓒ 2016 IBM \(Utils.version)"
            
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
                cell.switchOn?.addTarget(self, action: #selector(MoreController.onPrivacySwitchChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                return cell
			case .TenantCode:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.textLabel?.text = NSLocalizedString("More.Settings.TenantCode",comment:"")

				cell.detailTextLabel?.text = piGeofencingManager?.service.tenantCode

				return cell
			case .OrgCode:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.textLabel?.text = NSLocalizedString("More.Settings.OrgCode",comment:"")

				cell.detailTextLabel?.text = piGeofencingManager?.service.orgCode
				
				return cell
            }
		case .PIOutdoorSample:
			let row = MorePIOutdoorSample(rawValue: indexPath.row)
			switch row! {
			case .ContactUs:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.selectionStyle = .Default
				cell.textLabel?.text = NSLocalizedString("More.PIOutdoorSample.ContactUs",comment:"")

				return cell
			}
		case .Reset:
			let row = MoreReset(rawValue: indexPath.row)
			switch row! {
			case .Reset:
				let cell = self.dequeueBasicCellForIndexPath(indexPath)
				cell.textLabel?.text = NSLocalizedString("More.Reset.Reset",comment:"")
				cell.textLabel?.textColor = Utils.systemRedColor
				cell.selectionStyle = .Default
				return cell
			}

        }
        
    }

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let section = MoreSections(rawValue: indexPath.section)!
		switch (section) {
		case .Settings:
			break
		case .PIOutdoorSample:
			let row = MorePIOutdoorSample(rawValue: indexPath.row)!
			switch row {
			case .ContactUs:
				sendLogFiles()
			}
		case .Reset:
			let row = MoreReset(rawValue: indexPath.row)!
			switch row {
			case .Reset:
				self.confirmReset()
			}

		}
	}

	private func dequeueBasicCellForIndexPath(indexPath:NSIndexPath) -> UITableViewCell
	{

		let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCellID", forIndexPath:indexPath) as UITableViewCell

		cell.imageView?.image = nil
		cell.detailTextLabel?.text = nil
		cell.textLabel?.textColor = nil
		cell.selectionStyle = .None
		Utils.updateBodyTextStyle(cell.textLabel!)
		Utils.updateBodyTextStyle(cell.detailTextLabel!)
		return cell
	}

	private func sendLogFiles() {
		if let ip = self.tableView.indexPathForSelectedRow {
			self.tableView.deselectRowAtIndexPath(ip, animated: true)
		}

		if !MFMailComposeViewController.canSendMail() {
			let message = NSLocalizedString("NoMail.Message.ContactUs", comment: "")
			let alertController = UIAlertController(title: NSLocalizedString("NoMail.Message.Title", comment: ""), message: message, preferredStyle: .Alert)
			alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action) -> Void in
			}))
			self.presentViewController(alertController, animated: true, completion: nil)
		} else {
			let picker = MFMailComposeViewController()
			picker.mailComposeDelegate = self

			let subject = "PIOutdoorSample \(Utils.version)"
			picker.setSubject(subject)

			// Set up recipients
			picker.setToRecipients(["lizeray@fr.ibm.com"])

			let mailFooter = Utils.mailFooter()

			let emailBody = mailFooter
			// Fill out the email body text
			picker.setMessageBody(emailBody,isHTML:false)

			collectLogFiles(picker)

			self.presentViewController(picker, animated: true, completion: nil)

		}

	}

	private func collectLogFiles(picker:MFMailComposeViewController) {

		for p in PIGeofencingManager.logFiles() {
			let url = NSURL(fileURLWithPath: p)
			if let
			data = NSData(contentsOfURL: url),
			filename = url.lastPathComponent {
				picker.addAttachmentData(data, mimeType: "text/plain", fileName: filename)
			}
		}

	}


	private func confirmReset() {
		if let ip = self.tableView.indexPathForSelectedRow {
			self.tableView.deselectRowAtIndexPath(ip, animated: true)
		}

		let message = NSLocalizedString("Alert.Reset.Message", comment: "")
		let alert = UIAlertController(title: NSLocalizedString("Alert.Reset.Title",comment:""), message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel",comment:"Cancel"), style: .Cancel, handler: { (alertAction) -> Void in

			}))
		alert.addAction(UIAlertAction(title: NSLocalizedString("Alert.Reset.Reset",comment:""), style: .Destructive, handler: { [unowned self] (alertAction) -> Void in

			self.doReset()

			}))

		self.presentViewController(alert, animated: true, completion: nil)


	}

	private func doReset() {
		guard piGeofencingManager != nil else {
			return
		}
		
		MBProgressHUD.showHUDAddedTo(self.tabBarController?.view,animated:true)
		piGeofencingManager?.reset {
			NSNotificationCenter.defaultCenter().postNotificationName(kDidResetOrganization, object: nil)
			if


				let tenantCode = NSUserDefaults.standardUserDefaults().objectForKey("PITenant") as? String,
				let hostname = NSUserDefaults.standardUserDefaults().objectForKey("PIHostName") as? String {

				piGeofencingManager?.service.orgCode = nil

				Utils.createPIOrg(hostname, tenantCode: tenantCode,vc:self.tabBarController!) { orgCode in


					let data = SSKeychain.passwordDataForService(
						kPIService,
						account: kPIGeofenceAccount)

					if let data = data {
						do {
							var json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]

							json?["orgCode"] = orgCode
							if
								let json = json,
								let data = try? NSJSONSerialization.dataWithJSONObject(json, options: [])  {
								SSKeychain.setPasswordData(data, forService: kPIService, account: kPIGeofenceAccount)
								piGeofencingManager?.service.orgCode = orgCode
								piGeofencingManager?.synchronize()
							}
						} catch {
							DDLogError("Can't read JSON in the KeyChain \(error)",asynchronous:false)
						}
					}


					self.tableView.reloadData()
					MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
					piGeofencingManager?.startMonitoringRegions()
				}
			} else {
				self.tableView.reloadData()
				MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
			}
		}
	}

    func onPrivacySwitchChanged(sender: UISwitch) {
        Settings.privacy = sender.on
    }

    func contentsSizeChanged(notification:NSNotification){
        self.tableView.reloadData()
    }

	func protectedDataDidBecomeAvailable(notification:NSNotification){
		self.tableView.reloadData()
	}

	func orgCodeDidChange(notification:NSNotification){
		self.tableView.reloadData()
	}

}

extension MoreController:MFMailComposeViewControllerDelegate {

	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {

		self.dismissViewControllerAnimated(true) { (finished) -> Void in
			switch (result) {
			case MFMailComposeResultCancelled:
				break
			case MFMailComposeResultSaved:
				break
			case MFMailComposeResultSent:
				self.dismissViewControllerAnimated(true,completion:nil)
			case MFMailComposeResultFailed:
				break
			default:
				break
			}
		}
	}
}



