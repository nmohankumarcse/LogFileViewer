//
//  FilterViewController.swift
//  LogFileViewer
//
//  Created by Mohankumar on 01/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var filterTableView: UITableView!
    var filterChanged : ((_ filterChanged : Bool,_ selections : [String])->())?
    var filters : [String] = []
    var selections : [String] = []
    var heading : String?
    var isMultiSelect : Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(){
        self.filterTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selections.contains(filters[indexPath.row]){
            selections.remove(at: selections.index(of: filters[indexPath.row])!)
        }
        else{
            if !isMultiSelect{
                selections = []
            }
            selections.append(filters[indexPath.row])
        }
        
        self.filterTableView.reloadData()
        self.filterChanged!(true,self.selections)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.heading ?? "Filter"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = filters[indexPath.row]
        cell?.accessoryType = .none
        
        if selections.contains(filters[indexPath.row]){
            cell?.accessoryType = .checkmark
        }
        return cell!
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
