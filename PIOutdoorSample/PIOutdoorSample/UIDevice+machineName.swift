//
//  UIDevice+machineName.swift
//  PIOutdoorSample
//
//  Created by slizeray on 12/02/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

extension UIDevice {

	public var machineName: String {
		var systemInfo = utsname()
		uname(&systemInfo)

		let machine = systemInfo.machine
		let children = Mirror(reflecting:machine).children
		var identifier = ""

		for child in children {
			if let value = child.value as? Int8 where value != 0 {
				identifier.append(UnicodeScalar(UInt8(value)))
			}
		}
		return identifier
	}
}