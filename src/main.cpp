#include "ofMain.h"
#include "testApp.h"
#include "ofxFensterManager.h"
#include "ofAppGlutWindow.h"

//========================================================================
int main( ){
	ofSetupOpenGL(ofxFensterManager::get(), 800, 600, OF_WINDOW);			// <-------- setup the GL context
    
	// this kicks off the running of my app
	// can be OF_WINDOW or OF_FULLSCREEN
	// pass in width and height too:
	ofRunFensterApp(new testApp());
}

