/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import Foundation

class ImageData : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var task : NSURLSessionDownloadTask? = nil
    var data = NSData()
    dynamic var imageDownloadComplete : Bool = false
    var downloadInProgress : Bool = false
    var item = 0
    
    override init() {
        super.init()
    }
    
    init(i : Int) {
        super.init()
        item = i
    }
    
    func get(url : NSURL) {
        
        downloadInProgress = true
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let request = NSMutableURLRequest(URL: url)
        task = session.downloadTaskWithRequest(request)
        task!.resume()
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
            self.processResponse(data)
        })
    }
    
    func processResponse(d : NSData) {
        
        data = d
        downloadInProgress = false
        imageDownloadComplete = true
    }
}