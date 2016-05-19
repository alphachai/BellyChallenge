/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class Venue : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var id : String = ""
    var name : String = ""
    var lat : Double = 0
    var lng : Double = 0
    var category : String = ""
    var icon_url : String = ""
    var icon_data : ImageData = ImageData()
    
    var thumb : ImageData = ImageData()
    
    // use observer so that when photos are pulled if the cell is visible, photo is loaded
    // load thumb should only get data if photos is populated
    func pull_photos() {
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
    
    //list might need an observer on this too? either have individual observers for phtoso and hours or combine into one single "everything has loaded, reload my cell" observer.
    func pull_hours() {
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
    
    func processResponse(data : NSData) {
        // parse venue/photos
    }

}