//
//  ALImageGallery.swift
//  ALImageGallery Poject
//
//  Created by Aldo Rangel on 12/26/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 - 2017 Aldo Pedro Rangel Montiel
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import Foundation

public protocol ALImageGalleryDelegate{
    
    func galleryDidReceiveTap(_ imageGallery:ALImageGalleryViewController)
    func galleryDidReceiveDoubleTap(_ imageGallery:ALImageGalleryViewController)
    func galleryDidDismiss(_ imageGallery:ALImageGalleryViewController)
    func galleryImageDragged(_ imageGallery:ALImageGalleryViewController)
    
}

open class ALImageGalleryViewController:UIViewController, UIPageViewControllerDataSource, UIScrollViewDelegate {
    /// The images that the gallery contains
    open var images:[UIImage] = []
    /// Either the gallery should response to being dragged to top or not
    open var dismissWhenSlidesUp:Bool = true
    /// Either the gallery should response to being dragged down
    open var dismissWhenSlidesDown:Bool = true
    /// Either if the current displayed image should respond to dragging
    open var canBeDragged:Bool = true
    /// The index in which the gallery should open first
    open var selectedIndex:Int = 0
    /// A function to be executed once the Gallery is dismissed
    open var onDismissViewController:(() -> Void)? = nil
    /// A function to be executed once the Gallery is dragged to top
    open var onMovedToTop:Optional<() -> Void> = nil
    /// If the close button should be hidden or not
    open var closeButtonhidden = true
    /// The close button title
    open var closeButtonTitle:String = "Close"
    /// ALImageGalleryDelegate reference
    open var delegate:ALImageGalleryDelegate?
    /// The currently displayed image index
    open var currentIndex:Int {
        get{
            return _currentIndex
        }
    }
    /// If a UIActivityViewController should appear on long press gesture
    open var showActivityVCOnLongPress = true
    
    fileprivate var _currentIndex:Int = 0
    fileprivate var mainView:UIView!;
    fileprivate var pageViewController:UIPageViewController!
    fileprivate var scrollViewActive = false
    fileprivate var createdView = false
    var currentViewController: UIViewController!;
    var closeButton:UIButton!
    
    // MARK: - Initializers
    
    public init(images:[UIImage]){
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience public init (images:[UIImage], selectedIndex:Int){
        self.init(images: images)
        self.selectedIndex = selectedIndex
        
    }
    convenience public init (images:[UIImage], delegate:ALImageGalleryDelegate){
        self.init(images: images)
        self.delegate = delegate
        
    }
    convenience public init (images:[UIImage], selectedIndex:Int, delegate:ALImageGalleryDelegate){
        self.init(images: images, selectedIndex: selectedIndex)
        self.delegate = delegate
        
    }
    
    /// Required NSCoder Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - UIViewController overrides
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        if(images.count==0){
            return;
        }
        for subview  in  self.view.subviews {
            subview.backgroundColor = UIColor.clear
        }
        
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1)
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !createdView{
            createdView = true
            createMainView()
            createPageController()
        }
        orientationChanged()
    }
    
    // MARK: - pageViewController related code
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if scrollViewActive {
            return nil
            
        }else {
            var index:Int = images.index(of: ((viewController.view.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
            if(index == ( images.count - 1 )){
                return nil
            }else{
                index += 1
                return getViewControllerForIndex(index)
            }
        }
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if scrollViewActive {
            return nil
            
        }else {
            var index:Int = images.index(of: ((viewController.view.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
            if(index == 0 ){
                return nil
            }else{
                index -= 1
                return getViewControllerForIndex(index)
            }
        }
    }
    
    func getViewControllerForIndex( _ index:Int) -> UIViewController?{
        if((images.count == 0 || index >= images.count) || index<0  ){
            return nil;
        }
        
        let imageViewer: ALHelperViewController = ALHelperViewController()
        imageViewer.gallery = self
        let imageView = UIImageView()
        let scrollView: UIScrollView = UIScrollView(frame: mainView.frame)
        imageView.image = images[index]
        imageView.frame = mainView.frame
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.clipsToBounds = true;
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ALImageGalleryViewController.handleTapGesture(_:)) )
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ALImageGalleryViewController.handleDoubleTapGesture(_:)) )
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        doubleTap.numberOfTapsRequired = 2
        
        scrollView.contentSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addSubview(imageView)
        scrollView.backgroundColor = UIColor.clear
        
        imageViewer.gallery = self
        imageViewer.scrollView = scrollView
        imageViewer.imageView = imageView
        imageViewer.view.addSubview(scrollView)
        imageViewer.view.backgroundColor = UIColor.clear
        
        _currentIndex = index
        return imageViewer
    }
    
    
    // MARK: - UIScrollView Functions
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if(scrollView.zoomScale != 1.0){
            return
        }
        let scrollView: UIScrollView = pageViewController.viewControllers?.first!.view?.subviews[0] as! UIScrollView
        let imageView:UIImageView = scrollView.subviews[0] as! UIImageView
        
        mainView.frame = CGRect(x: 0, y: statusBarHeight(), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
        scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
        scrollView.contentSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        scrollView.center = view.center
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
        imageView.center = view.center
    }
    
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewActive = true
        pageViewController.dataSource = nil
        if scale == 1.0 {
            scrollViewActive = false
            pageViewController.dataSource = self
        }
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0] as UIView
    }
    
    
    // MARK: - Tap gestures Functions
    
    @objc func handleTapGesture(_ sender: UITapGestureRecognizer!){
        delegate?.galleryDidReceiveTap(self)
        removeGallery()
    }
    
    @objc func handleDoubleTapGesture(_ sender: UITapGestureRecognizer){
        delegate?.galleryDidReceiveDoubleTap(self)
        if scrollViewActive == false {
            scrollViewActive = true;
        }else {
            scrollViewActive = false;
        }
        
        let scrollView:UIScrollView = sender.view as! UIScrollView;
        if(scrollView.zoomScale==1){
            scrollView.setZoomScale(4.0, animated: true)
        }
        else{
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    // MARK: - Helper Functions

    
    @objc func removeGallery(){
        let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        if(orientation.isLandscape){
            
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            //return
        }
        scrollViewActive = false
        
        
        self.dismiss(animated: false, completion: { () -> Void in
            if(self.onDismissViewController != nil ){
                
                self.onDismissViewController!()
                
            }
            self.delegate?.galleryDidDismiss(self)
        })
        
    }
    
    internal func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }
    
    func orientationChanged(){
        if(pageViewController != nil){
            let scrollView: UIScrollView = pageViewController.viewControllers?.first!.view?.subviews[0] as! UIScrollView
            scrollView.setZoomScale(1.0, animated: false)
            scrollView.backgroundColor = UIColor.black
            let imageView:UIImageView = scrollView.subviews[0] as! UIImageView
            
            mainView.frame = CGRect(x: 0, y: statusBarHeight(), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
            scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
            scrollView.contentSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height - statusBarHeight())
            scrollView.center = view.center
            imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())
            imageView.center = view.center
            
            let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            _ = pageViewController.viewControllers?.first
            
            closeButton.frame = CGRect(x: mainView.frame.size.width - 74, y: 40, width: 60, height: 30)
            closeButton.isEnabled = !orientation.isLandscape
            
            resetPager()
        }
        
    }
    
    func resetPager(){
        
        let index:Int = images.index(of: ((pageViewController.viewControllers!.first!.view?.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
        var temp:[UIViewController] = []
        temp.append(getViewControllerForIndex(index)!)
        pageViewController.setViewControllers(temp, direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion:nil)
        self.pageViewController.view.setNeedsLayout()
        self.view.setNeedsDisplay()
    }
    
    func createMainView(){
        //Configure main view to use the entire screen
        mainView = UIView(frame: CGRect(x: 0, y: statusBarHeight(), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight()))
        print("Main: \(mainView.frame)")
        
        self.view.addSubview(mainView)
    }
    
    func createPageController(){
        var temp:[UIViewController] = []
        temp.append(getViewControllerForIndex(selectedIndex)!)
        
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.view.frame  = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - statusBarHeight())//mainView.frame
        pageViewController.view.layer.borderWidth = 0
        pageViewController.view.layer.borderColor = UIColor.green.cgColor
        pageViewController.setViewControllers(temp, direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion:nil)
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.didMove(toParentViewController: self)
        
        self.addChildViewController(pageViewController)
        self.mainView.addSubview(pageViewController.view)
        self.mainView.clipsToBounds = true
        closeButton = UIButton(frame: CGRect(x: mainView.frame.size.width - 74, y: 50, width: 60, height: 30))
        closeButton.titleLabel?.font = UIFont(name: "Roboto-Bold", size: 13)
        closeButton.titleLabel?.textColor = UIColor.white
        closeButton.setTitle(closeButtonTitle, for: UIControlState())
        closeButton.layer.cornerRadius = 5
        closeButton.layer.borderWidth = 1
        closeButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.isHidden = closeButtonhidden
        closeButton.addTarget(self, action: #selector(ALImageGalleryViewController.removeGallery), for: .touchUpInside)
        self.mainView.addSubview(closeButton)
        self.mainView.bringSubview(toFront: closeButton)
    }
    
    
}


//MARK: - ALHelperViewController


/// Internal ciew controller that contains a single image with it's own UIScrollView, UIImageView and gesture recognizer
internal class ALHelperViewController: UIViewController, UIGestureRecognizerDelegate{
    var gallery: ALImageGalleryViewController!
    var scrollView:UIScrollView!
    var imageView:UIImageView!
    let screenYCenter = UIScreen.main.bounds.height / 2
    
    override func viewWillAppear(_ animated: Bool) {
        gallery.currentViewController = self
        scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - gallery.statusBarHeight())
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - gallery.statusBarHeight())
        scrollView.contentSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        scrollView.center = view.center
        imageView.center = view.center
        
        print("Internal Scroll: \(scrollView.frame)")
        for subview  in  self.view.subviews {
            subview.backgroundColor = UIColor.clear
            
        }
        self.view.setNeedsLayout()
        self.view.setNeedsDisplay()
        
    }
    
    override func viewDidLoad() {
        if(gallery.canBeDragged){
            
            let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ALHelperViewController.handleDragGesture(_:)) )
            dragRecognizer.maximumNumberOfTouches = 1
            dragRecognizer.minimumNumberOfTouches = 1
            dragRecognizer.delegate = self
            self.view.addGestureRecognizer(dragRecognizer)
            if(gallery.showActivityVCOnLongPress){
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ALHelperViewController.handleLongPressGesture(_:)))
                longPress.minimumPressDuration = 0.754
                self.imageView.addGestureRecognizer(longPress)
                
                self.imageView.isUserInteractionEnabled = true
            }
        }
        self.view.clipsToBounds = false
        self.view.setNeedsLayout()
        self.view.setNeedsDisplay()
        
        
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let translation = (gestureRecognizer as! UIPanGestureRecognizer).translation(in: self.view.superview!)
        if (scrollView.zoomScale != 1){
            return false
        }
        if(abs(translation.x) - 1 > abs(translation.y) ){
            
            return false
            
        }
        
        return true
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer!){
        if (scrollView.zoomScale != 1 || !self.gallery.showActivityVCOnLongPress){
            return
        }
        switch (sender.state) {
        case UIGestureRecognizerState.began:
            let activityController = UIActivityViewController(activityItems: [imageView.image], applicationActivities: [])
            activityController.popoverPresentationController?.sourceView = imageView
            activityController.popoverPresentationController?.sourceRect = imageView.bounds
            self.gallery.present(activityController, animated: true)
            break;
        case UIGestureRecognizerState.changed:
            
            break;
        case UIGestureRecognizerState.ended:
            break;
        default:
            break;
        }
    }
    
    @objc func handleDragGesture(_ sender: UIPanGestureRecognizer){
        gallery.delegate?.galleryImageDragged(gallery)
        if (scrollView.zoomScale != 1 || !gallery.dismissWhenSlidesUp){
            return
        }
        let translation  = sender.translation(in: self.view.superview!)
        self.scrollView.center = CGPoint(x: self.view.center.x , y: self.view.center.y + translation.y)
        switch (sender.state) {
        case UIGestureRecognizerState.began:
            break;
        case UIGestureRecognizerState.changed:
            
            self.gallery.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: self.scrollView.center.y / self.screenYCenter)
            
            break;
        case UIGestureRecognizerState.ended:
            let scrollCenterY = self.scrollView.center.y
            if(scrollCenterY <= (UIScreen.main.bounds.height / 2 - 25) && self.gallery.dismissWhenSlidesUp){
                if(self.gallery.onMovedToTop != nil){
                    self.gallery.onMovedToTop!()
                    
                }
                self.gallery.removeGallery()
            }else{
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.scrollView.center = self.view.center
                    self.gallery.view.backgroundColor = UIColor.black
                    
                })
            }
            
            if(scrollCenterY >= (UIScreen.main.bounds.height / 2 + 25) && self.gallery.dismissWhenSlidesDown){
                
                self.gallery.removeGallery()
            } else{
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.scrollView.center = self.view.center
                    self.gallery.view.backgroundColor = UIColor.black
                    
                })
            }
            break;
        default:
            break;
        }
    }
}
