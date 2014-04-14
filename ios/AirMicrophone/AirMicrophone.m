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
    }
    return self;
}

-(void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    AirMicRefToSelf = nil;
    [super dealloc];
}

- (BOOL) canMakePayment
{
    return [SKPaymentQueue canMakePayments];
}

- (void) registerObserver
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}


//////////////////////////////////////////////////////////////////////////////////////
// PRODUCT INFO
//////////////////////////////////////////////////////////////////////////////////////

// get products info
- (void) sendRequest:(SKRequest*)request AndContext:(FREContext*)ctx
{
    request.delegate = self;
    [request start];   
}

// on product info received
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSString *formattedString;
    
    for (SKProduct* product in [response products])
    {        
        
        [numberFormatter setLocale:product.priceLocale];
        formattedString = [numberFormatter stringFromNumber:product.price];
        [dictionary setValue:formattedString forKey:[product productIdentifier]];
    }
    
    
    NSString* jsonDictionary = [dictionary JSONString];
    
    FREDispatchStatusEventAsync(AirMicCtx ,(uint8_t*) "PRODUCT_INFO_SUCCESS", (uint8_t*) [jsonDictionary UTF8String] );
    
    if ([response invalidProductIdentifiers] != nil && [[response invalidProductIdentifiers] count] > 0)
    {
        NSString* jsonArray = [[response invalidProductIdentifiers] JSONString];
        
        FREDispatchStatusEventAsync(AirMicCtx ,(uint8_t*) "PRODUCT_INFO_ERROR", (uint8_t*) [jsonArray UTF8String] );
        
    }
}

// on product info finish
- (void)requestDidFinish:(SKRequest *)request
{
    FREDispatchStatusEventAsync(AirMicCtx ,(uint8_t*) "DEBUG", (uint8_t*) [@"requestDidFinish" UTF8String] );
}

// on product info error
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    FREDispatchStatusEventAsync(AirMicCtx ,(uint8_t*) "DEBUG", (uint8_t*) [@"requestDidFailWithError" UTF8String] );
}


//////////////////////////////////////////////////////////////////////////////////////
// PURCHASE PRODUCT
//////////////////////////////////////////////////////////////////////////////////////

// complete a transaction (item has been purchased, need to check the receipt)
- (void) completeTransaction:(SKPaymentTransaction*)transaction
{
    NSMutableDictionary *data;

    // purchase done
    // dispatch event
    data = [[NSMutableDictionary alloc] init];
    [data setValue:[[transaction payment] productIdentifier] forKey:@"productId"];
    
    NSString* receiptString = [[[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding] autorelease];
    [data setValue:receiptString forKey:@"receipt"];
    [data setValue:@"AppStore"   forKey:@"receiptType"];
    
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"PURCHASE_SUCCESSFUL", (uint8_t*)[[data JSONString] UTF8String]); 
}

// transaction failed, remove the transaction from the queue.
- (void) failedTransaction:(SKPaymentTransaction*)transaction
{
    // purchase failed
    NSMutableDictionary *data;

    [[transaction payment] productIdentifier];
    [[transaction error] code];
    
    data = [[NSMutableDictionary alloc] init];
    [data setValue:[NSNumber numberWithInteger:[[transaction error] code]]  forKey:@"code"];
    [data setValue:[[transaction error] localizedFailureReason] forKey:@"FailureReason"];
    [data setValue:[[transaction error] localizedDescription] forKey:@"FailureDescription"];
    [data setValue:[[transaction error] localizedRecoverySuggestion] forKey:@"RecoverySuggestion"];
    
    NSString *error = transaction.error.code == SKErrorPaymentCancelled ? @"RESULT_USER_CANCELED" : [data JSONString];
    
    // conclude the transaction
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    // dispatch event
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"PURCHASE_ERROR", (uint8_t*) [error UTF8String]);
    
}

// transaction is being purchasing, logging the info.
- (void) purchasingTransaction:(SKPaymentTransaction*)transaction
{
    // purchasing transaction
    // dispatch event
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"PURCHASING", (uint8_t*)             
                                [[[transaction payment] productIdentifier] UTF8String]
                                ); 
}

// transaction restored, remove the transaction from the queue.
- (void) restoreTransaction:(SKPaymentTransaction*)transaction
{
    // transaction restored
    // dispatch event
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"TRANSACTION_RESTORED", (uint8_t*)             
                                [[[transaction error] localizedDescription] UTF8String]
                                ); 
    
    
    // conclude the transaction
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


// list of transactions has been updated.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSUInteger nbTransaction = [transactions count];
    NSString* pendingTransactionInformation = [NSString stringWithFormat:@"pending transaction - %@", [NSNumber numberWithUnsignedInteger:nbTransaction]];
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"UPDATED_TRANSACTIONS", (uint8_t*) [pendingTransactionInformation UTF8String]  ); 
    
    for ( SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                [self purchasingTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"PURCHASE_UNKNOWN", (uint8_t*) [@"Unknown Reason" UTF8String]);
                break;
        }
    }
}

// restoring transaction is done.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"DEBUG", (uint8_t*) [@"restoreCompletedTransactions" UTF8String] ); 
}

// restoring transaction failed.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"DEBUG", (uint8_t*) [@"restoreFailed" UTF8String] ); 
}

// transaction has been removed.
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    FREDispatchStatusEventAsync(AirMicCtx, (uint8_t*)"DEBUG", (uint8_t*) [@"removeTransaction" UTF8String] ); 
}


@end


DEFINE_ANE_FUNCTION(AirMicrophoneInit)
{
    [(AirMicrophone*)AirMicRefToSelf registerObserver];
    
    return nil;
}

// make a purchase
DEFINE_ANE_FUNCTION(makePurchase)
{
    
    uint32_t stringLength;
    const uint8_t *string1;
    //FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [@"purchase: getting product id" UTF8String]);

    if (FREGetObjectAsUTF8(argv[0], &stringLength, &string1) != FRE_OK)
    {
        return nil;
    }

    //FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [@"purchase: convert product id" UTF8String]);

    NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string1];
  
    FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [productIdentifier UTF8String]);
    
    SKPayment* payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
        
    FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [[payment productIdentifier] UTF8String]);
    
 //   [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return nil;
}


// check if the user can make a purchase
DEFINE_ANE_FUNCTION(userCanMakeAPurchase)
{
    
    BOOL canMakePayment = [SKPaymentQueue canMakePayments];
    
    if (canMakePayment)
    {
        FREDispatchStatusEventAsync(context, (uint8_t*) "PURCHASE_ENABLED", (uint8_t*) [@"Yes" UTF8String]);
 
    } else
    {
        FREDispatchStatusEventAsync(context, (uint8_t*) "PURCHASE_DISABLED", (uint8_t*) [@"No" UTF8String]);
    }
    return nil;
}



// make a SKProductsRequest. wait for a SKProductsResponse
// arg : array of string (string = product identifier)
DEFINE_ANE_FUNCTION(getProductsInfo)
{        
    FREObject arr = argv[0]; // array
    uint32_t arr_len; // array length
    
    FREGetArrayLength(arr, &arr_len);

    NSMutableSet* productsIdentifiers = [[NSMutableSet alloc] init];
     
    for(int32_t i=arr_len-1; i>=0;i--){
                
        // get an element at index
        FREObject element;
        FREGetArrayElementAt(arr, i, &element);
        
        // convert it to NSString
        uint32_t stringLength;
        const uint8_t *string;
        FREGetObjectAsUTF8(element, &stringLength, &string);
        NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string];
        
        [productsIdentifiers addObject:productIdentifier];
    }
    
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productsIdentifiers];
    
    
    [(AirMicrophone*)AirMicRefToSelf sendRequest:request AndContext:context];
    
    
    return nil;
}

// remove purchase from queue.
DEFINE_ANE_FUNCTION(removePurchaseFromQueue)
{
    uint32_t stringLength;
    const uint8_t *string1;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &string1) != FRE_OK)
    {
      return nil;
    }
    
    NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string1];

    FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [[NSString stringWithFormat:@"removing purchase from queue %@", productIdentifier] UTF8String]);

    NSArray* transactions = [[SKPaymentQueue defaultQueue] transactions];

    for (SKPaymentTransaction* transaction in transactions)
    {
     //   FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [[NSString stringWithFormat:@"%@", [transaction transactionState]] UTF8String]);

        FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [[[transaction payment] productIdentifier] UTF8String]);

        switch ([transaction transactionState]) {
            case SKPaymentTransactionStatePurchased:
                FREDispatchStatusEventAsync(context, (uint8_t*)"DEBUG", (uint8_t*) [@"SKPaymentTransactionStatePurchased" UTF8String]);
                break;
            case SKPaymentTransactionStateFailed:
                FREDispatchStatusEventAsync(context, (uint8_t*)"DEBUG", (uint8_t*) [@"SKPaymentTransactionStateFailed" UTF8String]);
                break;
            case SKPaymentTransactionStatePurchasing:
                FREDispatchStatusEventAsync(context, (uint8_t*)"DEBUG", (uint8_t*) [@"SKPaymentTransactionStatePurchasing" UTF8String]);
            case SKPaymentTransactionStateRestored:
                FREDispatchStatusEventAsync(context, (uint8_t*)"DEBUG", (uint8_t*) [@"SKPaymentTransactionStateRestored" UTF8String]);
            default:
                FREDispatchStatusEventAsync(context, (uint8_t*)"DEBUG", (uint8_t*) [@"Unknown Reason" UTF8String]);
                break;
        }

        if ([transaction transactionState] == SKPaymentTransactionStatePurchased && [[[transaction payment] productIdentifier] isEqualToString:productIdentifier])
        {
            // conclude the transaction
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            FREDispatchStatusEventAsync(context, (uint8_t*) "DEBUG", (uint8_t*) [@"Conluding transaction" UTF8String]);
            break;
        }
    }
    
    return nil;
}





// ContextInitializer()
//
// The context initializer is called when the runtime creates the extension context instance.
void AirMicContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, 
                             uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 5;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "initLib";
    func[0].functionData = NULL;
    func[0].function = &AirMicrophoneInit;
    
    func[1].name = (const uint8_t*) "makePurchase";
    func[1].functionData = NULL;
    func[1].function = &makePurchase;
    
    func[2].name = (const uint8_t*) "userCanMakeAPurchase";
    func[2].functionData = NULL;
    func[2].function = &userCanMakeAPurchase;
    
    func[3].name = (const uint8_t*) "getProductsInfo";
    func[3].functionData = NULL;
    func[3].function = &getProductsInfo;

    func[4].name = (const uint8_t*) "removePurchaseFromQueue";
    func[4].functionData = NULL;
    func[4].function = &removePurchaseFromQueue;
    
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


