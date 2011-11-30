//
//  SoftCircle.h
//  softbodytest
//
//  Created by Dashiell Gough on 10/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import <map>

@interface SoftCircle : CCSprite {
    b2Body *innerBody_;
    
    std::map<int, b2Body*> segments_;
    std::map<int, b2Joint*> segmentJoints_;
    std::map<int, b2Joint*> innerJoints_;
    
    float texScale_;
    float subCircleRadius_;
    
}

-(id) initWithWorld:(b2World*)world position:(b2Vec2)position;

@end
