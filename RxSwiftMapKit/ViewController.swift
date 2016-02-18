//
//  ViewController.swift
//  RxSwiftMapKit
//
//  Created by George Kravas on 18/02/16.
//  Copyright © 2016 George Kravas. All rights reserved.
//
import UIKit
import RxSwift
import RxCocoa
import MapKit

class ViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    
    let ADDRESS_CELL_ID = "AddessCell"
    let OPEN_MAP_SEGUE = "OpenMap"
    
    var disposeBag = DisposeBag()
    var mapItems: [MKMapItem] = []
    var selectedItem: MKMapItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar
            .rx_text
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { query in
                self.search(query)
            }
            .subscribeNext { (searchResponse) -> Void in
                self.refreshTableView(searchResponse.mapItems)
            }
            .addDisposableTo(disposeBag)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapItems.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: ADDRESS_CELL_ID);
        let addressArray: [String] = mapItems[indexPath.row].placemark.addressDictionary!["FormattedAddressLines"] as! [String];
        cell.textLabel?.text = addressArray.joinWithSeparator(" ")
        return cell
    }
    
    func refreshTableView(mapItems:[MKMapItem]) {
        self.mapItems = mapItems
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    private func search(query: String) -> PublishSubject<MKLocalSearchResponse> {
        let subject = PublishSubject<MKLocalSearchResponse>();
        let mapRequest = MKLocalSearchRequest()
        mapRequest.naturalLanguageQuery = query
        
        let mapSearch = MKLocalSearch(request: mapRequest);
        mapSearch.startWithCompletionHandler { (searchResponce, error) -> Void in
            if error != nil {
                subject.onError(error!)
            } else {
                subject.onNext(searchResponce!)
            }
        }
        return subject;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        selectedItem = mapItems[indexPath.row]
        performSegueWithIdentifier(OPEN_MAP_SEGUE, sender: cell)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == OPEN_MAP_SEGUE {
            (segue.destinationViewController as! MapViewController).item = selectedItem
        }
    }
}

