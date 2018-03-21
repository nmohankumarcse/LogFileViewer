//
//  JsonCollectionViewController.swift
//  LogFileViewer//  Created by Mohankumar on 02/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class JsonCollectionViewController: UIViewController ,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    let colors =  [#colorLiteral(red: 0.7798358798, green: 0.7913441062, blue: 0.8411058784, alpha: 1),#colorLiteral(red: 0.8004157031, green: 0.8862745166, blue: 0.7694299163, alpha: 1),#colorLiteral(red: 0.8072711229, green: 0.8187190294, blue: 0.8726261258, alpha: 1),#colorLiteral(red: 0.966617167, green: 0.8771314025, blue: 0.9303179383, alpha: 1),#colorLiteral(red: 0.8907834888, green: 0.8533425927, blue: 0.931820631, alpha: 1),#colorLiteral(red: 0.9168012142, green: 0.9452653527, blue: 0.945302546, alpha: 1),#colorLiteral(red: 0.8540275693, green: 0.8777510524, blue: 0.9234330058, alpha: 1)]
    
    @IBOutlet weak var jsonViewTypeSegment: UISegmentedControl!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var jsonCollectionView: UICollectionView!
    var selectedIndexHandler : ((_ index: Int)->())?
    var jsonViewControllerMapper : [Int:JsonViewerViewController] = [:]
    var treeColor : [String : UIColor] = [:]
    var treeChildColor : [String : UIColor] = [:]
    var treeChild : [String : [String]] = [:]
    var jsonViewParamsList : [JsonViewParams] = []
    var indexSelected : Int = 0
    var addBreadCrumbHandler : ((_ index: Int,_ headings:[String])->())?
    var noOfFragments = 1
    
    
    enum ExpansionStatus{
        case nochild
        case hasChildren(count : Int)
    }
    
    fileprivate func expandAll(_ pJsonViewParams: JsonViewParams,completion: (ExpansionStatus)->()) {
        var pageCount = 0
        var containsChild = false
        for (section,list) in pJsonViewParams.list.enumerated(){
            if let res = list as? Dictionary<String, Any>{
                for(_,key) in res.keys.enumerated(){
                    if var ary = res[key] as? Array<Any>{
                        var sortFilters : [String] = []
                        if ary.count > 0{
                            containsChild = true
                            if let sortedKey = res.minSortableIntValueKey(){
                                sortFilters = [sortedKey]
                                if var sort = ary as? [Dictionary<String, Any>]{
                                    ary = sort.sortByKey(key: sortedKey)
                                }
                            }
                            else{
                                sortFilters = []
                            }
                            pageCount = pageCount+1
                            var newJsonParams = pJsonViewParams
                            var parent = ""
                            if pJsonViewParams.list.count > 1{
                                parent = "\(pJsonViewParams.heading)(\(section+1)/\(pJsonViewParams.list.count))-\(key)"
                            }
                            else{
                               parent = "\(key)"
                            }
                            newJsonParams.heading = "\(key)"
                            newJsonParams.sortFilters = sortFilters
                            newJsonParams.list = ary
                            let _ = insertNewNode(newJsonParams, parent: "\(parent)")
//                            expandAll(insertedNode, completion: { status in
//                                print(status)
//                            })
                        }
                    }
                    else if let dict = res[key] as? Dictionary<String,Any>{
                        containsChild = true
                        pageCount = pageCount+1
                        
                        if dict.collectionTypes().count > 0{
                            var newJsonParams = pJsonViewParams
                            newJsonParams.heading = "\(key)"
                            newJsonParams.list = [dict]
                            let _ = insertNewNode(newJsonParams, parent: "\(key)")
//                            expandAll(insertedNode, completion:{ status in
//                                    print(status)
//                            })
                        }
                    }
                }
            }
        }
        if !containsChild{
            completion(.nochild)
        }
        else{
           completion(.hasChildren(count: pageCount))
        }
        self.initializeAllViewControllers()
        self.refresh()
        if let breadCrumb = addBreadCrumbHandler{
            breadCrumb(self.indexSelected,jsonViewParamsList.map{$0.parent})
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIScreen.main.bounds.size.width > 414{
            noOfFragments = 3
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !treeColor.keys.contains(self.jsonViewParamsList[0].tree){
            createNewColor(self.jsonViewParamsList[0].tree)
            let pJsonViewParams = self.jsonViewParamsList[0]
            expandAll(pJsonViewParams, completion: { status in
                print("viewDidAppear",status)
                self.refresh()
            })
        }
    }
    @IBAction func segmentChanged(_ sender: Any) {
        noOfFragments = 1
        if self.jsonViewTypeSegment.selectedSegmentIndex == 0{
            if UIScreen.main.bounds.size.width > 414{
                noOfFragments = 3
            }
        }
        else{
            indexSelected = 0
        }
        self.refresh()
    }
    
    @IBAction func back(_ sender: Any) {
        if (self.navigationController != nil){
            self.navigationController?.popViewController(animated: true)
        }
        else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        noOfFragments = 1
        if size.width > 414{
            noOfFragments = 3
        }
        self.jsonCollectionView.reloadData()
    }

    func getViewControllerAtIndex(index: NSInteger) -> JsonViewerViewController
    {
        let vc : JsonViewerViewController?
        if jsonViewControllerMapper.keys.sorted().contains(index){
            vc = jsonViewControllerMapper[index]
        }
        else{
            vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? JsonViewerViewController
            self.addChildViewController(vc!)
            jsonViewControllerMapper[index] = vc
            vc?.didMove(toParentViewController: self)
        }
        // Create a new view controller and pass suitable data.
        
        //            let key = self.logParser.logKeys[index]
        let jsonViewparams = jsonViewParamsList[index]
        vc?.jsonViewParams = jsonViewparams
        vc?.preferredContentSize = CGSize.init(width: self.view.frame.size.width/CGFloat(noOfFragments), height: self.view.frame.size.height)
        var frame = CGRect.init(x: 0, y: 0, width: 0, height: 0)
        frame.size = (vc?.preferredContentSize)!
        vc?.view.frame = frame
        vc?.handlerClose = removeJsonViewAtIndex(index:inlcudingParent:)
        vc?.didSelectRowAt = didSelectRowAtJsonView(jsonViewParams:)
        //            vc.breadCrumb = ["\(key) : \(logger.message)"]
        return vc!
    }
    
    fileprivate func removeJsonFor(_ isFound: inout [JsonViewParams], _ allTree: [String], _ vc: JsonViewerViewController?) {
        isFound = jsonViewParamsList.filter{allTree.contains($0.tree)}.sorted{$0.pageIndex < $1.pageIndex}.reversed()
        if isFound.count > 0{
            for (json) in isFound{
                jsonViewParamsList.remove(at: json.pageIndex)
                let vcn = jsonViewControllerMapper[json.pageIndex]
                jsonViewControllerMapper[(vcn?.jsonViewParams.pageIndex)!] = nil
                adjustIndexForDeletion(json.pageIndex)
                initializeAllViewControllers()
            }
        }
        vc?.spinner.stopAnimating()
        treeChild[(vc?.jsonViewParams.tree)!] = nil
    }
    
    func removeJsonViewAtIndex(index: Int,inlcudingParent : Bool){
        if jsonViewControllerMapper.keys.sorted().contains(index){
            let vc = jsonViewControllerMapper[index]
            let allTree  = getAllChild(tree: (vc?.jsonViewParams.tree)!)
            var isFound : [JsonViewParams] = []
            if !(inlcudingParent){
                if allTree.count>0{
                    removeJsonFor(&isFound, allTree, vc)
                }
                else{
                    expandAll((vc?.jsonViewParams)!, completion: { status in
                        print(status)
                        vc?.spinner.stopAnimating()
                    })
                }
                vc?.setUpUI()
                self.indexSelected = index
            }
            else{
                var includeParent : [String] = []
                includeParent.append(contentsOf: allTree)
                includeParent.append((vc?.jsonViewParams.tree)!)
                removeJsonFor(&isFound, includeParent, vc)
            }
        }
        if index > 1{
            self.indexSelected = index-1
        }
        else{
            self.indexSelected = 0
        }
        refresh()
        if let breadCrumb = addBreadCrumbHandler{
            breadCrumb(self.indexSelected,jsonViewParamsList.map{$0.parent})
        }
    }
    
    func getAllChild(tree:String) -> [String]{
        var children : [String] = []//[tree]
        if treeChild[tree] != nil{
            for child in (treeChild[tree])!{
                children.append(child)
                children.append(contentsOf: getAllChild(tree: child))
            }
        }
        return children
    }
    
    fileprivate func createNewColor(_ newTree: String) {
        let treeHeight = newTree.components(separatedBy: "->")
        treeColor[newTree] = colors[(treeHeight.count%7)]
        treeChildColor[newTree] = colors[((treeHeight.count+1)%7)]
    }
    
    fileprivate func adjustIndexForInsertion(_ pageIndex: Int) {
        var temp = jsonViewParamsList.sorted{$0.pageIndex < $1.pageIndex}
        for (index,var jsonParam) in temp.enumerated().reversed(){
            if jsonParam.pageIndex > pageIndex{
                jsonParam.pageIndex = jsonParam.pageIndex+1
                jsonViewControllerMapper[pageIndex+1] = jsonViewControllerMapper[pageIndex]
                temp[index] = jsonParam
            }
        }
        jsonViewParamsList = temp
    }
    
    fileprivate func adjustIndexForDeletion(_ pageIndex: Int) {
        var temp = jsonViewParamsList.sorted{$0.pageIndex < $1.pageIndex}
        for (index,var jsonParam) in temp.enumerated().reversed(){
            if jsonParam.pageIndex > pageIndex{
                jsonParam.pageIndex = jsonParam.pageIndex-1
                jsonViewControllerMapper[pageIndex-1] = jsonViewControllerMapper[pageIndex]
                temp[index] = jsonParam
            }
        }
        jsonViewParamsList = temp
    }
    
    func initializeAllViewControllers(){
        for (jsonParam) in jsonViewParamsList.enumerated(){
            let _ = getViewControllerAtIndex(index: jsonParam.element.pageIndex)
        }
    }
    
    fileprivate func insertNewNode(_ jsonViewParams: JsonViewParams, parent: String)->JsonViewParams {
        let childrenCount = getAllChild(tree: (jsonViewParams.tree)).count
        var insertIndex = jsonViewParams.pageIndex+childrenCount+1
        let tree = jsonViewParams.tree
        let isFound = jsonViewParamsList.filter{$0.tree==tree}
        let newTree = jsonViewParams.tree+"\n\t->\(parent)"
        let isNewTreeFound = jsonViewParamsList.filter{$0.tree==newTree}
        if isNewTreeFound.count == 0{
            if !treeColor.keys.contains(newTree){
                createNewColor(newTree)
            }
            if let children = treeChild[tree]{
                var child = children
                child.append(newTree)
                treeChild[tree] = child
            }
            else{
                treeChild[tree] = [newTree]
            }
            var color = treeColor[newTree]
            if isFound.count>0{
                insertIndex = (isFound.last?.pageIndex)!+childrenCount+1
                color = treeChildColor[tree]
            }
            let parentColor = treeColor[tree]
            if(insertIndex > jsonViewParamsList.count){
                insertIndex = jsonViewParamsList.count
            }
            adjustIndexForInsertion((isFound.last?.pageIndex)!+childrenCount)
            let newjsonViewParams = JsonViewParams.init(list: jsonViewParams.list, filters: [], sortFilters: [], pageIndex: insertIndex, selectedIndexPath: nil, collapseSectionArray: [], heading: jsonViewParams.heading,parent: parent, tree : newTree, color : color!, parentColor : parentColor!)
            
            jsonViewParamsList.insert(newjsonViewParams, at: insertIndex)
            jsonViewControllerMapper[insertIndex] = nil
            initializeAllViewControllers()
            //jsonViewParamsList.append(newjsonViewParams)
            
            if self.indexSelected != jsonViewParams.pageIndex+childrenCount+1{
                self.indexSelected = jsonViewParams.pageIndex+childrenCount+1
            }
            return newjsonViewParams
        }
        else{
            self.indexSelected = (isNewTreeFound.first?.pageIndex)!
            return isNewTreeFound.first!
        }
    }
    
    func didSelectRowAtJsonView(jsonViewParams:JsonViewParams){
        
//        if jsonViewParams.pageIndex < jsonViewParamsList.count-1{
//            jsonViewParamsList.removeLast(jsonViewParamsList.count-1-jsonViewParams.pageIndex)
//            for (index,element) in jsonViewControllerMapper.keys.sorted().enumerated().reversed(){
//                jsonViewControllerMapper[element]?.removeFromParentViewController()
//                jsonViewControllerMapper[element] = nil
//                if index == jsonViewParams.pageIndex{
//                    break
//                }
//            }
//        }
        
        //overwrite existing
        jsonViewParamsList[jsonViewParams.pageIndex].selectedIndexPath = jsonViewParams.selectedIndexPath
        jsonViewParamsList[jsonViewParams.pageIndex].collapseSectionArray = jsonViewParams.collapseSectionArray
        jsonViewParamsList[jsonViewParams.pageIndex].filters = jsonViewParams.filters
        jsonViewParamsList[jsonViewParams.pageIndex].sortFilters = jsonViewParams.sortFilters
        var parent = ""
        let existing =  jsonViewParamsList[jsonViewParams.pageIndex]
        if existing.list.count > 1{
                let key = jsonViewParams.filters[(jsonViewParams.selectedIndexPath?.row)!]
            parent = "\(jsonViewParams.parent)(\((jsonViewParams.selectedIndexPath?.section)!+1)/\(existing.list.count))-\(key)"
        }
        else{
            parent = "\(jsonViewParams.heading)"
        }
        
        let insertedNode = insertNewNode(jsonViewParams, parent: parent)
        self.indexSelected = insertedNode.pageIndex
        if let breadCrumb = addBreadCrumbHandler{
            breadCrumb(self.indexSelected,jsonViewParamsList.map{$0.parent})
        }
        self.refresh()
    }
    
    func refresh(){
        self.spinner.stopAnimating()
        self.jsonCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if self.jsonViewParamsList.count > 0{
                self.jsonCollectionView.scrollToItem(at: IndexPath.init(row: self.indexSelected, section: 0), at: .left, animated: true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.jsonViewTypeSegment.selectedSegmentIndex == 0{
            return jsonViewParamsList.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : JsonCollectionViewCell = self.jsonCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! JsonCollectionViewCell
        let vc = getViewControllerAtIndex(index: indexPath.item)
        if jsonViewTypeSegment.selectedSegmentIndex == 1{
            vc.viewType = .Text
        }
        else if jsonViewTypeSegment.selectedSegmentIndex == 2{
            vc.viewType = .Tree
        }
        else{
            vc.viewType = .Table
        }
        vc.showSelectedView()
        let allTree  = getAllChild(tree: (vc.jsonViewParams.tree))
        vc.isExpandedButton.isSelected = true
        if allTree.count>0{
            vc.isExpandedButton.isSelected = false
        }
        vc.setUpUI()
        if indexPath.item == self.jsonViewParamsList.count-1{
//            vc.autoSelect()
        }
        cell.addSubview(vc.view)
        cell.layer.borderColor = UIColor.clear.cgColor
        if indexPath.item == self.indexSelected{
            cell.layer.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            cell.layer.borderWidth = 1.5
            cell.layer.cornerRadius = 5
        }
        cell.layer.masksToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item % noOfFragments == 0,noOfFragments>1{
            return CGSize.init(width:(self.view.frame.size.width-2*(self.view.frame.size.width/CGFloat(noOfFragments))), height: self.jsonCollectionView.frame.size.height)
        }
        return CGSize.init(width:self.view.frame.size.width/CGFloat(noOfFragments), height: self.jsonCollectionView.frame.size.height)

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.indexSelected = indexPath.item
        if let breadCrumb = addBreadCrumbHandler{
            breadCrumb(self.indexSelected,jsonViewParamsList.map{$0.parent})
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showScreeshot"{
            let sv = segue.destination as! ScreenshotViewController
            var images : [UIImage] = []
            for(_,key) in  jsonViewControllerMapper.keys.sorted().enumerated(){
                if let vc = jsonViewControllerMapper[key]{
                    images.append(vc.combineTreeAndTable())
                }
            }
            sv.images = images
        }
    }
    

}
