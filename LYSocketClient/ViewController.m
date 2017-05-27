//
//  ViewController.m
//  LYSocketClient
//
//  Created by hxf on 24/05/2017.
//  Copyright © 2017 sinowave. All rights reserved.
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <errno.h>


#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <signal.h>

// for select
#include <sys/select.h>
#import <pthread.h>

/*
 ***establishing a socket on the client***
 1.Create a socket with the socket() system call
 2.Connect the socket to the address of the server using the connect() system call
 3.Send and receive data. There are a number of ways to do this, but the simplest is to use the read() and write() system calls.
 */

//connect/recv/send 等接口都是阻塞式的，因此我们需要将这些操作放在非 UI 线程中进行

#import "ViewController.h"

@interface ViewController ()
{
   int _sock;
}
@property (weak, nonatomic) IBOutlet UITextField *serverIpTextField;
@property (weak, nonatomic) IBOutlet UITextField *serverPortTextField;

@property (weak, nonatomic) IBOutlet UITextField *messageBoardTextField;


- (IBAction)connect:(id)sender;
- (IBAction)sendMsg:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *messageRecordBoard;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)asynThread
{
    //1.create socket()
    int fd=socket(PF_INET,SOCK_STREAM,0);
    int on=1;
    setsockopt(fd,SOL_SOCKET,SO_REUSEADDR,(const char*)&on,sizeof(on));

    
    struct sockaddr_in addr;
    addr.sin_family=AF_INET;
    addr.sin_port=htons(self.serverPortTextField.text.integerValue);
    addr.sin_addr.s_addr=inet_addr([self.serverIpTextField.text UTF8String]);
    int err=0;
    //2.connect()
    err=connect(fd,(struct sockaddr*)&addr,sizeof(struct sockaddr));
    if (err==0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.messageRecordBoard.text = [self.messageRecordBoard.text stringByAppendingString:[NSString stringWithFormat:@"%@ \n",[NSString stringWithCString:"connected Success!!!" encoding:NSUTF8StringEncoding]]];
        });
    }
    _sock=fd;
    
    
    do {
        const char buffer[1024];
        int length = sizeof(buffer);
        int result = recv(fd, buffer, length, 0);
        if (result>0) {
            const char *buf = buffer;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.messageRecordBoard.text = [self.messageRecordBoard.text stringByAppendingString:[NSString stringWithFormat:@"%@ \n",[NSString stringWithCString:buf encoding:NSUTF8StringEncoding]]];
            });
        }
    } while (1);
    
    

}

#pragma mark -GCDAsyncSocketDelegate

- (IBAction)connect:(id)sender
{

    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(asynThread)
                                                            object:nil];
    [backgroundThread start];
}

- (IBAction)sendMsg:(id)sender
{
   int ret=0;
   const char* buf = [self.messageBoardTextField.text UTF8String];
   int size=(int)self.messageBoardTextField.text.length;
    //3.send() & receive() data
   ret=send(_sock,buf,size,0);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}
@end
