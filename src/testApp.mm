#include "testApp.h"
#include <Cocoa/Cocoa.h>

extern "C" {
#include "macGlutfix.h"
}

//--------------------------------------------------------------
void testApp::setup(){
    
    dotSpacing = 12;
    dotRadius = 3;
    dotPositionNoiseScale = 80;
    dotPositionNoiseAmount = 0.75;
    dotBrightnessFactor = 1.0;
    dotDepth = 0;
    
    imageSource = 0;
    
    fogDensity = 0.0;
    
    camWidth 		= 800;	// try to grab at this size.
	camHeight 		= 600;
	
    ofSetFrameRate(60);
    
    //ofxFensterManager::get()->setPrimaryWindow(ofxFensterManager::get()->getWindowById(0));
    
    captureFenster=ofxFensterManager::get()->createFenster(ofGetScreenWidth() - 1000, ofGetScreenHeight() - 1000, 400, 300, OF_WINDOW);
    
    captureFensterListener = new captureWindow();
    
    captureFenster->addListener(captureFensterListener); //this line works because testApp does not extend ofBaseApp, but ofxFensterListener
    
    //start server
	OFX_REMOTEUI_SERVER_SETUP(10000);
    
	//expose vars to ofxRemoteUI server, AFTER SETUP!
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotSpacing, 5, ofGetWidth());
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotRadius, 0, ofGetWidth());
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotPositionNoiseScale, 0, ofGetWidth()/5.);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotPositionNoiseAmount, 0, 1.0);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotBrightnessFactor, 0, 1.0);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(dotDepth, -1.0, 1.0);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(resetCam);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(fogDensity, 0, .01);
	OFX_REMOTEUI_SERVER_SHARE_PARAM(imageSource, 0, 1);
    
    ofEnableSmoothing();
    
    cam.reset();
    
    ofxDisplayList displays = ofxDisplayManager::get()->getDisplays();
    ofxDisplay* disp = displays[0];
    if(displays.size() > 1){
        disp = displays[1];
        ofxFensterManager::get()->getWindowById(0)->move(disp->x, disp->y);
        ofxFensterManager::get()->getWindowById(0)->setFullscreen(true);
    }
    
    BringAppToFront();
    
    //    cam.enableOrtho();
    
}

//--------------------------------------------------------------
void testApp::update(){
    
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    bool upload = false;
    
    int dataWidth, dataHeight;
    
    if(imageSource == 0){
        if(!vidGrabber.isInitialized()) {
            vidGrabber.setVerbose(true);
            vidGrabber.setDeviceID(0);
            vidGrabber.setDesiredFrameRate(60);
            vidGrabber.initGrabber(camWidth,camHeight);
            captureFenster->setWindowTitle("Camera Capture");
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
    
    if (imageSource == 1) {
        if(captureFenster->getWindowTitle() != "Screen Capture"){
            captureFenster->setWindowTitle("Screen Capture");
        }
        
        dataWidth = captureFensterListener->windowRect.getWidth();
        dataHeight = captureFensterListener->windowRect.getHeight();
        
        data = pixelsBelowWindow(captureFensterListener->windowRect.x,captureFensterListener->windowRect.y,dataWidth,dataHeight);
        
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
        if (captureFensterListener->tex.getWidth() != dataWidth || captureFensterListener->tex.getHeight() != dataHeight) {
            
            captureFensterListener->tex.allocate(dataWidth, dataHeight, GL_RGB);
        }
        
        if (data!= NULL) captureFensterListener->tex.loadData(data, dataWidth, dataHeight, GL_RGB);
        
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
    
    [pool drain];

	float dt = 0.016666;
    OFX_REMOTEUI_SERVER_UPDATE(dt);
    
}

//--------------------------------------------------------------
void testApp::draw(){
    
    ofBackground(0);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
	//cam.begin();
    glFogi(GL_FOG_MODE, GL_EXP2);
    glFogf(GL_FOG_DENSITY, fogDensity);
    glEnable(GL_FOG);
    for (vector<LightDot*>::iterator it = dots.begin() ; it != dots.end(); ++it) {
        //(*it)->lookAt(cam);
        (*it)->draw();
    }
	//cam.end();
    
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
        ofxFensterManager::get()->getWindowById(0)->toggleFullscreen();
        cam.reset();
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
    
}

//--------------------------------------------------------------
void testApp::gotMessage(ofMessage msg){
    
}

//--------------------------------------------------------------
void testApp::dragEvent(ofDragInfo dragInfo){ 
    
}