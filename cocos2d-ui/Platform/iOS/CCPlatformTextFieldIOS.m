   //
//  CCPlatformTextFieldIOS.m
//  cocos2d-osx
//
//  Created by Sergey Klimov on 7/1/14.
//
//

#import "CCPlatformTextFieldIOS.h"
#import "CCDirector.h"
#import "CCControl.h"
#import <UIKit/UIKit.h>

@implementation CCPlatformTextFieldIOS {
    UITextField *_textField;
    CGFloat _scaleMultiplier;
    BOOL _keyboardIsShown;
    float _keyboardHeight;
}
- (id) init {
    if (self=[super init]) {
        // Create UITextField and set it up
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        
        // UIKit might not be running in the same scale as us.
        _scaleMultiplier = [CCDirector sharedDirector].contentScaleFactor/[UIScreen mainScreen].scale;
        
    }
    return self;
}

- (void) positionInControl:(CCControl *)control padding:(CGFloat)padding {
    CGPoint worldPos = [control convertToWorldSpace:CGPointZero];
    CGPoint viewPos = [[CCDirector sharedDirector] convertToUI:worldPos];
    viewPos.x += padding;
    viewPos.y += padding;
    
    CGSize size = control.contentSizeInPoints;
    size.width *= _scaleMultiplier;
    size.height *= _scaleMultiplier;
    
    viewPos.y -= size.height;
    size.width -= padding * 2;
    size.height -= padding * 2;
    
    CGRect frame = CGRectZero;
    frame.origin = viewPos;
    frame.size = size;
    
    _textField.frame = frame;
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [self addUITextView];
    [self registerForKeyboardNotifications];

}
- (void) onExitTransitionDidStart
{
    [super onExitTransitionDidStart];
    [self removeUITextView];
    [self unregisterForKeyboardNotifications];
}
- (void) setString:(NSString *)string
{
    _textField.text = string;
}

- (NSString*) string
{
    return _textField.text;
}

- (void)setFontSize:(float)fontSize {
    UIFont *font = _textField.font;
    _textField.font = [font fontWithSize:fontSize*_scaleMultiplier];

}

- (BOOL)hidden {
    return _textField.hidden;
}

- (void) setHidden:(BOOL)hidden {
    _textField.hidden = hidden;
}

- (void) addUITextView
{
    [[[CCDirector sharedDirector] view] addSubview:_textField];
}

- (void) removeUITextView
{
    [_textField removeFromSuperview];
}

#pragma mark Text Field Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{

    if (_keyboardIsShown)
    {
        [self focusOnTextField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self endFocusingOnTextField];
    if ([[self delegate] respondsToSelector:@selector(platformTextFieldDidFinishEditing:)]) {
        [[self delegate]platformTextFieldDidFinishEditing:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (id)nativeTextField
{
    return _textField;
}


#pragma mark Keyboard Notifications

- (void)registerForKeyboardNotifications
{
#if !__TV_OS_VERSION_MAX_ALLOWED
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
#endif
}

- (void) unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#if !__TV_OS_VERSION_MAX_ALLOWED

- (void)keyboardWasShown:(NSNotification*)notification
{
    _keyboardIsShown = YES;
    
    UIView* view = [[CCDirector sharedDirector] view];
    
    NSDictionary* info = [notification userInfo];
    NSValue* value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect frame = [value CGRectValue];
    frame = [view.window convertRect:frame toView:view];
    
    CGSize kbSize = frame.size;
    
    _keyboardHeight = kbSize.height;
    
    BOOL focusOnTextField = _textField.isEditing;
    
    if (focusOnTextField)
    {
        [self focusOnTextField];
    }
}

- (void) keyboardWillBeHidden:(NSNotification*) notification
{
    _keyboardIsShown = NO;
    BOOL focusOnTextField = _textField.isEditing;
    
    if (focusOnTextField)
        [self endFocusingOnTextField];
}

#endif

#pragma mark Focusing on Text Field


- (void) focusOnTextField
{
    CGSize windowSize = [[CCDirector sharedDirector] viewSize];
    
    // Find the location of the textField
    float fieldCenterY = _textField.frame.origin.y - (_textField.frame.size.height/2);
    
    // Upper third part of the screen
    float upperThirdHeight = windowSize.height / 3;
    
    if (fieldCenterY > upperThirdHeight)
    {
        // Slide the main view up
        
        // Calculate offset
        float dstYLocation = windowSize.height / 4;
        float offset = -(fieldCenterY - dstYLocation);
        
        if (offset < -_keyboardHeight) offset = -_keyboardHeight;
        
        // Calcualte target frame
        UIView* view = [[CCDirector sharedDirector] view];
        CGRect frame = view.frame;
        frame.origin.y = offset;
        
        // Do animation
        [UIView beginAnimations: @"textFieldAnim" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: 0.2f];
        
        view.frame = frame;
        [UIView commitAnimations];
    }
}

- (void) endFocusingOnTextField
{
    // Slide the main view back down
    
    UIView* view = [[CCDirector sharedDirector] view];
    [UIView beginAnimations: @"textFieldAnim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.2f];
    
    CGRect frame = view.frame;
    frame.origin = CGPointZero;
    view.frame = frame;
    
    [UIView commitAnimations];
}



@end
