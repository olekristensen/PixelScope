#pragma once

#include "ofMain.h"
#include "LightDot.h"
#include "ofxRemoteUI.h"

#include "ofxFensterManager.h"

class captureWindow: public ofxFensterListener {
public:
	captureWindow() {

	}
    
    void update(){
        windowRect = ofGetWindowRect();
        windowRect.x = ofGetWindowPositionX();
        windowRect.y = ofGetWindowPositionY();
        windowRect.translate(0,22);
    }
    
	void draw() {
        tex.draw(0,0,ofGetWindowWidth(), ofGetWindowHeight());
	}
    
    ofTexture tex;
    ofRectangle windowRect;
    
    void keyReleased(int key, ofxFenster* win){
        
        if (key == 'f') {
            ofxFensterManager::get()->getWindowById(0)->toggleFullscreen();
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
	void mouseMoved(int x, int y );
	void mouseMoved(int x, int y, ofxFenster* win);
	void mouseDragged(int x, int y, int button);
	void mousePressed(int x, int y, int button);
	void mouseReleased(int x, int y, int button);
	void windowResized(int w, int h);
	void dragEvent(ofDragInfo dragInfo);
	void gotMessage(ofMessage msg);
	void mouseMovedEvent(ofMouseEventArgs &args);

        vector<LightDot*> dots;
    
        ofxFenster * captureFenster;
        captureWindow * captureFensterListener;
    
        float dotBrightnessFactor;
        float dotHueShift;
        float dotSaturationFactor;

        float dotPositionNoiseAmount;
        float dotPositionNoiseScale;
        float dotSpacing;
        float dotRadius;
        float dotDepth;
    
        float fogDensity;
    
        bool resetCam;
    
        int imageSource;
    
        ofRectangle area;
    
        int camWidth;
        int camHeight;

        ofVideoGrabber vidGrabber;
        ofEasyCam cam;
    
    unsigned char * data;

    
};