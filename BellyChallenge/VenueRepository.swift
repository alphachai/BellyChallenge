/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class VenueRepository : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    dynamic var foundResults : Bool = false
    dynamic var queryInProgress : Bool = false
    var results : [Venue] = []
    
    var latitude : Double = 0.00
    var longitude : Double = 0.00
    var total : Int = 0
    
    static let sharedInstance : VenueRepository = VenueRepository()
    
    private override init() {
        super.init()
    }
    
    func get(lat : Double, lng : Double) {
        
        foundResults = false
        queryInProgress = true
        latitude = lat
        longitude = lng
        
        pull(lat, lng: lng)
    }
    
    func get() {
        if(results.count == 0) {
            return
        }
        
        pull(latitude, lng: longitude)
    }
    
    func pull(lat : Double, lng : Double) {
        //let parameters = ["ll": "\(lat),\(lng)", "sort": "1"]
        var url = "\(Constants.Foursquare.API.search)"
            url += "?ll=\(lat),\(lng)"
            url += "&v=20160417"
            url += "&client_id=" + Constants.Foursquare.id
            url += "&client_secret=" + Constants.Foursquare.secret
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        let task = session.downloadTaskWithRequest(request)
        task.resume()
        
        //print("\nGET \(url)")
    }
    
    // Download in progress.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    // Download complete with error.
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            print("DEBUG: download completed with error")
        }
    }
    
    // Download complete.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let data = NSData(contentsOfURL: location)!
        NSOperationQueue.mainQueue().addOperationWithBlock({
            //print(String.init(data: data, encoding:NSUTF8StringEncoding))
            self.processResponse(data)
        })
    }
    
    func clear() {
        if(queryInProgress == false) {
            foundResults = false
            results = []
        }
    }
    
    func processResponse(data : NSData) {
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, v) in jsonData {
                if k == "response" {
                    let venues = v["venues"] as! Array<AnyObject>
                    for nthVenue in venues {
                        
                        let new : Venue = Venue()
                        
                        for (k,v) in nthVenue as! Dictionary<String,AnyObject> {
                            
                            if k == "categories" {
                                
                                let categories = v as! Array<AnyObject>
                                
                                if categories.count > 0 {
                                    let firstCategory = categories.first as! Dictionary<String,AnyObject>
                                    new.category = firstCategory["name"] as! String
                                    let i = firstCategory["icon"] as! Dictionary<String,AnyObject>
                                    let prefix = i["prefix"] as! String
                                    let suffix = i["suffix"] as! String
                                    new.icon_url = prefix + "32" + suffix
                                 }
                                
                            } else if k == "location" {
                              
                                let location = v as! Dictionary<String,AnyObject>
                                new.lat = location["lat"] as! Double
                                new.lng = location["lng"] as! Double
                                
                            } else {
                                
                                if new.respondsToSelector(Selector(k)) && !NSObject.respondsToSelector(Selector(k)) {
                                    new.setValue(v, forKey: k)
                                }
                            }
                        
                        }
                        
                        results.append(new)
                    }
                    
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