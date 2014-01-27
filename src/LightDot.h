//
//  rgbDot.h
//  ledPixelDots
//
//  Created by ole kristensen on 25/03/13.
//
//

#ifndef __ledPixelDots__rgbDot__
#define __ledPixelDots__rgbDot__

#include "ofMain.h"
#include <iostream>

class LightDot : public ofNode{
    
public:
    
    void customDraw();

    ofColor color;
    
    float radius;
    float blur;
    
    int address;
    
    LightDot(){
        
        color.set(255.0, 255.0, 255.0, 255.0);
        radius = 2.0;
        blur = 0.0;
        address = -1;
        
    }
    
};

#endif /* defined(__ledPixelDots__rgbDot__) */
