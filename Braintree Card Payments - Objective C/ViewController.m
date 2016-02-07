//
//  ViewController.m
//  Braintree Card Payments - Objective C
//
//  Created by Orcun on 07/02/2016.
//  Copyright © 2016 Orcun. All rights reserved.
//

#import "ViewController.h"
#import "BraintreeCard.h"

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UITextField *cardTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardExpiryMonthTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardExpiryYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardCvvTextField;

@property (weak, nonatomic) IBOutlet UIButton *buyButton;


@end

NSString *clientToken;
NSString *resultCheck;


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSURL *clientTokenURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/tokenGen.php"];
    NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
    [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO: Handle errors
        clientToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // Log the client token to confirm that it is returned from the server
        NSLog(@"Client token received: %@",clientToken);
        
    }] resume];

   }


- (IBAction)buyButtonTapped:(id)sender {
    
    // Add the client token to braintreeClient
    BTAPIClient *braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    
    // Initiliaze the BTCardClient for tokenizing card details
    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient:braintreeClient];
    
    // Take the card details from text fields in the app
    BTCard *card = [[BTCard alloc] initWithNumber:self.cardTextField.text
                                  expirationMonth:self.cardExpiryMonthTextField.text
                                   expirationYear:self.cardExpiryYearTextField.text
                                              cvv:self.cardCvvTextField.text];
    
    // Tokenize the card details
    [cardClient tokenizeCard:card
                  completion:^(BTCardNonce *tokenizedCard, NSError *error) {
                      
                      // Log the tokenized card nonce to confirm it's generated
                       NSLog(@"Nonce received: %@",tokenizedCard.nonce);
                      
                      // Invoke postNonceToServer function to send the nonce to server
                      [self postNonceToServer:tokenizedCard.nonce];
                  }];
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    
    double price = 1199.00;
    
    
    NSURL *paymentURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/iosPayment.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:paymentURL];
    
    request.HTTPBody = [[NSString stringWithFormat:@"amount=%ld&payment_method_nonce=%@", (long)price,paymentMethodNonce] dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *paymentResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // TODO: Handle success and failure
        
        // Logging the HTTP request so we can see what is being sent to the server side
        NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
        
        // Trimming the response for success/failure check so it takes less time to determine the result
        NSString *trimResult =[paymentResult substringToIndex:50];
        
        // Log the transaction result
        NSLog(@"%@",paymentResult);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Checking the result for the string "Successful" and updating GUI elements
            if ([trimResult containsString:@"Successful"]) {
                NSLog(@"Transaction is successful!");
                resultCheck = @"Transaction successful";
                
                
            } else {
                NSLog(@"Transaction failed! Contact Mat!");
                resultCheck = @"Transaction failed!Contact Mat!";
                
            }
            
            // Create an alert controller to display the transaction result
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:resultCheck
                                                                           message:paymentResult
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:
                                            UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                
                                                NSLog(@"You pressed button OK");
                                            }];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    }] resume];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
