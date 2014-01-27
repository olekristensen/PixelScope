//
//  rgbDot.cpp
//  ledPixelDots
//
//  Created by ole kristensen on 25/03/13.
//
//

#include "LightDot.h"

 void LightDot::customDraw() {

    ofFill();
    ofSetColor(color);
    ofCircle(0,0,0, radius);
    
}
 
 
