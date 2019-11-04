//
//  ViewController.swift
//  Snacktacular
//
//  Created by John Gallaugher on 3/23/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit
import CoreLocation

class SpotsListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var spots: Spots!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        spots = Spots()
        spots.spotArray.append(Spot(name: "El Pelon", address: "Comm. Ave", coordinate: CLLocationCoordinate2D(), averageRating: 0.0, numberOfReviews: 0, postingUserID: "", documentID: ""))
        spots.spotArray.append(Spot(name: "Shake Shack", address: "The Street – Chestnut Hill", coordinate: CLLocationCoordinate2D(), averageRating: 0.0, numberOfReviews: 0, postingUserID: "", documentID: ""))
        spots.spotArray.append(Spot(name: "Pino's Pizza", address: "Cleveland Circle", coordinate: CLLocationCoordinate2D(), averageRating: 0.0, numberOfReviews: 0, postingUserID: "", documentID: ""))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSpot" {
            let destination = segue.destination as! SpotDetailViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.spot = spots.spotArray[selectedIndexPath.row]
        } else {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
}

extension SpotsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spots.spotArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SpotsTableViewCell
        cell.nameLabel.text = spots.spotArray[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
