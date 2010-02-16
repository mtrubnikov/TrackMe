//
//  MainViewController.m
//  TrackMe
//
//  Created by Steve Baker on 2/15/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "PointOfInterest.h"


@implementation MainViewController

#pragma mark -
#pragma mark properties
@synthesize myMapView;
@synthesize locationManager;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Ref Dudney Ch 24 Distance  init then autorelease (sic)  We only need to set the delegate.
    
    // TODO: If not moving, stop updating location to save power
    
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
    // notify us only if distance changes by 10 meters or more
    self.locationManager.distanceFilter = 10.0f;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager startUpdatingLocation];
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark destructors and memory cleanUp
// use cleanUp method to avoid repeating code in setView, viewDidUnload, and dealloc
- (void)cleanUp {
    [myMapView release], myMapView = nil;
    // locationManager was autoreleased.  Don't overrelease it
    //[locationManager release], locationManager = nil;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


// Release IBOutlets in setView.  
// Ref http://developer.apple.com/iPhone/library/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmNibObjects.html
//
// http://moodle.extn.washington.edu/mod/forum/discuss.php?d=3162
- (void)setView:(UIView *)aView {
    
    if (!aView) { // view is being set to nil        
        // set outlets to nil, e.g. 
        // self.anOutlet = nil;
        [self cleanUp];
    }    
    // Invoke super's implementation last    
    [super setView:aView];    
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	[self cleanUp];
}


- (void)dealloc {
    [self cleanUp];
    [super dealloc];
}

#pragma mark -
#pragma mark MKMapViewDelegate methods
// Ref Dudney sec 25.3
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    MKPinAnnotationView *annotationView = nil;
    
    if(annotation != mapView.userLocation)
    {
        // Attempt to get an unused annotationView.  Returns nil if one isn't available.
        // Ref http://developer.apple.com/iphone/library/documentation/MapKit/Reference/MKMapView_Class/MKMapView/MKMapView.html#//apple_ref/occ/instm/MKMapView/dequeueReusableAnnotationViewWithIdentifier:
        annotationView = (MKPinAnnotationView *)
        [mapView dequeueReusableAnnotationViewWithIdentifier:@"myIdentifier"];
        
        // if dequeue didn't return an annotationView, allocate a new one
        if (nil == annotationView) {
            // NSLog(@"dequeue didn't return an annotationView, allocing a new one");
            annotationView = [[[MKPinAnnotationView alloc] 
                               initWithAnnotation:annotation
                               reuseIdentifier:@"myIdentifier"]
                              autorelease];
        } else {
            NSLog(@"dequeueReusableAnnotationViewWithIdentifier returned an annotationView");
        }    
        [annotationView setPinColor:MKPinAnnotationColorPurple];
        [annotationView setCanShowCallout:YES];
        [annotationView setAnimatesDrop:YES];
    } else {
        [mapView.userLocation setTitle:@"I am here"];
    }
    return annotationView;
}


- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"lat: %f, long: %f, latDelta: %f, longDelta: %f",
          aMapView.region.center.latitude, aMapView.region.center.longitude, 
          aMapView.region.span.latitudeDelta, aMapView.region.span.longitudeDelta);
}


#pragma mark Location methods
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    // Ref Dudney Ch25 pg 470, 466, 451.  Can recenter map as on pg 451, but don't need to?  
    // In IB, checking mapView showsUserLocation will initially center map for us.
    
    // Set region based on old and new location
    CLLocationCoordinate2D theCenter = newLocation.coordinate;
    
    MKCoordinateSpan theSpan;
    // if this is the first update, oldLocation is nil
    // if this is the second update, the coordinates of newLocation may equal the coordinates of oldLocation
    if (nil == oldLocation 
        || (newLocation.coordinate.latitude == oldLocation.coordinate.latitude)
        || (newLocation.coordinate.longitude == oldLocation.coordinate.longitude)) {
        theSpan = MKCoordinateSpanMake(0.2, 0.2);
    } else {
        theSpan = MKCoordinateSpanMake(
                                       fmin(45.0, 4.0f * fabs(newLocation.coordinate.latitude - oldLocation.coordinate.latitude)),
                                       fmin(45.0, 4.0f * fabs(newLocation.coordinate.longitude - oldLocation.coordinate.longitude)));
    }
    NSLog(@"lat: %f, long: %f, latDelta: %f, longDelta: %f",
          theCenter.latitude, theCenter.longitude, theSpan.latitudeDelta, theSpan.longitudeDelta);
    MKCoordinateRegion theRegion = MKCoordinateRegionMake(theCenter, theSpan);    
    [self.myMapView setRegion:theRegion animated:YES];

    PointOfInterest *newPointOfInterest = [[PointOfInterest alloc] init];
    newPointOfInterest.title = @"POI";
    newPointOfInterest.coordinate = newLocation.coordinate;
    
    [self.myMapView addAnnotation:newPointOfInterest];
    [newPointOfInterest release], newPointOfInterest = nil;
}


@end

