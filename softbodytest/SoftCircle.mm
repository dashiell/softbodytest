//
//  SoftCircle.m
//  softbodytest
//
//  Created by Dashiell Gough on 10/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SoftCircle.h"
#define PTM_RATIO 32
#define NUM_SEGMENTS 10
#define SPRITE_WIDTH 64

@implementation SoftCircle

-(id) initWithWorld:(b2World*)world position:(b2Vec2)position
{
    if ((self = [super init])) 
    {
        const float radius = SPRITE_WIDTH/2.0/PTM_RATIO;
        b2Vec2 innerBodyPos = position;
        const float angleStep = (M_PI * 2.0f) / NUM_SEGMENTS; 
        const float sinHalfAngle = sinf(angleStep * 0.5f);
        subCircleRadius_ = sinHalfAngle * radius / (1.0f + sinHalfAngle); 
        
        // create outer circle bodies
        
        b2CircleShape shape; 
        shape.m_radius = subCircleRadius_;
        
        b2FixtureDef fd;
        fd.shape = &shape;
        fd.density = 0.1; 
        fd.restitution = 0.05;
        fd.friction = 1.0;
        
        float angle = 0;
        for (int i = 0; i < NUM_SEGMENTS; i++) {
            b2Vec2 offset(sinf(angle), cosf(angle));
            offset *= radius - subCircleRadius_;
            
            b2BodyDef bd;
            bd.type = b2_dynamicBody;
            bd.position = innerBodyPos + offset;
            b2Body* body = world->CreateBody(&bd);
            
            body->CreateFixture(&fd);
            
            segments_[i] = body;
            angle += angleStep;
        }
        
        
        // create inner circle body
        
        b2BodyDef bd;
        bd.type = b2_dynamicBody;
   
        bd.position = innerBodyPos;
      
        innerBody_ = world->CreateBody(&bd);
        
        shape.m_radius = (radius - subCircleRadius_ * 2.0f) * 0.5;
       
        innerBody_->CreateFixture(&fd);
        
        // get scale
        float partToCentDist = b2Distance(segments_[0]->GetPosition(), innerBody_->GetPosition());
        b2Vec2 offset(sinf(0),cosf(0));
        offset *= radius;
        b2Vec2 partEdgePos = innerBodyPos + offset;
        float partEdgeToCentDist = b2Distance(partEdgePos, innerBody_->GetPosition());
        texScale_ = partEdgeToCentDist/partToCentDist;
       
        // Create links between outer circle bodies
        
        b2DistanceJointDef jointDef;
        for (int i = 0; i < NUM_SEGMENTS; i++)
        {
            const int neighborIndex = (i + 1) % NUM_SEGMENTS;
            
            // joints between outer circles
            
            jointDef.Initialize(segments_[i], segments_[neighborIndex],
                                segments_[i]->GetWorldCenter(), 
                                segments_[neighborIndex]->GetWorldCenter() );
            jointDef.collideConnected = true;
            jointDef.frequencyHz = 10.0f;
            jointDef.dampingRatio = 0.5f;
            
            segmentJoints_[i] = world->CreateJoint(&jointDef);
            
            // create joints - outer circles with inner circle
            
            jointDef.Initialize(segments_[i], innerBody_, segments_[i]->GetWorldCenter(), innerBodyPos);
            jointDef.collideConnected = true;
            jointDef.frequencyHz = 10.0;
            jointDef.dampingRatio = 0.5;
            
            innerJoints_[i] = world->CreateJoint(&jointDef);
        }
        
        CCTexture2D *tex = [[[CCTextureCache sharedTextureCache] addImage:@"ball.png"] retain];
        innerBody_->SetUserData(tex);
    }
    return self;
}

-(void) draw {
    
    CGPoint segmentPos[ NUM_SEGMENTS + 2 ];
    CGPoint texturePos[ NUM_SEGMENTS + 2 ];
    CGPoint textureCenter;
    float angle, baseAngle;
    
    // calculate triangle fan segments
    
    segmentPos[ 0 ] = CGPointZero;
    
     CGPoint centerPos = ccp(innerBody_->GetPosition().x * PTM_RATIO, innerBody_->GetPosition().y * PTM_RATIO);
    
    for ( int count = 0; count < NUM_SEGMENTS; count ++ ) {
        
        b2Body *part = segments_[count];
        CGPoint partPos = ccp(part->GetPosition().x * PTM_RATIO, part->GetPosition().y * PTM_RATIO);
   
        segmentPos[count + 1] = ccpMult(ccpSub(partPos, centerPos), texScale_); // 1.0 is scale
        
    }
    segmentPos[ NUM_SEGMENTS + 1 ] = segmentPos[ 1 ];
    
    // move to absolute position
    
    for ( int count = 0; count < ( NUM_SEGMENTS + 2 ); count ++ ) {
        segmentPos[ count ] = ccpAdd( centerPos, segmentPos[ count ] );
    }
    
    baseAngle = M_PI;
    
    texturePos[ 0 ] = CGPointZero;
    for ( int count = 0; count < NUM_SEGMENTS; count ++ ) {
        
        // calculate new angle
        
        angle = baseAngle + ( 2 * M_PI / NUM_SEGMENTS * count );
    
        // calculate texture position
        
        texturePos[ count + 1 ].x	= sinf( angle );
        texturePos[ count + 1 ].y	= cosf( angle );
    }
    texturePos[ NUM_SEGMENTS + 1 ] = texturePos[ 1 ];
    
    // recalculate to texture coordinates
   
    textureCenter = CGPointMake( 0.5f, 0.5f );
    for ( int count = 0; count < ( NUM_SEGMENTS + 2 ); count ++ )
        texturePos[ count ] = ccpAdd( ccpMult( texturePos[ count ], 0.5f ), textureCenter );
    
    
    glEnable( GL_TEXTURE_2D );
    CCTexture2D *tex = (CCTexture2D*)innerBody_->GetUserData();
    glBindTexture(GL_TEXTURE_2D, [tex name]);

    glDisableClientState( GL_COLOR_ARRAY );
    glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
    glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
    glDrawArrays( GL_TRIANGLE_FAN, 0, NUM_SEGMENTS + 2 );
    
}

@end
