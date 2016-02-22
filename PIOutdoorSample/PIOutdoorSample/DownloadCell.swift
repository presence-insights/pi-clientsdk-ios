/**
*  PIOutdoorSDK
*  DownloadCell.swift
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
import PIOutdoorSDK

class DownloadCell: UITableViewCell {

	private static let dateFormatter:NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .FullStyle
		dateFormatter.timeStyle = .NoStyle
		return dateFormatter
	}()

	private static let timeFormatter:NSDateFormatter = {
		let timeFormatter = NSDateFormatter()
		timeFormatter.dateStyle = .NoStyle
		timeFormatter.timeStyle = .MediumStyle
		return timeFormatter
	}()



	@IBOutlet weak var startDate: UILabel!

	@IBOutlet weak var startTime: UILabel!

	@IBOutlet weak var endDate: UILabel!

	@IBOutlet weak var endTime: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


	func configure(download:PIDownload) {
		self.updateFonts()

		self.startDate.text = self.dynamicType.dateFormatter.stringFromDate(download.startDate)
		self.startTime.text = self.dynamicType.timeFormatter.stringFromDate(download.startDate)

		if let endDate = download.endDate {
			self.endDate.text = self.dynamicType.dateFormatter.stringFromDate(endDate)
			self.endTime.text = self.dynamicType.timeFormatter.stringFromDate(endDate)
		} else {
			self.endDate.text = nil
			self.endTime.text = nil
		}

		switch download.progressStatus {
		case .NetworkError:
			self.endDate.tintColor = UIColor.redColor()
			self.endTime.tintColor = UIColor.redColor()

		default:
			self.endDate.tintColor = nil
			self.endTime.tintColor = nil

		}
	}
	
	private func updateFonts() {

		Utils.updateTextStyle(self.startDate)
		Utils.updateTextStyle(self.startTime)
		Utils.updateTextStyle(self.endDate)
		Utils.updateTextStyle(self.endTime)

	}

	/// Returns the default string used to identify instances of `DownloadCell`.
	static var identifier: String {
		get {
			return String(DownloadCell.self)
		}
	}

	/// Returns the `UINib` object initialized for the view.
	static var nib: UINib {
		get {
			return UINib(nibName: StringFromClass(DownloadCell), bundle: NSBundle(forClass: DownloadCell.self))
		}
	}


}
