#pragma once

#include "ofMain.h"
#include "LightDot.h"
#include "ofxRemoteUI.h"
#include "ofxRemoteUIServer.h"
#include "ofxFensterManager.h"
#include "ofxBlur.h"

enum imageSources{
    IMAGE_SOURCE_CAMERA, IMAGE_SOURCE_SCREEN
};

class captureWindow: public ofxFenster {
public:
	
    void setup(){
		setWindowTitle("Capture");
	}

    void update(){
        videoRect = ofRectangle(0,0, tex.getWidth(), tex.getHeight());
        ofRectangle thisWindowRect = ofRectangle(0, 0, getWidth(), getHeight());
        croppingRect  = ofRectangle(0, 0,ofxFensterManager::get()->getMainWindow()->getWidth(), ofxFensterManager::get()->getMainWindow()->getHeight());
        videoRect.scaleTo(thisWindowRect, OF_ASPECT_RATIO_KEEP);
        croppingRect.scaleTo(videoRect, OF_ASPECT_RATIO_KEEP);
    }
    
	void draw() {
        ofEnableAlphaBlending();
        ofSetColor(255,255);
        tex.draw(videoRect);
        // draw cropping mask
        ofSetColor(64, 64, 64, 191);
        ofRect(0, 0, getWidth(), croppingRect.y);
        ofRect(0, croppingRect.y, croppingRect.x, croppingRect.height);
        ofRect(croppingRect.getRight(), croppingRect.getTop(), getWidth()-croppingRect.getRight(), croppingRect.height);
        ofRect(0, croppingRect.getBottom(), getWidth(), getHeight()-croppingRect.getBottom());
        
	}
    
    ofTexture tex;
    ofRectangle croppingRect;
    ofRectangle mainWindowRect;
    ofRectangle thisWindowRect;
    ofRectangle videoRect;
    imageSources imageSource;
    
    void keyReleased(int key){
        
        if (key == 'f') {
            ofxFensterManager::get()->getMainWindow()->toggleFullscreen();
        }
        
    }
    
};

class testApp : public ofBaseApp {

	public:
		void setup();
		void update();
		void draw();

        void createDots(ofRectangle area, float spacing);
        //void updateDots(ofImage image);
    
    void updateDots(unsigned char * data, int width, int height);

	void keyPressed  (int key, ofxFenster* win);
	void keyReleased(int key, ofxFenster* win);
	void keyReleased(int key);
	void mouseMoved(int x, int y );
	void mouseMoved(int x, int y, ofxFenster* win);
	void mouseDragged(int x, int y, int button);
	void mousePressed(int x, int y, int button);
	void mouseReleased(int x, int y, int button);
	void windowResized(int w, int h);
	void dragEvent(ofDragInfo dragInfo);
	void gotMessage(ofMessage msg);
	void mouseMovedEvent(ofMouseEventArgs &args);
    
    static void serverCallback(RemoteUIServerCallBackArg arg);
    void screenShot();

        vector<LightDot*> dots;
    
        captureWindow captureFenster;
    
        float dotBrightnessFactor;
        float dotHueShift;
        float dotSaturationFactor;

        float dotPositionNoiseAmount;
        float dotPositionNoiseScale;
        float dotSpacing;
        float dotRadius;
        float dotDepth;
        float blurStrength;
        float blurGain;
    
        float fogDensity;
    
        bool resetCam;
        bool doScreenShot;
        bool fullScreen;
        bool isFullScreen;
    
    imageSources imageSource;
    
        ofRectangle area;
    
        int camWidth;
        int camHeight;

        ofVideoGrabber vidGrabber;
        ofEasyCam cam;
    
    unsigned char * data;
    
    ofxBlur blur;

    
};