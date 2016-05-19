/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class Venue : NSObject {
    
    dynamic var iveUpdated : Bool = false
    
    var id : String = ""
    var name : String = ""
    var lat : Double = 0
    var lng : Double = 0
    var category : String = ""
    var icon_url : String = ""
    var icon_data : ImageData = ImageData()
    
    var downloads : [Download] = []
    var foundTimes : Bool = false
    var isOpen : Bool = false
    var thumb_url = ""
    var thumb : ImageData = ImageData()
    
    var hoursPulled = false
    var photosPulled = false
    
    override init() {
        super.init()
        loadObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    func loadObservers() {
        self.addObserver(self, forKeyPath: "isOpen", options: Constants.KVO_Options, context: nil)
        self.addObserver(self, forKeyPath: "thumb_url", options: Constants.KVO_Options, context: nil)
    }
    
    func removeObservers() {
        self.removeObserver(self, forKeyPath: "isOpen")
        self.removeObserver(self, forKeyPath: "thumb_url")
        
        for d in downloads {
            if d.downloadInProgress {
                d.task!.cancel()
                d.removeObserver(self, forKeyPath: "downloadComplete")
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "downloadComplete" {
            object?.removeObserver(self, forKeyPath: "downloadComplete")
            
            if let d = object?.data {
                if object?.name == "photos" {
                    processPhotos(d)
                } else if object?.name == "hours" {
                    processHours(d)
                }
            }
        } else if keyPath == "isOpen" || keyPath == "thumb_url" {
            iveUpdated = true
        }
    }
    
    func pull_photos() {
        var url = Constants.Foursquare.API.venues + "\(id)/photos"
        url += "?limit=1"
        url += "&v=20160417"
        url += "&client_id=" + Constants.Foursquare.id
        url += "&client_secret=" + Constants.Foursquare.secret
        
        let photosDownload = Download()
        photosDownload.name = "photos"
        
        if let checkedURL = NSURL(string: url) {
            downloads.append(photosDownload)
            downloads.last!.addObserver(self, forKeyPath: "downloadComplete", options: Constants.KVO_Options, context: nil)
            downloads.last!.get("GET", url: checkedURL)
        }
    }
    
    func pull_hours() {
        var url = Constants.Foursquare.API.venues + "\(id)/hours"
        url += "?limit=1"
        url += "&v=20160417"
        url += "&client_id=" + Constants.Foursquare.id
        url += "&client_secret=" + Constants.Foursquare.secret
        
        let photosDownload = Download()
        photosDownload.name = "hours"
        
        if let checkedURL = NSURL(string: url) {
            downloads.append(photosDownload)
            downloads.last!.addObserver(self, forKeyPath: "downloadComplete", options: Constants.KVO_Options, context: nil)
            downloads.last!.get("GET", url: checkedURL)
        }
    }
    
    func processPhotos(data : NSData) {
        
        if photosPulled == true {
            return
        }
        photosPulled = true
        
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, v) in jsonData {
                if k == "response" {
                    let response = v as! Dictionary<String,AnyObject>
                    let photos = response["photos"] as! Dictionary<String,AnyObject>
                    let count = photos["count"] as! Int
                    if count > 0 {
                        let items = photos["items"] as! Array<AnyObject>
                        let item = items[0]
                        let prefix = item["prefix"] as! String
                        let suffix = item["suffix"] as! String
                        //let height = item["height"] as! Int
                        //let width = item["width"] as! Int
                        thumb_url = prefix + "width" + "100" + suffix
                        iveUpdated = true
                    }
                }
            }
        } catch {
            print("Hours JSON serialization failed.")
        }
        
        for i in 0..<downloads.count {
            if downloads[i].downloadComplete && downloads[i].name == "photos" {
                downloads.removeAtIndex(i)
                break
            }
        }
    }
    
    //https://developer.foursquare.com/docs/responses/hours
    func processHours(data : NSData) {
        
        if hoursPulled == true {
            return
        }
        hoursPulled = true
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Weekday , .Hour, .Minute], fromDate: date)
        
        let today_day = components.weekday
        let today_hh = components.hour
        let today_mm = components.minute
        
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, v) in jsonData {
                if k == "response" {
                    let response = v as! Dictionary<String,AnyObject>
                    let hours = response["hours"] as! Dictionary<String,AnyObject>
                    if hours.count > 0 {
                        let timeframes = hours["timeframes"] as! Array<AnyObject>
                        
                        for t in timeframes {
                            foundTimes = true
                            let timeframe = t as! Dictionary<String, AnyObject>
                            let days = timeframe["days"] as! Array<Int>
                            
                            if days.contains(today_day) {
                                
                                let open_segments = timeframe["open"] as! Array<AnyObject>
                                for s in open_segments {
                                    let segment = s as! Dictionary<String,AnyObject>
                                    
                                    let start = segment["start"] as! String
                                    let end = segment["end"] as! String
                                    
                                    let start_h = Int(start[Range(start.startIndex ..< start.startIndex.advancedBy(2))])!
                                    
                                    let start_m = Int(start[Range(start.endIndex.advancedBy(-2) ..< start.endIndex)])!
                                    
                                    let end_h = Int(end[Range(end.startIndex ..< end.startIndex.advancedBy(2))])!
                                    
                                    let end_m = Int(end[Range(end.endIndex.advancedBy(-2) ..< end.endIndex)])!
                                    
                                    if start_h == today_hh {
                                        if today_mm >= start_m {
                                            isOpen = true
                                        }
                                    } else if start_h < today_hh && today_hh < end_h {
                                        isOpen = true
                                    } else if end_h == today_hh {
                                        if today_mm <= end_m {
                                            isOpen = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("Hours JSON serialization failed.")
        }
        
        for i in 0..<downloads.count {
            if downloads[i].downloadComplete && downloads[i].name == "hours" {
                downloads.removeAtIndex(i)
                break
            }
        }
    }
}