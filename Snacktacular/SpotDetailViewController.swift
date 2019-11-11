//
//  SpotDetailViewController.swift
//  Snacktacular
//
//  Created by John Gallaugher on 3/23/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit
import GooglePlaces
import MapKit
import Contacts

class SpotDetailViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var averageRatingLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    var spot: Spot!
    var reviews: Reviews!
    var photos: Photos!
    let regionDistance: CLLocationDistance = 750 // 750 meters or about a half mile
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        
        
        // mapView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        imagePicker.delegate = self
        
        
        
        if spot == nil {
            spot = Spot()
            getLocation()
            nameField.addBorder(width: 0.5, radius: 5.0, color: .black)
            addressField.addBorder(width: 0.5, radius: 5.0, color: .black)
            
        } else {
            nameField.isEnabled = false
            addressField.isEnabled = false
            nameField.backgroundColor = UIColor.clear
            addressField.backgroundColor = UIColor.white
            saveBarButton.title = ""
            cancelBarButton.title = ""
            navigationController?.setToolbarHidden(true, animated: true)
            
            
        }
        reviews = Reviews()
        photos = Photos()
 
        let region = MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        mapView.setRegion(region, animated: true)
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reviews.loadData(spot: spot) {
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        spot.name = nameField.text!
        spot.address = addressField.text!
        switch segue.identifier ?? "" {
        case "AddReview":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ReviewTableViewController
            destination.spot = spot
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        case "ShowReview":
            let destination = segue.destination as! ReviewTableViewController
            destination.spot = spot
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.review = reviews.reviewArray[selectedIndexPath.row]
        default:
            print("*** ERROR Did not have a segue in SpotDetailViewController prepare(for segue:)")
            
        }
    }
    
    func updateUserInterface() {
        nameField.text = spot.name
        addressField.text = spot.address
        updateMap()
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(spot)
        mapView.setCenter(spot.coordinate, animated: true)
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.accessCamera()
        }
        let photolibaryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(photolibaryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        saveBarButton.isEnabled = (nameField.text == "")
    }
    
    @IBAction func textFieldReturnPressed(_ sender: UITextField) {
        sender.resignFirstResponder()
        spot.name = nameField.text!
        spot.address = addressField.text!
        updateUserInterface()
        
    }
    
    

    @IBAction func photoButtonPressed(_ sender: UIButton) {
        cameraOrLibraryAlert()
    }
    
    @IBAction func reviewButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "AddReview", sender: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        spot.name = nameField.text!
        spot.address = addressField.text!
        spot.saveData { success in
            if success {
                self.leaveViewController()
            } else {
                print("*** ERROR: Couldn't leave this view controller because data wasn't saved.")
            }
        }
    }
    
    @IBAction func lookupPlacePressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
}

extension SpotDetailViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        spot.name = place.name!
        spot.address = place.formattedAddress ?? ""
        spot.coordinate = place.coordinate
        dismiss(animated: true, completion: nil)
        updateUserInterface()
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

extension SpotDetailViewController: CLLocationManagerDelegate {
    
    func getLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func handleLocationAuthorization(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            print("I'm sorry – can't show location. User has not authorized it.")
        case .restricted:
            print("Access denied. Likely parental controls are restricting location services in this app.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorization(status: status)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard spot.name == "" else {
            return
        }
        let geoCoder = CLGeocoder()
        var name = ""
        var address = ""
        currentLocation = locations.last
        spot.coordinate = currentLocation.coordinate
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {placemarks, error in
            if placemarks != nil {
                let placemark = placemarks?.last
                name = placemark?.name ?? "name unknown"
                // need to import contacts to use this code:
                if let postalAddress = placemark?.postalAddress {
                    address = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                }
            } else {
                print("*** Error retrieving place. Error code: \(error!.localizedDescription)")
            }
            self.spot.name = name
            self.spot.address = address
            self.updateUserInterface()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location.")
    }
}

extension SpotDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.reviewArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as! SpotReviewsTableViewCell
        cell.review = reviews.reviewArray[indexPath.row]
        return cell
    }
}

extension SpotDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! SpotPhotosCollectionViewCell
        cell.photo = photos.photoArray[indexPath.row]
        return cell
    }
}

extension SpotDetailViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let photo = Photo()
        photo.image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        photos.photoArray.append(photo)
        dismiss(animated: true) {
            self.collectionView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
    
    
    
}
