/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class BusinessRepository : NSObject {
    
    dynamic var foundResults : Bool = false
    dynamic var queryInProgress : Bool = false
    var results : [Business] = []
    let yelp = YelpAPIClient()
    
    var latitude : Double = 0.00
    var longitude : Double = 0.00
    var total : Int = 0
    
    static let sharedInstance : BusinessRepository = BusinessRepository()
    
    private override init() {
        super.init()
    }
    
    func get(lat : Double, lng : Double) {
        
        foundResults = false
        queryInProgress = true
        latitude = lat
        longitude = lng
        
        let parameters = ["ll": "\(lat),\(lng)", "sort": "1"]
        
        yelp.searchPlacesWithParameters(parameters, successSearch: { (data, response) -> Void in
            
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.processResponse(data)
                })
            
            }, failureSearch: { (error) -> Void in
                print(error)
        })
    }
    
    func get() {
        if(results.count == 0) {
            return
        }
        
        let parameters = ["ll": "\(latitude),\(longitude)", "sort": "1"]
        
        yelp.searchPlacesWithParameters(parameters, successSearch: { (data, response) -> Void in
            
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.processResponse(data)
            })
            
            }, failureSearch: { (error) -> Void in
                print(error)
        })
    }
    
    func clear() {
        if(queryInProgress == false) {
            foundResults = false
            results = []
        }
    }
    
    func processResponse(data : NSData) {
        
        //print(String.init(data: data, encoding:NSUTF8StringEncoding))
        
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, v) in jsonData {
                if k == "businesses" {
                    
                    for b in jsonData["businesses"] as! [AnyObject] {
                        
                        let new : Business = Business()
                        
                        for (k,v) in b as! Dictionary<String, AnyObject> {
                            
                            if k == "categories" {
                                
                                let categories = v as! Array<AnyObject>
                                let first = categories.first as! Array<AnyObject>
                                new.category = first.first as! String
                                
                            } else {
                                
                                if new.respondsToSelector(Selector(k)) && !NSObject.respondsToSelector(Selector(k)) {
                                    new.setValue(v, forKey: k)
                                }
                            }
                        
                        }
                        
                        results.append(new)
                    }
                    
                } else if k == "total" {
                    total = v as! Int
                }
            }
        } catch {
            NSLog("JSON serialization failed!")
        }
        
        if results.count > 0 {
            foundResults = true
        } else {
            print("Search returned no results or encountered an error.")
        }
        
        queryInProgress = false
    }
}