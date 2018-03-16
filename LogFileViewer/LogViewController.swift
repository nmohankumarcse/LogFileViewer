//
//  LogViewController.swift
//  LogFileViewer//  Created by Mohankumar on 28/02/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class LogViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    var logParser : LogParser = LogParser()
    var filters : [String] = []
    var eventFitlers : [String] = []
    var eventFilterSelected : [String] = []
    var filter : FilterViewController?
    enum FilterType{
        case  Filter
        case  Event
    }
    
    @IBOutlet weak var logTableView: UITableView!
    @IBOutlet weak var filterContainer: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var addFile: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.filters = LogType.allValues.map{$0.rawValue}
        self.eventFitlers = []
       self.textView.isHidden = true
        self.spinner.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
            
//            if let path = Bundle(for: type(of: self)).path(forResource: "XMLDocument", ofType: "xml") {
//                if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
//                    let xml = XML.parse(data)
//                    let array =  self.convertXMLToDict(xmlAny: xml.all!)
//                    let dict = ["Root":array[0]]
//                    let data = try! JSONSerialization.data(withJSONObject: dict, options: [])
//                    let parsedString = "2018-03-01 22:19:57 " + String.init(data: data, encoding: .utf8)!
//
//                    self.logParser.parseString(parsedString: parsedString, completion: { status in
//                        switch status{
//                        case .success:
//                            self.updateFilter(searchText: nil, completion: self.reloadTables)
//                        case .failure(let error):
//                            self.reloadTables()
//                            print("Parser Error",error)
//                        }
//                    })
//                }
//            }
            

            self.logParser.parseLogFile(completion: { status in
                switch status{
                case .success:
                    self.updateFilter(searchText: nil, completion: self.reloadTables)
                case .failure(let error):
                    self.reloadTables()
                    print("Parser Error",error)
                }
            })
        })
        // Do any additional setup after loading the view.
    }
    

    

    
    @IBAction func addFile(_ sender: Any) {
        if self.textView.isHidden == false{
            self.textView.isHidden = true
            self.spinner.startAnimating()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
                self.logParser.parseString(parsedString: self.textView.text, completion: { status in
                    switch status{
                    case .success:
                        self.updateFilter(searchText: nil, completion: self.reloadTables)
                    case .failure(let error):
                        self.reloadTables()
                        print("Parser Error",error)
                    }
                })
            })
        }
        else{
            self.textView.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    var filterType : FilterType = .Filter
    
    @IBAction func filter(_ sender: Any) {
        filterType = .Filter
        filterContainer.isHidden = !filterContainer.isHidden
        prepareFilter()
        self.textView.isHidden = true
        filter?.refresh()
    }
    
    
    @IBAction func events(_ sender: Any) {
        filterType = .Event
        prepareFilter()
        filter?.refresh()
       self.textView.isHidden = true
        filterContainer.isHidden = !filterContainer.isHidden
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFilter"{
            filter = segue.destination as? FilterViewController
            prepareFilter()
        }
    }
    
    func prepareFilter(){
        switch filterType{
        case .Filter:
            filter?.filters = LogType.allValues.map{$0.rawValue}
            filter?.selections = filters
            filter?.heading = "Filter"
            filter?.filterChanged = setFilterSelection(status:selections:)
        case .Event:
            filter?.filters = eventFitlers
            filter?.selections = eventFilterSelected
            filter?.heading = "Event"
            filter?.filterChanged = setEventFilterSelection(status:selections:)
        }
    }
    
    func setFilterSelection(status : Bool,selections : [String]){
        if status{
            self.filters = selections
            updateFilter(searchText: searchBar.text, completion: reloadTables)
        }
    }
    
    func setEventFilterSelection(status : Bool,selections : [String]){
        if status{
            self.eventFilterSelected = selections
            updateFilter(searchText: searchBar.text, completion: reloadTables)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        updateFilter(searchText: searchBar.text, completion: reloadTables)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateFilter(searchText: searchBar.text, completion: reloadTables)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.logTableView{
            return self.logParser.logKeys.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var keys = self.logParser.log.keys.sorted()
        return keys[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = self.logParser.logKeys[section]
        let logMessage = self.logParser.log[key]
        return logMessage!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            let key = self.logParser.logKeys[indexPath.section]
            let logMessage = self.logParser.log[key]
            let logItem = logMessage![indexPath.row]
            cell?.textLabel?.text = logItem.message
            if logItem.logType == .Error{
                cell?.textLabel?.text = ""+logItem.message.suffix(200)
            }
            if logItem.logType == .Request || logItem.logType == .Response || logItem.logType == .RequestXML || logItem.logType == .ResponseXML{
                cell?.accessoryType = .disclosureIndicator
            }
            cell?.detailTextLabel?.text = logItem.logType.rawValue
//            cell?.selectionStyle = .none
            return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = self.logParser.logKeys[indexPath.section]
        let logMessage = self.logParser.log[key]
        let logger = logMessage![indexPath.row] as LogMessage
        if let ary = logger.json{
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "JsonNavigator") as? JsonNavigatorViewController{
//                let key = self.logParser.logKeys[indexPath.section]
//                vc.list = [ary]
//                vc.heading = logger.logType.rawValue
//                vc.breadCrumb = ["\(key) : \(logger.message)"]
                vc.heading = "\(logger.time) : \(logger.message)"
                vc.json = ary
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    func reloadTables(){
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.logTableView.reloadData()
        }
    }
    
    func updateFilter(searchText : String?,completion: @escaping ()->()){
        self.spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            var sorted = self.logParser.logMessages.sorted{$0.time < $1.time}
            if let str = searchText, str.indices.count > 0{
                sorted = sorted.filter{$0.wholeContent.contains(str)}
            }
            sorted = sorted.filter{self.filters.contains($0.logType.rawValue)}
            self.updateEvents(sorted: sorted)
            if self.eventFilterSelected.count > 0{
                sorted = sorted.filter{self.eventFilterSelected.contains($0.message)}
            }
            DispatchQueue.main.async {
                self.title = "Log (\(sorted.count))"
            }
            self.logParser.generateLog(sorted: sorted, completion: completion)
        }
    }
    
    
    func updateEvents(sorted : [LogMessage]){
        eventFitlers = []
        eventFitlers = sorted.map{$0.message}
        eventFitlers = eventFitlers.unique
        let ary = eventFilterSelected.filter{eventFitlers.contains($0)}
        if ary.count == 0{
            eventFilterSelected = []
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
        if scrollView == self.logTableView{
            self.filterContainer.isHidden = true
        }
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

