/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class BusinessRepository : NSObject {
    
    static let sharedInstance : BusinessRepository = BusinessRepository()
    
    private override init() {
        super.init()
    }
}