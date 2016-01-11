//
//  ALImageGallery.swift
//  ALImageGallery Poject
//
//  Created by Aldo Rangel on 12/26/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Aldo Pedro Rangel Montiel
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

public class ALImageGalleryViewController:UIViewController, UIPageViewControllerDataSource, UIScrollViewDelegate {
    /// The images that the gallery contains
    public var images:[UIImage] = []
    /// Either the gallery should response to being dragged to top or not
    public var dismissWhenSlidesUp:Bool = true
    /// The index in which the gallery should open first
    public var selectedIndex:Int = 0
    /// A function to be executed once the Gallery is dismissed
    public var onDismissViewController:(() -> Void)? = nil
    /// A function to be executed once the Gallery is dragged to top
    public var onMovedToTop:Optional<() -> Void> = nil
    /// The close button title
    public var closeButtonTitle:String = "Close"
    var mainView:UIView!;
    var pageViewController:UIPageViewController!
    var scrollViewActive = false
    var currentIndex:Int = 0
    var currentViewController: UIViewController!;
    var closeButton:UIButton!
    
    // MARK: - UIViewController overrides
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if(images.count==0){
            return;
        }
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
        for v  in  self.view.subviews {
            v.backgroundColor = UIColor.clearColor()
        }
        
    }
    
    override public func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        createMainView()
        createPageController()
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1)
        })
    }
    
    // MARK: - pageViewController related code
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if scrollViewActive {
            return nil
            
        }else {
            var index:Int = images.indexOf(((viewController.view.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
            if(index == ( images.count - 1 )){
                return nil
            }else{
                index++
                return getViewControllerForIndex(index)
            }
        }
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if scrollViewActive {
            return nil
            
        }else {
            var index:Int = images.indexOf(((viewController.view.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
            if(index == 0 ){
                return nil
            }else{
                index--
                return getViewControllerForIndex(index)
            }
        }
    }
    
    func getViewControllerForIndex( index:Int) -> UIViewController?{
        if((images.count == 0 || index >= images.count) || index<0  ){
            return nil;
        }
        
        let imageViewer: ALHelperViewController = ALHelperViewController()
        let imageView = UIImageView()
        let scrollView: UIScrollView = UIScrollView(frame: mainView.frame)
        imageViewer.view.backgroundColor = UIColor.clearColor()
        imageView.image = images[index]
        imageView.frame = mainView.frame
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        imageView.clipsToBounds = true;
        
        let singleTap = UITapGestureRecognizer(target: self, action: "handleTapGesture:" )
        let doubleTap = UITapGestureRecognizer(target: self, action: "handleDoubleTapGesture:" )
        singleTap.numberOfTapsRequired = 1
        singleTap.requireGestureRecognizerToFail(doubleTap)
        doubleTap.numberOfTapsRequired = 2
        
        scrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addSubview(imageView)
        scrollView.backgroundColor = UIColor.clearColor()
        
        imageViewer.gallery = self
        imageViewer.view.addSubview(scrollView)
        imageViewer.scrollView = scrollView
        imageViewer.imageView = imageView
        
        currentIndex = index
        return imageViewer
    }
    
    
    // MARK: - UIScrollView Functions
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if(scrollView.zoomScale != 1.0){
            return
        }
        let scrollView: UIScrollView = pageViewController.viewControllers?.first!.view?.subviews[0] as! UIScrollView
        let imageView:UIImageView = scrollView.subviews[0] as! UIImageView
        
        mainView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        scrollView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        scrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)
        scrollView.center = view.center
        imageView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        imageView.center = view.center
    }
    
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        scrollViewActive = true
        pageViewController.dataSource = nil
        if scale == 1.0 {
            scrollViewActive = false
            pageViewController.dataSource = self
        }
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0] as
        UIView
        
    }
    
    
    // MARK: - Tap gestures Functions
    
    func handleTapGesture(sender: UITapGestureRecognizer!){
        removeGallery()
    }
    
    func handleDoubleTapGesture(sender: UITapGestureRecognizer){
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
    
    @IBAction func removeGallery(){
        let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        if(orientation.isLandscape){
            
            let value = UIInterfaceOrientation.Portrait.rawValue
            UIDevice.currentDevice().setValue(value, forKey: "orientation")
            //return
        }
        scrollViewActive = false
        
        
        self.dismissViewControllerAnimated(false, completion: { () -> Void in
            if(self.onDismissViewController != nil ){
                
                self.onDismissViewController!()
                
            }
        })
        
    }
    
    func orientationChanged(){
        if(pageViewController != nil){
            let scrollView: UIScrollView = pageViewController.viewControllers?.first!.view?.subviews[0] as! UIScrollView
            scrollView.setZoomScale(1.0, animated: false)
            scrollView.backgroundColor = UIColor.blackColor()//
            let imageView:UIImageView = scrollView.subviews[0] as! UIImageView
            
            mainView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
            scrollView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
            scrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)
            scrollView.center = view.center
            imageView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
            imageView.center = view.center
            
            let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
            pageViewController.viewControllers?.first
            
            closeButton.frame = CGRectMake(mainView.frame.size.width - 74, 50, 60, 30)
            closeButton.enabled = !orientation.isLandscape
            
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("resetPager"), userInfo: nil, repeats: false)
            
        }
        
    }
    
    func resetPager(){
        
        let index:Int = images.indexOf(((pageViewController.viewControllers!.first!.view?.subviews[0] as! UIScrollView).subviews[0] as! UIImageView ).image!)!
        var temp:[UIViewController] = []
        temp.append(getViewControllerForIndex(index)!)
        pageViewController.setViewControllers(temp, direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion:nil)
    }
    
    func createMainView(){
        //Configure main view
        mainView = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        mainView.layer.borderColor = UIColor.redColor().CGColor
        mainView.layer.borderWidth = 0
        
        self.view.addSubview(mainView)
    }
    
    func createPageController(){
        var temp:[UIViewController] = []
        temp.append(getViewControllerForIndex(selectedIndex)!)
        
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.view.frame  = mainView.frame
        pageViewController.view.layer.borderWidth = 0
        pageViewController.view.layer.borderColor = UIColor.greenColor().CGColor
        pageViewController.setViewControllers(temp, direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion:nil)
        pageViewController.view.backgroundColor = UIColor.clearColor()
        pageViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(pageViewController)
        self.mainView.addSubview(pageViewController.view)
        self.mainView.clipsToBounds = true
        closeButton = UIButton(frame: CGRect(x: mainView.frame.size.width - 74, y: 50, width: 60, height: 30))
        closeButton.titleLabel?.font = UIFont(name: "Roboto-Bold", size: 13)
        closeButton.titleLabel?.textColor = UIColor.whiteColor()
        closeButton.setTitle(closeButtonTitle, forState: UIControlState.Normal)
        closeButton.layer.cornerRadius = 5
        closeButton.layer.borderWidth = 1
        closeButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        closeButton.layer.borderColor = UIColor.whiteColor().CGColor
        closeButton.addTarget(self, action: "removeGallery", forControlEvents: .TouchUpInside)
        self.mainView.addSubview(closeButton)
        self.mainView.bringSubviewToFront(closeButton)
    }
    
    
}


//MARK: - ALHelperViewController
internal class ALHelperViewController: UIViewController, UIGestureRecognizerDelegate{
    var gallery: ALImageGalleryViewController!;
    var scrollView:UIScrollView!
    var imageView:UIImageView!
    let screenYCenter = UIScreen.mainScreen().bounds.height / 2
    
    override func viewWillAppear(animated: Bool) {
        gallery.currentViewController = self
        scrollView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        imageView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        scrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)
        scrollView.center = view.center
        imageView.center = view.center
        
        for v  in  self.view.subviews {
            v.backgroundColor = UIColor.clearColor()
            
        }
        
    }
    
    override func viewDidLoad() {
        
        let dragRecognizer = UIPanGestureRecognizer(target: self, action: "handleDragGesture:" )
        dragRecognizer.maximumNumberOfTouches = 1
        dragRecognizer.minimumNumberOfTouches = 1
        dragRecognizer.delegate = self
        self.view.addGestureRecognizer(dragRecognizer)
        
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let translation = (gestureRecognizer as! UIPanGestureRecognizer).translationInView(self.view.superview!)
        if (scrollView.zoomScale != 1){
            return false
        }
        if(abs(translation.x) > 3 && abs(translation.y) < 85){
            
            return false
            
        }
        
        return true
    }
    
    func handleDragGesture(sender: UIPanGestureRecognizer){
        if (scrollView.zoomScale != 1 || !gallery.dismissWhenSlidesUp){
            return
        }
        let translation  = sender.translationInView(self.view.superview!)
        self.scrollView.center = CGPointMake(self.view.center.x , self.view.center.y + translation.y)
        switch (sender.state) {
        case UIGestureRecognizerState.Began:
            break;
        case UIGestureRecognizerState.Changed:
            
            self.gallery.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: self.scrollView.center.y / self.screenYCenter)
            
            break;
        case UIGestureRecognizerState.Ended:
            let scrollCenterY = self.scrollView.center.y
            if(scrollCenterY <= 180){
                if(self.gallery.onMovedToTop != nil){
                    self.gallery.onMovedToTop!()
                    
                }
                self.gallery.removeGallery()
            }else{
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.scrollView.center = self.view.center
                    self.gallery.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1)
                    
                })
            }
            break;
        default:
            break;
        }
    }
}