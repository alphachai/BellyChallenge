/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import UIKit

class VenueCell: UITableViewCell {

    @IBOutlet weak var thumb: UIImageView!
    @IBOutlet weak var thumbHolder: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
