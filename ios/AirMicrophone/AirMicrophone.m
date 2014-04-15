//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2014 Fovea.cc (http://fovea.cc | hoelt@fovea.cc)
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//////////////////////////////////////////////////////////////////////////////////////

#import "AirMicrophone.h"

FREContext AirMicCtx = nil;

void *AirMicRefToSelf;

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])


@implementation AirMicrophone

- (id) init
{
    self = [super init];
    if (self)
    {
        AirMicRefToSelf = self;

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession requestRecordPermission:^(BOOL granted) {
                if (!granted) {
                    NSLog(@"NO RECORD PERMISSION");
                    [audioSession setActive:YES error:nil];
                    return;
                }
                [self createRecorder];
            }];
        }
        else {
            [self createRecorder];
        }
    }
    return self;
}

-(void)createRecorder
{
    NSLog(@"Entering createRecorder");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
        [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
        [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
        [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
        nil];

    NSError *error;

    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];

    if (recorder) {
        NSLog(@"record!");
        [recorder prepareToRecord];
        recorder.meteringEnabled = YES;
        [recorder record];
    }
    else {
        NSLog(@"%@", [error description]);
    }
    NSLog(@"Exiting createRecorder");
}

-(void)dealloc
{
    // [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    AirMicRefToSelf = nil;
    [recorder release];
    [super dealloc];
}

- (void) registerObserver
{
    // [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

//////////////////////////////////////////////////////////////////////////////////////
// PRODUCT INFO
//////////////////////////////////////////////////////////////////////////////////////

@end


DEFINE_ANE_FUNCTION(AirMicrophoneInit)
{
    [(AirMicrophone*)AirMicRefToSelf registerObserver];
    
    return nil;
}


// check if the user can make a purchase
DEFINE_ANE_FUNCTION(getActivityLevel)
{
    AirMicrophone *mic = (AirMicrophone*)AirMicRefToSelf;
    [mic->recorder updateMeters];
    float avg  = [mic->recorder averagePowerForChannel:0];
    float peak = [mic->recorder peakPowerForChannel:0];
    static uint8_t sPeak[8];
    // sprintf(sPeak, "%2.2f", pow(10, peak / 20));
    float value = 2.0 * (pow(5.0, avg / 40.0) - 0.5); // Magic formula to make activity as near as android.
    if (value < 0.001f) value = 0.001f;
    sprintf(sPeak, "%2.2f", value);
    FREDispatchStatusEventAsync(context, (uint8_t*) "ACTIVITY_LEVEL", sPeak);
    return nil;
}


// ContextInitializer()
//
// The context initializer is called when the runtime creates the extension context instance.
void AirMicContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, 
                             uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 2;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "initLib";
    func[0].functionData = NULL;
    func[0].function = &AirMicrophoneInit;
    
    func[1].name = (const uint8_t*) "getActivityLevel";
    func[1].functionData = NULL;
    func[1].function = &getActivityLevel;
    
    *functionsToSet = func;
    
    AirMicCtx = ctx;

    if ((AirMicrophone*)AirMicRefToSelf == nil)
    {
        AirMicRefToSelf = [[AirMicrophone alloc] init];
    }

}

// ContextFinalizer()
//
// Set when the context extension is created.

void AirMicContextFinalizer(FREContext ctx) { 
    NSLog(@"Entering ContextFinalizer()");
    
    NSLog(@"Exiting ContextFinalizer()");	
}



// AirMicInitializer()
//
// The extension initializer is called the first time the ActionScript side of the extension
// calls ExtensionContext.createExtensionContext() for any context.

void AirMicInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) 
{
    
    NSLog(@"Entering ExtInitializer()");                    
    
	*extDataToSet = NULL;
	*ctxInitializerToSet = &AirMicContextInitializer; 
	*ctxFinalizerToSet = &AirMicContextFinalizer;
    
    NSLog(@"Exiting ExtInitializer()"); 
}


