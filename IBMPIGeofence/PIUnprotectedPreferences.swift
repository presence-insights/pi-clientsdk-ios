/**
*  IBMPIGeofence
*  PIUnprotectedPreferences.swift
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

import Foundation

class PIUnprotectedPreferences {

	let name:String

	private var dict:NSMutableDictionary

	static let sharedInstance = PIUnprotectedPreferences(name: "IBMPIUnprotectedPreferences")

	private static var applicationLibraryDirectory:NSURL {

		return NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).first! as NSURL
	}

	init(name:String) {
		self.name = name
		let url = self.dynamicType.applicationLibraryDirectory.URLByAppendingPathComponent("\(name).plist")
		if let dict = NSMutableDictionary(contentsOfURL: url)  {
			self.dict = dict
		} else {
			dict = NSMutableDictionary()
		}
	}

	func synchronize() {
		let url = self.dynamicType.applicationLibraryDirectory.URLByAppendingPathComponent("\(name).plist")
		self.dict.writeToURL(url, atomically: true)
		do {
			try NSFileManager.defaultManager().setAttributes([NSFileProtectionKey:NSFileProtectionNone], ofItemAtPath: url.path!)
		} catch  {
			print(error)
		}
	}

	func objectForKey(defaultName: String) -> AnyObject? {
		return self.dict[defaultName]
	}

	func setObject(value: AnyObject?, forKey defaultName: String) {
		if let value = value {
			self.dict[defaultName] = value
		} else {
			self.dict.removeObjectForKey(defaultName)
		}
	}

	func removeObjectForKey(defaultName: String) {
		self.dict.removeObjectForKey(defaultName)
	}

	func stringForKey(defaultName: String) -> String? {
		return self.dict[defaultName] as? String

	}

	func integerForKey(defaultName: String) -> Int {
		return self.dict[defaultName] as! Int

	}

	func floatForKey(defaultName: String) -> Float {
		return self.dict[defaultName] as! Float

	}

	func doubleForKey(defaultName: String) -> Double {
		return self.dict[defaultName] as! Double
	}

	func boolForKey(defaultName: String) -> Bool {
		return self.dict[defaultName] as! Bool

	}

	func setInteger(value: Int, forKey defaultName: String) {
		self.dict[defaultName] = NSNumber(integer: value)
	}

	func setFloat(value: Float, forKey defaultName: String) {
		self.dict[defaultName] = NSNumber(float: value)
	}

	func setDouble(value: Double, forKey defaultName: String) {
		self.dict[defaultName] = NSNumber(double: value)

	}

	func setBool(value: Bool, forKey defaultName: String) {
		self.dict[defaultName] = NSNumber(bool: value)
	}
}