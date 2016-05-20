/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import UIKit

class DetailedViewController: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    
    var venue = Venue()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        output()
    }
    
    func output() {
        name.text = venue.name
        
        if(venue.thumb.imageDownloadComplete == true) {
            image.image = UIImage(data: venue.thumb.data)!
            image.contentMode = UIViewContentMode.ScaleAspectFill
        } else {
            image.image = UIImage(named: "placeholder.png")
        }
        
        image.layer.borderWidth = 1
        image.layer.borderColor = Constants.Colors.imageBorder.CGColor
        image.layer.cornerRadius = 5
        image.clipsToBounds = true
        
        let foundTimes = venue.foundTimes
        let isOpen = venue.isOpen
        
        status.alpha = 0
        if isOpen == true && foundTimes == true {
            status.alpha = 1
            status.text = "OPEN"
            status.textColor = Constants.Colors.open
        } else if isOpen == false && foundTimes == true {
            status.alpha = 1
            status.text = "CLOSED"
            status.textColor = Constants.Colors.closed
        }
    }
    
    override func viewDidAppear(animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
