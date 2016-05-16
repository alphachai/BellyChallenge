/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

// https://tech.bellycard.com/challenges/iPhone-List-View.psd

import Foundation
import UIKit

let businesses = BusinessRepository.sharedInstance

struct Constants {
    
    static let product = "BellyChallenge"
    static let version = "0.1"
    static let systemVersion = UIDevice.currentDevice().systemVersion
    static let model = UIDevice.currentDevice().model
    static let name = UIDevice.currentDevice().name
    static let uniqueID = NSUUID().UUIDString
}