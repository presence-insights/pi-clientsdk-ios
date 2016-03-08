//
//  DownloadRequest.swift
//  PIOutdoorSDK
//
//  Created by slizeray on 11/02/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

/**
Protocol that should be adopted by all PI request
*/

public protocol PIDownloadRequest {


	/**
	- parameter service: the PI instance
	- returns: a Response instance
	*/

	func executeDownload(service:PIService) -> PIDownloadResponse?


}