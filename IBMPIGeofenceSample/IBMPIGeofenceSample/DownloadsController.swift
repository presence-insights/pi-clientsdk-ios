/**
*  PIOutdoorSDK
*  DownloadsController.swift
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
import CoreData
import IBMPIGeofence
import MBProgressHUD

class DownloadsController: UITableViewController {

	private var _fetchedResultsController:NSFetchedResultsController?

	var sectionChanged = false

	var fetchedResultsController:NSFetchedResultsController {

		if _fetchedResultsController == nil {
			let fetchRequest = PIDownload.fetchRequest
			let timeSortDescriptor = NSSortDescriptor(key:"startDate",ascending:false)
			fetchRequest.sortDescriptors = [timeSortDescriptor]

			fetchRequest.fetchBatchSize = 25
			fetchRequest.returnsObjectsAsFaults = false

			let dataController = PIGeofenceData.dataController
			_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.mainContext, sectionNameKeyPath: nil, cacheName: nil)
			_fetchedResultsController?.delegate = self
			do {
				try _fetchedResultsController?.performFetch()
			} catch {
				assertionFailure("perform fetch error \(error)")
			}
		}

		return _fetchedResultsController!
	}


    override func viewDidLoad() {
        super.viewDidLoad()

		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight = 44

		self.tableView.tableFooterView = UIView(frame: CGRectZero)
		
		self.tableView.registerNib(DownloadCell.nib, forCellReuseIdentifier:DownloadCell.identifier)

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(DownloadsController.contentsSizeChanged(_:)),
			name: UIContentSizeCategoryDidChangeNotification,
			object: nil)



    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections!.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// Return the number of rows in the section.
		let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo

		return sectionInfo.numberOfObjects
    }

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(DownloadCell.identifier, forIndexPath: indexPath) as! DownloadCell

		let download = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PIDownload
		cell.configure(download)

		return cell
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
        // Return false if you do not want the item to be re-orderable.
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

}

extension DownloadsController: NSFetchedResultsControllerDelegate {

	// MARK: - NSFetchedResultsControllerDelegate
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
		sectionChanged = false
	}

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {


		switch type {
		case .Insert:
			self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation:.Automatic)
		case .Delete:
			self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
		case .Update:
			self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
		case .Move:
			if indexPath == newIndexPath && sectionChanged == false {
				self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
				break
			}
			self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
			self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
		}
	}

	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

		sectionChanged = true

		switch(type){
		case .Insert:
			self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
		case .Delete:
			self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
		default:
			assertionFailure("change section in Table View failure")
		}

	}

	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.endUpdates()
	}

}


extension DownloadsController {

	func contentsSizeChanged(notification:NSNotification){
		self.tableView.reloadData()
	}

}

extension DownloadsController {
	
	@IBAction func refresh(sender: AnyObject) {
		guard piGeofencingManager != nil else {
			return
		}

		MBProgressHUD.showHUDAddedTo(self.tabBarController?.view,animated:true)
		piGeofencingManager?.synchronize { success in
			MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
			if success == false {
				let title = NSLocalizedString("Alert.Refresh.Error.Title",comment:"")
				let message = NSLocalizedString("Alert.Refresh.Error.Message",comment:"")
				self.showError(title, message: message)

			}
		}
	}
	private func showError(title:String,message:String) {

		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.showAlert(title, message: message)
	}
	
}
