/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class VenueRepository : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var foundResults : Bool = false
    var queryInProgress : Bool = false
    var results : [Venue] = []
    
    static let sharedInstance : VenueRepository = VenueRepository()
    
    private override init() {
        super.init()
    }
    
    func get(lat : Double, lng : Double) {
        
        foundResults = false
        queryInProgress = true
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        //config.HTTPAdditionalHeaders = ["ll": "\(lat),\(lng)"]
        
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        var url = "\(Constants.Foursquare.API.search)"
        url += "?ll=\(lat),\(lng)&client_id=\(Constants.Foursquare.id)&client_secret=\(Constants.Foursquare.secret)&v=20160417"
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        
        //request.setValue("\(lat),\(lng)", forHTTPHeaderField: "ll")
        
        let task = session.downloadTaskWithRequest(request)
        
        print("\nGET \(url)")
        //print(config.HTTPAdditionalHeaders)
        
        task.resume()
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
        
        //let data = NSData(contentsOfURL: location)!
        
        if let d = NSData(contentsOfURL: location) {
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.processResponse(d)
            })
        }
    }
    
    func processResponse(data : NSData) {
        
        //print(String.init(data: data, encoding:NSUTF8StringEncoding))
        
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, _) in jsonData {
                if k == "venues" {
                    
                    for (k,v) in jsonData["venues"] as! Dictionary<String, AnyObject> {
                        let new : Venue = Venue()
                        
                        if new.respondsToSelector(Selector(k)) && !NSObject.respondsToSelector(Selector(k)) {
                            self.setValue(v, forKey: k)
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