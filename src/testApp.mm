#include "testApp.h"
#include <Foundation/Foundation.h>

extern "C" {
#include "macGlutfix.h"
}

#include "ofxDisplayManager.h"

//--------------------------------------------------------------
void testApp::setup(){
    
    dotSpacing = 12;
    dotRadius = 3;
    dotPositionNoiseScale = 80;
    dotPositionNoiseAmount = 0.75;
    dotBrightnessFactor = 1.0;
    dotDepth = 0;
    blurStrength = 0;
    blurGain = 1.0;
    doScreenShot = false;
    fullScreen = false;
    isFullScreen = false;
    
    vector<ofVideoDevice> vidDevices = vidGrabber.listDevices();
    for(int i=0; i < vidDevices.size(); i++){
        ofVideoDevice device = vidDevices[i];
        cout << device.deviceName << endl;
        cout << device.hardwareName << endl;
        vector<ofVideoFormat> deviceFormats = device.formats;
        for (int j=0; j < deviceFormats.size(); j++) {
            ofVideoFormat f = deviceFormats[j];
            cout << " - " << f.width << "x" << f.height << endl;
        }
        
    }
    
    imageSource = IMAGE_SOURCE_CAMERA;
    
    fogDensity = 0.0;
    
    camWidth 		= 800;	// try to grab at this size.
	camHeight 		= 600;

    blur.setup(ofGetWidth(), ofGetHeight());
    
    ofSetFrameRate(60);
    
    ofxFensterManager::get()->setupWindow(&captureFenster);
    captureFenster.setWindowPosition(ofGetScreenWidth() - 1000, ofGetScreenHeight() - 1000);
    captureFenster.setWindowShape(400, 300);
    
    //start server
	OFX_REMOTEUI_SERVER_SETUP(10000);
    
	//expose vars to ofxRemoteUI server, AFTER SETUP!
    
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_GROUP("Dots");
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_COLOR(ofColor::white);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotSpacing, 5, ofGetWidth());
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotRadius, 0, ofGetWidth());
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotPositionNoiseScale, 0, ofGetWidth()/5.);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotPositionNoiseAmount, 0, 1.0);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotBrightnessFactor, 0, 1.0);
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_GROUP("Blur");
	OFX_REMOTEUI_SERVER_SHARE_PARAM(blurStrength, 0, 1.25);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(blurGain, 1.0, 10);
//	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotDepth, -1.0, 1.0);
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_GROUP("Source");
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_COLOR(ofColor::lightGray);
    vector<string> sourceMenuItems;
	sourceMenuItems.push_back("Camera");sourceMenuItems.push_back("Screen");
	OFX_REMOTEUI_SERVER_SHARE_ENUM_PARAM(imageSource, IMAGE_SOURCE_CAMERA, IMAGE_SOURCE_SCREEN, sourceMenuItems);
    OFX_REMOTEUI_SERVER_SET_UPCOMING_PARAM_GROUP("Screenshot");
	OFX_REMOTEUI_SERVER_SHARE_PARAM(doScreenShot);

//	OFX_REMOTEUI_SERVER_SHARE_PARAM(resetCam);
//	OFX_REMOTEUI_SERVER_SHARE_PARAM(fogDensity, 0, .01);
    
//	OFX_REMOTEUI_SERVER_SHARE_PARAM(imageSource, 0, 1);
  
    OFX_REMOTEUI_SERVER_LOAD_FROM_XML();
    
    OFX_REMOTEUI_SERVER_GET_INSTANCE()->setCallback(testApp::serverCallback); // (optional!)
    
    OFX_REMOTEUI_SERVER_SET_DRAWS_NOTIF(false);
    
    ofEnableSmoothing();
    
    cam.reset();
    
    // Main window goes fullscreen if on secondary display
    
    ofxDisplayList displays = ofxDisplayManager::get()->getDisplays();
    ofxDisplay* disp = displays[0];
    if(displays.size() > 1){
        disp = displays[1];
        ofxFensterManager::get()->getMainWindow()->setWindowPosition(disp->x+10, disp->y+10);
        ofxFensterManager::get()->getMainWindow()->setFullscreen(true);
        fullScreen = true;
        isFullScreen= true;
    }
    
    //BringAppToFront();
    
    //    cam.enableOrtho();
    
}

//--------------------------------------------------------------
void testApp::update(){
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    blur.setScale(blurStrength);
    blur.setBrightness((blurGain==1.0)?0.0:blurGain);
	//blur.setRotation(ofMap(mouseY, 0, ofGetHeight(), -PI, PI));

    bool upload = false;
    
    int dataWidth, dataHeight;
    
    captureFenster.imageSource = imageSource;
    
    if(imageSource == IMAGE_SOURCE_CAMERA){
        if(!vidGrabber.isInitialized()) {
            vidGrabber.setVerbose(true);
            vidGrabber.setDeviceID(vidGrabber.listDevices().size()-1);
            vidGrabber.setDesiredFrameRate(60);
            vidGrabber.initGrabber(camWidth,camHeight);
            captureFenster.setWindowTitle("Camera Capture");
            captureFenster.setWindowShape(camWidth/2, camHeight/2);
        }
        vidGrabber.update();
        
        if (vidGrabber.isFrameNew()){
            
            dataWidth = camWidth;
            dataHeight = camHeight;
            data = vidGrabber.getPixels();
            upload = true;
            
        }
        
    } else if (vidGrabber.isInitialized()){
        vidGrabber.close();
    }
    
    if (imageSource == IMAGE_SOURCE_SCREEN) {
        
        captureFenster.setWindowTitle("Screen Capture");
        
        dataWidth = captureFenster.getWidth();
        dataHeight = captureFenster.getHeight();
        
        data = pixelsBelowWindow(captureFenster.getWindowPosition().x,captureFenster.getWindowPosition().y,dataWidth,dataHeight);
        
        // now, let's get the R and B data swapped, so that it's all OK:
        
        int j = 0;
        
        for (int i = 0; i < dataWidth*dataHeight; i++){
            
            unsigned char r1 = data[i*4]; // mem A
            
            data[j*3]   = data[i*4+1];
            data[j*3+1] = data[i*4+2];
            data[j*3+2] = data[i*4+3];
            
            j++;
            
        }
        
        upload = true;
        
    }
    
    if (upload) {
        if (captureFenster.tex.getWidth() != dataWidth || captureFenster.tex.getHeight() != dataHeight) {
            captureFenster.tex.allocate(dataWidth, dataHeight, GL_RGB);
        }
        
        if (data!= NULL) captureFenster.tex.loadData(data, dataWidth, dataHeight, GL_RGB);
        
        ofRectangle screenRect = ofGetWindowRect();
        
        // inset the rect to make a margin
        // screenRect.set(screenRect.x+dotSpacing, screenRect.y+dotSpacing, screenRect.width - (dotSpacing*2),  screenRect.height - (dotSpacing*2));
        
        // move the rect to a centered coordinate sysstem for the camera.
        // screenRect.translate(-screenRect.width*0.5, -screenRect.height*0.5);
        
        area.set(screenRect);
        
        createDots(area, dotSpacing);
        if (data!= NULL) updateDots(data, dataWidth, dataHeight);
        
    }
    
    if (resetCam) {
        cam.reset();
        resetCam = false;
    }

	float dt = 0.016666;

    OFX_REMOTEUI_SERVER_UPDATE(dt);

    if(doScreenShot){
        screenShot();
    }
    doScreenShot = false;
    OFX_REMOTEUI_SERVER_PUSH_TO_CLIENT();

    [pool drain];
    
    if(fullScreen && !isFullScreen){
        ofxFensterManager::get()->getMainWindow()->ofAppBaseWindow::setFullscreen(true);
        isFullScreen=fullScreen;
    }

    if(!fullScreen && isFullScreen){
        ofxFensterManager::get()->getMainWindow()->ofAppBaseWindow::setFullscreen(false);
        isFullScreen=fullScreen;
    }

}

//--------------------------------------------------------------
void testApp::draw(){
    ofBackground(0);
    ofSetColor(255,255);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
	//cam.begin();
    
    blur.begin();
    ofBackground(0);

//    glFogi(GL_FOG_MODE, GL_EXP2);
//    glFogf(GL_FOG_DENSITY, fogDensity);
//    glEnable(GL_FOG);
    for (vector<LightDot*>::iterator it = dots.begin() ; it != dots.end(); ++it) {
        //(*it)->lookAt(cam);
        (*it)->draw();
    }
    blur.end();
	//cam.end();
    
    ofSetColor(255,255);
    ofBackground(0);

    blur.draw();

	//ofDrawBitmapString(ofToString((int) ofGetFrameRate()), 10, 20);

    
}

void testApp::createDots(ofRectangle area, float spacing){
    
    while(!dots.empty()) delete dots.back(), dots.pop_back();
    
    dots.clear();
    
    for (float x = area.x; x < (area.x + area.width); x += spacing) {
        for (float y = area.y; y < (area.y + area.height); y += spacing) {
            LightDot * newDot = new LightDot();
            
            float noiseX = (0.5-ofNoise(x*dotPositionNoiseScale/area.width, y*dotPositionNoiseScale/area.height, x*dotPositionNoiseScale/area.width)) * dotPositionNoiseAmount*dotSpacing;
            
            float noiseY = (0.5-ofNoise(x*dotPositionNoiseScale/area.width, y*dotPositionNoiseScale/area.height, y*dotPositionNoiseScale/area.height)) * dotPositionNoiseAmount*dotSpacing;
            
            newDot->setPosition(x+noiseX, y+noiseY, 0);
            
            dots.push_back(newDot);
        }
    }
    
}

void testApp::updateDots(unsigned char * data, int width, int height){
    
    for (vector<LightDot*>::iterator it = dots.begin() ; it != dots.end(); ++it) {
        
        
        ofRectangle imageRect = ofRectangle(0,0,width,height);
        
        ofVec2f imagePosition = ofVec2f(
                                        fminf((abs((*it)->getX()-area.x) / area.width) * width, width-1) ,
                                        fminf((abs((*it)->getY()-area.y) / area.height) * height, height-1)
                                        );
        
        //*
        if(imageRect.getAspectRatio() > area.getAspectRatio()){
            // offset and scale the x axis when it is less than the width;
            imagePosition.x *= (area.getAspectRatio()/imageRect.getAspectRatio());
            imagePosition.x -= ((width * (area.getAspectRatio()/imageRect.getAspectRatio())) - width) * 0.5;
        } else {
            // offset and scale the y axis when it is less than the height;
            imagePosition.y /= (area.getAspectRatio()/imageRect.getAspectRatio());
            imagePosition.y -= ((height * (imageRect.getAspectRatio())/area.getAspectRatio()) - height) * 0.5;
        }
        //*/
        
        
        int pixelIndex = ( round(imagePosition.x) + round(imagePosition.y) * width ) * 3;
        
        (*it)->color.set(data[pixelIndex], data[pixelIndex+1], data[pixelIndex+2]);
        (*it)->color.a = 255 * dotBrightnessFactor;
        (*it)->setPosition((*it)->getX(), (*it)->getY(), (127-(*it)->color.getBrightness())*dotDepth);
        
        (*it)->radius = dotRadius;
        
    }
    
}


//--------------------------------------------------------------
void testApp::keyPressed(int key, ofxFenster* win){
    
}

//--------------------------------------------------------------
void testApp::keyReleased(int key, ofxFenster* win){
    
    if (key == 'f') {
        fullScreen!=fullScreen;
    }
    
}

void testApp::keyReleased(int key){
    
    if (key == 'f') {
        fullScreen!=fullScreen;
    }
    
}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y, ofxFenster* win ){
    mouseMoved(x, y);
}

void testApp::mouseMoved(int x, int y){
    
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){
    
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){
    
}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){
    
}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){
    cam.reset();
    blur.setup(w, h);
}

//--------------------------------------------------------------
void testApp::gotMessage(ofMessage msg){
    
}

//--------------------------------------------------------------
void testApp::dragEvent(ofDragInfo dragInfo){ 
    
}

//define a callback method to get notifications of client actions
void testApp::serverCallback(RemoteUIServerCallBackArg arg){
    
	switch (arg.action) {
		case CLIENT_CONNECTED: cout << "CLIENT_CONNECTED" << endl; break;
		case CLIENT_DISCONNECTED: cout << "CLIENT_DISCONNECTED" << endl; break;
		case CLIENT_UPDATED_PARAM: cout << "CLIENT_UPDATED_PARAM: "<< arg.paramName << ": ";
			arg.param.print();
			break;
		case CLIENT_DID_SET_PRESET: cout << "CLIENT_DID_SET_PRESET" << endl; break;
		case CLIENT_SAVED_PRESET: cout << "CLIENT_SAVED_PRESET" << endl; break;
		case CLIENT_DELETED_PRESET: cout << "CLIENT_DELETED_PRESET" << endl; break;
		case CLIENT_SAVED_STATE: cout << "CLIENT_SAVED_STATE" << endl; break;
		case CLIENT_DID_RESET_TO_XML: cout << "CLIENT_DID_RESET_TO_XML" << endl; break;
		case CLIENT_DID_RESET_TO_DEFAULTS: cout << "CLIENT_DID_RESET_TO_DEFAULTS" << endl; break;
		default:break;
	}
}

void testApp :: screenShot ()
{
    string filePath = "~/Desktop/";
    string fileExt = ".png";
	string fileName = "PixelScope\\ Shot\\ ";
    
    string timeStr = ofToString(ofGetYear()) + "-" + ofToString(ofGetMonth()) + "-" + ofToString(ofGetDay()) + "\\ " + ofToString(ofGetHours()) + "-" + ofToString(ofGetMinutes()) + "-" + ofToString(ofGetSeconds());
    
    string shPath;
	shPath = "/usr/sbin/screencapture";
    
    shPath = shPath + " " + filePath + fileName + "1\\ " + timeStr + fileExt + " " + filePath + fileName + "2\\ " + timeStr + fileExt;
	   
	char *shPathChar;
    shPathChar = new char[ shPath.length() + 1 ];
	
	strcpy( shPathChar, shPath.c_str() );
	
    cout << shPathChar << endl;
    
    system(shPathChar);
    
    delete[] shPathChar;
	
	//--
    
}
