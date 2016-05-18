/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

// https://tech.bellycard.com/challenges/iPhone-List-View.psd

import Foundation
import UIKit

let venues = BusinessRepository.sharedInstance

struct Constants {
    
    static let product = "BellyChallenge"
    static let version = "0.1"
    static let systemVersion = UIDevice.currentDevice().systemVersion
    static let model = UIDevice.currentDevice().model
    static let name = UIDevice.currentDevice().name
    static let uniqueID = NSUUID().UUIDString
    
    struct Colors {
        static let statusBar = UIColor(red: 51.0/255.0, green: 169.0/255.0, blue: 224.0/255.0, alpha: 1.0)
    }
    
    struct Yelp {
        static let ckey = "emFz4WJ9z4HInUjRzDRWDQ"
        static let csecret = "mWEDzD0LoR_fvK-ol58cDAuxNWo"
        static let token = "zU0XR_7XH6F3nxwTR1eEI2tSeIorceCa"
        static let tokensecret = "eiRnvipfcQCFLvUwk6e20QvnBhM"
        
        struct API {
            static let search = "https://api.yelp.com/v2/search"
        }
    }
    
    static let KVO_Options = NSKeyValueObservingOptions([.New, .Old])
}