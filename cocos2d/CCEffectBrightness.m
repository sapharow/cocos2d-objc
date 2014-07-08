//
//  CCEffectBrightness.m
//  cocos2d-ios
//
//  Created by Thayer J Andrews on 5/7/14.
//
//

#import "CCEffectBrightness.h"
#import "CCEffect_Private.h"
#import "CCRenderer.h"
#import "CCTexture.h"

#if CC_ENABLE_EXPERIMENTAL_EFFECTS
static float conditionBrightness(float brightness);

@interface CCEffectBrightness ()

@property (nonatomic) float conditionedBrightness;

@end


@implementation CCEffectBrightness

-(id)init
{
    CCEffectUniform* uniformBrightness = [CCEffectUniform uniform:@"float" name:@"u_brightness" value:[NSNumber numberWithFloat:0.0f]];
    
    if((self = [super initWithFragmentUniforms:@[uniformBrightness] vertexUniforms:nil varying:nil]))
    {
        self.debugName = @"CCEffectBrightness";
        return self;
    }
    return self;
}

-(id)initWithBrightness:(float)brightness
{
    if((self = [self init]))
    {
        _brightness = brightness;
        _conditionedBrightness = conditionBrightness(brightness);
    }    
    return self;
}

+(id)effectWithBrightness:(float)brightness
{
    return [[self alloc] initWithBrightness:brightness];
}

-(void)buildFragmentFunctions
{
    self.fragmentFunctions = [[NSMutableArray alloc] init];

    CCEffectFunctionInput *input = [[CCEffectFunctionInput alloc] initWithType:@"vec4" name:@"inputValue" snippet:@"texture2D(cc_PreviousPassTexture, cc_FragTexCoord1)"];

    NSString* effectBody = CC_GLSL(
                                   return vec4((inputValue.rgb + vec3(u_brightness * inputValue.a)), inputValue.a);
                                   );
    
    CCEffectFunction* fragmentFunction = [[CCEffectFunction alloc] initWithName:@"brightnessEffect" body:effectBody inputs:@[input] returnType:@"vec4"];
    [self.fragmentFunctions addObject:fragmentFunction];
}

-(void)buildRenderPasses
{
    __weak CCEffectBrightness *weakSelf = self;
    
    CCEffectRenderPass *pass0 = [[CCEffectRenderPass alloc] init];
    pass0.shader = self.shader;
    pass0.beginBlocks = @[[^(CCEffectRenderPass *pass, CCTexture *previousPassTexture){
        pass.shaderUniforms[CCShaderUniformMainTexture] = previousPassTexture;
        pass.shaderUniforms[CCShaderUniformPreviousPassTexture] = previousPassTexture;
        pass.shaderUniforms[self.uniformTranslationTable[@"u_brightness"]] = [NSNumber numberWithFloat:weakSelf.conditionedBrightness];
    } copy]];
    
    self.renderPasses = @[pass0];
}

-(void)setBrightness:(float)brightness
{
    _brightness = brightness;
    _conditionedBrightness = conditionBrightness(brightness);
}

@end

float conditionBrightness(float brightness)
{
    NSCAssert((brightness >= -1.0) && (brightness <= 1.0), @"Supplied brightness out of range [-1..1].");
    return clampf(brightness, -1.0f, 1.0f);
}

#endif
