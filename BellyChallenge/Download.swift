/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import Foundation

class Download : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var task : NSURLSessionDownloadTask? = nil
    var data = NSData()
    dynamic var downloadComplete : Bool = false
    var downloadInProgress : Bool = false
    var item = 0
    var name = ""
    
    override init() {
        super.init()
    }
    
    func get(method : String, url : NSURL) {
        
        downloadInProgress = true
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method
        task = session.downloadTaskWithRequest(request)
        task!.resume()
    }
    
    // Download in progress.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    // Download complete with error.
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            print("Download \"\(name)\" completed with error.")
        }
    }
    
    // Download complete.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let data = NSData(contentsOfURL: location)!
        NSOperationQueue.mainQueue().addOperationWithBlock({
            self.processResponse(data)
        })
    }
    
    func processResponse(d : NSData) {
        
        data = d
        downloadInProgress = false
        downloadComplete = true
    }
}