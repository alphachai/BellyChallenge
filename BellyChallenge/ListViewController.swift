/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import UIKit
import CoreLocation

class ListViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager : CLLocationManager = CLLocationManager()
    var current_row = 0
    var current_section = 0
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObservers()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = Constants.Colors.statusBar
        refreshControl!.tintColor = UIColor.whiteColor()
        refreshControl!.addTarget(self, action: #selector(updateLocation), forControlEvents: .ValueChanged)
        
        updateLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        //tableView.reloadData()
        //loadVisibleMediaImages()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        updateLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //print("Found location.")
        if locations.count > 0 {
            let lat = locations[0].coordinate.latitude
            let lng = locations[0].coordinate.longitude
            if(venues.results.count == 0) {
                venues.fetchData(lat, newLng: lng)
            } else {
                pullNewResults(lat, lng: lng)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Unable to find location.")
        print(error.description)
        print("Searching from downtown Chicago, IL")
        if(venues.results.count == 0) {
            venues.fetchData(41.879659, newLng: -87.624636)
        } else {
            pullNewResults(41.879659, lng: -87.624636)
        }
    }
    
    func pullNewResults(lat : Double, lng : Double) {
        removeVenueObservers()
        venues.clear()
        tableView.reloadData()
        venues.get(lat, lng: lng)
    }
    
    func updateLocation() {
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.requestLocation()
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Location Access Disabled",
                message: "For this app to function, please open settings and allow location access.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func loadObservers() {
        venues.addObserver(self, forKeyPath: "foundResults", options: Constants.KVO_Options, context: nil)
    }
    
    func removeObservers() {
        venues.removeObserver(self, forKeyPath: "foundResults")
        removeVenueObservers()
    }
    
    func removeVenueObservers() {
        removeImageObservers()
        if venues.foundResults {
            for i in 0..<venues.results.count {
                venues.results[i].removeObserver(self, forKeyPath: "iveUpdated")
            }
        }
    }
    
    func removeImageObservers() {
        for i in 0..<venues.results.count {//for r in venues.results {
            if venues.results[i].thumb.downloadInProgress == true {
                venues.results[i].thumb.task!.cancel()
                venues.results[i].thumb.removeObserver(self, forKeyPath: "imageDownloadComplete")
            }
            
            if venues.results[i].icon_data.downloadInProgress == true {
                venues.results[i].icon_data.task!.cancel()
                venues.results[i].icon_data.removeObserver(self, forKeyPath: "imageDownloadComplete")
            }
        }
    }
    
    deinit {
        removeObservers()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "iveUpdated" {
            
            let sender = object as? Venue
            
            if sender!.iveUpdated == true {
                sender!.iveUpdated = false
                loadVisible()
            }
            
        } else if keyPath == "foundResults" && venues.foundResults == true {
            
            venues.sortResultsByDistance()
            
            for i in 0..<venues.results.count {
                venues.results[i].addObserver(self, forKeyPath: "iveUpdated", options: Constants.KVO_Options, context: nil)
            }
            
            tableView.reloadData()
            loadVisible()
            refreshControl?.endRefreshing()
            
        } else if keyPath == "deinitCanary" {
            
            removeObservers()
            
        } else if keyPath == "imageDownloadComplete" { // reload the cell where image data is ready
            object?.removeObserver(self, forKeyPath: "imageDownloadComplete")
            
            let target = object as! ImageData
            let path = NSIndexPath(forItem: target.item, inSection: 0)
            tableView.reloadRowsAtIndexPaths([path], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (venues.results.count>0) {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView = nil
            return 2
            
        } else {
            
            let message = UILabel(frame: CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height))
            message.text = "Loading..."
            message.textColor = UIColor.blackColor()
            message.numberOfLines = 0
            message.textAlignment = NSTextAlignment.Center
            
            tableView.backgroundView = message
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        current_row = indexPath.row
        current_section = indexPath.section
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1 // loading cell
        }
        return venues.results.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("venue", forIndexPath: indexPath) as! VenueCell
            
            cell.name.text = venues.results[indexPath.row].name
            cell.type.text = venues.results[indexPath.row].category
            
            cell.distance.text = "\(String(format: "%0.1f", venues.getDistance(venues.results[indexPath.row]))) miles away"
            
            let foundTimes = venues.results[indexPath.row].foundTimes
            let isOpen = venues.results[indexPath.row].isOpen
            
            cell.status.alpha = 0
            if isOpen == true && foundTimes == true {
                cell.status.alpha = 1
                cell.status.text = "OPEN"
                cell.status.textColor = Constants.Colors.open
            } else if isOpen == false && foundTimes == true {
                cell.status.alpha = 1
                cell.status.text = "CLOSED"
                cell.status.textColor = Constants.Colors.closed
            }
            
            if(venues.results[indexPath.item].thumb.imageDownloadComplete == true) {
                cell.thumb.image = UIImage(data: venues.results[indexPath.item].thumb.data)!
                cell.icon.contentMode = UIViewContentMode.ScaleAspectFill
            } else {
                cell.thumb.image = UIImage(named: "placeholder.png")
            }
            
            if(venues.results[indexPath.item].icon_data.imageDownloadComplete == true) {
                cell.icon.image = UIImage(data: venues.results[indexPath.item].icon_data.data)!
                cell.icon.contentMode = UIViewContentMode.ScaleAspectFit
                setTint(cell.icon, tint: Constants.Colors.icon)
            } else {
                cell.icon.image = UIImage()
            }
            
            cell.thumb.layer.borderWidth = 1
            cell.thumb.layer.borderColor = Constants.Colors.imageBorder.CGColor
            cell.thumb.layer.cornerRadius = 5
            cell.thumb.clipsToBounds = true
            
            return cell
        } else {
            return tableView.dequeueReusableCellWithIdentifier("loading", forIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 115
        } else {
            return 50
        }
    }
    
    func setTint(view: UIImageView, tint: UIColor) {
        let i = view.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        view.image = i
        view.tintColor = tint
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            loadVisible()
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        loadVisible()
    }
    
    func loadVisible() {
        if venues.results.count > 0 {
            if let indicies : [NSIndexPath] = tableView.indexPathsForVisibleRows! {
                for i in indicies {
                    if i.section == 0 {
                        loadThumb(i.row)
                        loadIcon(i.row)
                        
                        if venues.results[i.row].photosPulled == false {
                            venues.results[i.row].pull_photos()
                        }
                        
                        if venues.results[i.row].hoursPulled == false {
                            venues.results[i.row].pull_hours()
                        }
                    } else if i.section == 1 {
                        print("Load more results? Not implemented for this demo.")
                    }
                }
            }
        }
    }
    
    func loadThumb(index : Int) {
        if venues.results[index].thumb.imageDownloadComplete == true || venues.results[index].thumb_url == "" {
            return // already loaded or no url
        }
        let url = venues.results[index].thumb_url
        if let checkedURL = NSURL(string: url) {
            venues.results[index].thumb.item = index
            venues.results[index].thumb.addObserver(self, forKeyPath: "imageDownloadComplete", options: Constants.KVO_Options, context: nil)
            venues.results[index].thumb.name = "thumb"
            venues.results[index].thumb.get(checkedURL)
        }
    }
    
    func loadIcon(index : Int) {
        if venues.results[index].icon_data.imageDownloadComplete == true || venues.results[index].icon_url == "" {
            return // already loaded or no icon url
        }
        var url = venues.results[index].icon_url
            url += "?client_id=" + Constants.Foursquare.id
            url += "&client_secret=" + Constants.Foursquare.secret
        if let checkedURL = NSURL(string: url) {
            venues.results[index].icon_data.item = index
            venues.results[index].icon_data.addObserver(self, forKeyPath: "imageDownloadComplete", options: Constants.KVO_Options, context: nil)
            venues.results[index].icon_data.name = "icon"
            venues.results[index].icon_data.get(checkedURL)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "tableShowDetail" {
            
            let dest = segue.destinationViewController as! DetailedViewController
            dest.venue = venues.results[current_row]
        }
    }

}

