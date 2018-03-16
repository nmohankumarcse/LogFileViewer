//
//  ViewController.swift
//  LogFileViewer//  Created by Mohankumar on 27/02/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

struct JsonViewParams{
    var list : [Any] = []
    var filters : [String] = []
    var sortFilters : [String] = []
    var pageIndex : Int = 0
    var selectedIndexPath : IndexPath?
    var collapseSectionArray : [Int] = []
    var heading : String = ""
    var parent : String = ""
    var tree : String = ""
    var color : UIColor = UIColor.white
    var parentColor : UIColor = UIColor.white
}


class JsonViewerViewController: UIViewController{
    var jsonViewParams : JsonViewParams = JsonViewParams.init()
    var filter : FilterViewController?
    enum FilterType{
        case  Filter
        case  Sort
    }
    var didSelectRowAt :((JsonViewParams)->())?
    var handlerClose :((_ index : Int,_ includeParent: Bool)->())?
    var filterType : FilterType = .Filter
    @IBOutlet weak var descriptorLabel: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterContainer: UIView!
    @IBOutlet weak var isExpandedButtonView: UIView!
    @IBOutlet weak var isExpandedButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var deleteSpinner: UIActivityIndicatorView!
    @IBOutlet weak var optionsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.descriptorLabel
        setUpUI()
    }
    
    func setUpUI(){
        self.title = jsonViewParams.heading
        self.view.backgroundColor = jsonViewParams.parentColor
        descriptorLabel.textContainer.lineFragmentPadding = 15
        if jsonViewParams.list.count == 0{
            if let path = Bundle.main.path(forResource: "sampleData", ofType: "json"){
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    //welcome = try! Welcome.init(data: data)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    do {
                        jsonViewParams.list = [jsonResult]
                        tableView.reloadData()
                    }
                } catch {
                    // handle error
                }
            }
        }
            
        else{
            let result = jsonViewParams.list[0]
            updateDescriptorLabel()
            if jsonViewParams.filters.count == 0{
                if let res = result as? Dictionary<String, Any>{
                    jsonViewParams.filters = [String](res.keys.sorted())
                }
            }
            if jsonViewParams.sortFilters.count == 0{
                autoSort()
            }
        }
        if jsonViewParams.list.count>0{
            if let item = jsonViewParams.selectedIndexPath?.item{
                if !jsonViewParams.collapseSectionArray.contains(item){
                    if jsonViewParams.list.count > (jsonViewParams.selectedIndexPath?.row)!{
                    self.tableView.scrollToRow(at: jsonViewParams.selectedIndexPath!, at: .middle, animated: false)
                    }
                }
            }
            let result = jsonViewParams.list[0]
            if let res = result as? Dictionary<String, Any>{
                var isExpanded = true
                for key in res.keys.enumerated(){
                    let value = res[key.element]
                    if let _ = value as? Array<Any>{
                        isExpanded = false
                    }
                    else if let _ = value as? Dictionary<String,Any>{
                        isExpanded = false
                    }
                }
                self.isExpandedButtonView.isHidden = isExpanded
            }
        }
        self.tableView.reloadData()
    }
    
    func updateDescriptorLabel(){
//        let result = jsonViewParams.list[0]
//        if let res = result as? Dictionary<String, Any>{
//            let allKeys = Set.init(res.keys.sorted())//
//            let filteredKeys = Set.init(jsonViewParams.filters)
//            let excludedKeys = allKeys.subtracting(filteredKeys)
        
        self.descriptorLabel.text = "Tree :\n\(jsonViewParams.tree) \nSort by : \(jsonViewParams.sortFilters.joined())"
        
        if(descriptorLabel.text.indices.count > 0 )
        {
            let bottom : NSRange = NSRange.init(location: descriptorLabel.text.indices.count - 1, length: 1)
            descriptorLabel .scrollRangeToVisible(bottom)
        }
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ExpandCollapse(_ sender: UIButton) {
        self.spinner.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
            sender.isSelected = !sender.isSelected
            self.handlerClose!(self.jsonViewParams.pageIndex,false)
        })
    }
    
    func shareJson() {
        let data = try! JSONSerialization.data(withJSONObject: jsonViewParams.list, options: [])
        
        do {
            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            var filename = jsonViewParams.tree
            filename = filename.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            let fileUrl = documentDirectoryUrl.appendingPathComponent("\(filename.components(separatedBy: "/").last ?? filename).json")
            try data.write(to:fileUrl, options: [])
            
            let objectsToShare = [fileUrl]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.optionsButton
            activityVC.popoverPresentationController?.sourceRect = self.optionsButton.bounds
            self.present(activityVC, animated: true, completion: nil)
            
        } catch let error{
            print("cannot write file \(error.localizedDescription)")
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    func captureScreenshot(){
        let image = screenshot()
         guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let filename = jsonViewParams.heading
        if let imageData = UIImageJPEGRepresentation(image, 1.0){
            let imageUrl = documentDirectoryUrl.appendingPathComponent("\(filename.components(separatedBy: "/").last ?? filename).jpg")
            try! imageData.write(to:imageUrl, options: [])
        }
//        jsonViewParams.screenshot = image
    }
    
    func combineTreeAndTable()->UIImage{
        let treeImage = treeScreenshot()
        let tableImage = screenshot()
        let width = max(treeImage.size.width, tableImage.size.width)
        let height = treeImage.size.height+tableImage.size.height
        let size = CGSize.init(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        jsonViewParams.parentColor.setFill()
        let rect = CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: size)
        UIRectFill(rect)
        treeImage.draw(in: CGRect.init(x: 0, y: 0, width: treeImage.size.width, height: treeImage.size.height))
        tableImage.draw(in: CGRect.init(x: 0, y: treeImage.size.height, width: tableImage.size.width, height: tableImage.size.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func screenshot() -> UIImage{
        
        UIGraphicsBeginImageContextWithOptions(self.tableView.contentSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        let previousFrame = tableView.frame
        tableView.frame = CGRect.init(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: self.tableView.contentSize.width, height: self.tableView.contentSize.height);
        tableView.layer.render(in: context!)
        tableView.frame = previousFrame
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image!
    }
    
    func treeScreenshot() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(self.descriptorLabel.contentSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        let previousFrame = descriptorLabel.frame
        descriptorLabel.frame = CGRect.init(x: descriptorLabel.frame.origin.x, y: descriptorLabel.frame.origin.y, width: self.descriptorLabel.contentSize.width, height: self.descriptorLabel.contentSize.height);
        descriptorLabel.layer.render(in: context!)
        descriptorLabel.frame = previousFrame
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image!
    }
}

extension JsonViewerViewController{//Fiters & Sort
    
    func autoSort(){
        let result = jsonViewParams.list[0]
        if let res = result as? Dictionary<String, Any>{
            if let sortedKey = res.minSortableIntValueKey(){
                jsonViewParams.sortFilters = [sortedKey]
                if var sort = jsonViewParams.list as? [Dictionary<String, Any>]{
                    jsonViewParams.list = sort.sortByKey(key: sortedKey)
                }
            }
            updateDescriptorLabel()
        }
    }
    
    @IBAction func filterTapped(_ sender: Any) {
        
        let actionSheetController = UIAlertController(title: "Choose", message: nil, preferredStyle: .actionSheet)
        let deleteActionButton = UIAlertAction(title: "Delete", style: .default) { action -> Void in
            self.delete()
        }
        let shareActionButton = UIAlertAction(title: "Share", style: .default) { action -> Void in
            self.shareJson()
        }
        let filterActionButton = UIAlertAction(title: "Filter", style: .default){action -> Void in
            self.showFilter()
        }
        let openNewButton = UIAlertAction(title: "Open in New Window", style: .default){ action -> Void in
            self.openInNewWindow()
        }
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .destructive) { action -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        actionSheetController.addAction(openNewButton)
        actionSheetController.addAction(filterActionButton)
        actionSheetController.addAction(shareActionButton)
        actionSheetController.addAction(deleteActionButton)
        actionSheetController.addAction(cancelActionButton)
        actionSheetController.popoverPresentationController?.sourceView = sender as? UIButton
        actionSheetController.popoverPresentationController?.sourceRect = ((sender as? UIButton)?.bounds)!
        self.present(actionSheetController, animated: true, completion: nil)
     }
    
    
    func openInNewWindow(){
        let jsonCollectionViewController = self.storyboard?.instantiateViewController(withIdentifier: "JsonCollectionViewController") as? JsonCollectionViewController
        var copy = self.jsonViewParams
        copy.pageIndex = 0
        jsonCollectionViewController?.jsonViewParamsList = [copy]
        self.present(jsonCollectionViewController!, animated: true, completion: nil)
    }
    
    func showFilter(){
        filterType = .Filter
        filterContainer.isHidden = !filterContainer.isHidden
        prepareFilter()
        filter?.refresh()
    }
    
    func delete(){
        deleteSpinner.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
            self.handlerClose!(self.jsonViewParams.pageIndex,true)
        })
    }
    
    @IBAction func deleteJsonView(_ sender: Any) {
        delete()
//        self.shareJson()
    }
    
    @IBAction func sort(_ sender: Any) {
        filterType = .Sort
        filterContainer.isHidden = !filterContainer.isHidden
        prepareFilter()
        filter?.refresh()
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
            if let logMessage = jsonViewParams.list as? [Dictionary<String, Any>]{
                if logMessage.count > 0{
                    filter?.filters = logMessage[0].keys.sorted()
                    filter?.selections = jsonViewParams.filters
                    filter?.heading = "Filter"
                    filter?.filterChanged = setFilterSelection(status:selections:)
                    filter?.isMultiSelect = true
                }
            }
        case .Sort:
            if let logMessage = jsonViewParams.list as? [Dictionary<String, Any>]{
                if logMessage.count > 0{
                    filter?.filters = logMessage[0].keys.sorted()
                    filter?.selections = jsonViewParams.sortFilters
                    filter?.heading = "Sory By"
                    filter?.isMultiSelect = false
                    filter?.filterChanged = setsortFilterselection(status:selections:)
                }
            }
        }
    }
    
    func setFilterSelection(status : Bool,selections : [String]){
        if status{
            jsonViewParams.filters = selections
            tableView.reloadData()
        }
        updateDescriptorLabel()
    }
    
    func setsortFilterselection(status : Bool,selections : [String]){
        if status{
            jsonViewParams.sortFilters = selections
            if var logMessage = jsonViewParams.list as? [Dictionary<String, Any>]{
                if logMessage.count > 0{
                    if selections.count > 0 {
                        jsonViewParams.list = logMessage.sortByKey(key: selections.first!)
                    }
                }
            }
        }
        tableView.reloadData()
    }
}

extension JsonViewerViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return jsonViewParams.list.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !jsonViewParams.collapseSectionArray.contains(section){
            return jsonViewParams.filters.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = jsonViewParams.list[indexPath.section]
        if let res = result as? Dictionary<String, Any>{
            if jsonViewParams.filters.count >= indexPath.row{
                let key = jsonViewParams.filters[indexPath.row]
                let value = res[key]
                jsonViewParams.selectedIndexPath = indexPath
                if let ary = value as? Array<Any>{
                    var jsonViewCopy = self.jsonViewParams
                    jsonViewCopy.heading = "\(key)"
                    jsonViewCopy.list = ary
                    self.didSelectRowAt!(jsonViewCopy)
                }
                else if let dict = value as? Dictionary<String,Any> {
                    if dict.collectionTypes().count > 0{
                        var jsonViewCopy = self.jsonViewParams
                        jsonViewCopy.heading = "\(key)"
                        jsonViewCopy.list = [dict]
                        self.didSelectRowAt!(jsonViewCopy)
                    }
                }
                else{
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(jsonViewParams.heading) - \(section)"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! JsonViewerHeaderTableViewCell
        cell.index = section
        cell.headerTitle.text = "\(jsonViewParams.heading) - (\(section+1)/\(jsonViewParams.list.count))"
        cell.handlerForSelection = headerTapped(index:)
        return cell
    }
    
    func headerTapped(index : Int){
        if jsonViewParams.collapseSectionArray.contains(index){
            jsonViewParams.collapseSectionArray.remove(at: jsonViewParams.collapseSectionArray.index(of: index)!)
        }
        else{
            jsonViewParams.collapseSectionArray.append(index)
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = jsonViewParams.list[indexPath.section]
        var cell = tableView.dequeueReusableCell(withIdentifier: "valuecell")
        if let res = result as? Dictionary<String, Any>{
            if jsonViewParams.filters.count > indexPath.row{
                let key = jsonViewParams.filters[indexPath.row]
                let value = res[key]
                cell?.accessoryType = .none
                if let val = value as? String{
                    cell?.detailTextLabel?.text = val
                }
                else if let ary = value as? Array<Any>{
                    cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                    cell?.accessoryType = .disclosureIndicator
                    cell?.detailTextLabel?.text = "\(key) (\(ary.count))"
                }
                else if let dict = value as? Dictionary<String,Any> {
                    cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                    cell?.accessoryType = .disclosureIndicator
                    if dict.collectionTypes().count == 0{
                        cell?.detailTextLabel?.text = dict.map{"\($0.key):\($0.value)"}.joined(separator: "\n")
                    }else{
                        cell?.detailTextLabel?.text = dict.map{"\($0.key): Dictionary"}[0]
                    }
                }
                else{
                    cell?.detailTextLabel?.text = "\(value ?? 0)"
                }
                cell?.textLabel?.text = key
            }
        }
        cell?.backgroundColor = jsonViewParams.color
        cell?.contentView.backgroundColor = jsonViewParams.color
        if indexPath == jsonViewParams.selectedIndexPath{
            cell?.backgroundColor = UIColor.lightGray
        }
        //            cell?.selectionStyle = .none
        return cell!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView{
            self.filterContainer.isHidden = true
        }
    }
}

