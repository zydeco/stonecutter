//
//  MCServer.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 09/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "MCServer.h"
#import <RakNetWrapper/RakNetWrapper.h>
#import "NSData+ZLib.h"
#import "RNBitStream+VarData.h"

typedef enum : uint8_t {
    LoginPacket = 0x01,
    DisconnectPacket = 0x05
} PacketType;

@implementation MCServer
{
    RNPeerInterface *server;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)run {
    server = [RNPeerInterface new];
    RNSocketDescriptor *descriptor = [[RNSocketDescriptor alloc] initWithPort:19132 andAddress:nil];
    NSError *error = nil;
    
    [server startupWithMaxConnectionsAllowed:8 socketDescriptors:@[descriptor] error:&error];
    server.maximumIncomingConnections = 8;
    
    NSLog(@"running server %llx", server.myGUID);
    
    RNBitStream *response = [RNBitStream new];
    [response writeString:[@[@"MCPE",
                             [[NSHost currentHost] localizedName],
                             @223,
                             @"1.12.15",
                             @1,
                             @(server.maximumNumberOfPeers),
                             @(server.myGUID),
                             [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey],
                             @"Creative",
                             @""
                             ] componentsJoinedByString:@";"]];
    server.offlinePingResponse = response.data;
    
    while (server.isActive) {
        RNPacket *packet = [server receive];
        if (packet) {
            [self handlePacket:packet];
        } else {
            [NSThread sleepForTimeInterval:1.0 / 60.0];
        }
    }
    
    NSLog(@"Server is no longer active.");
}

- (void)stop {
    [server shutdownWithDuration:1500];
}

- (void)handlePacket:(RNPacket *)packet {
    RNMessageIdentifier msg = *(uint8_t*)packet.data.bytes;
    
    if (msg == RNMessageIdentifierUnconnectedPing) {
        return;
    } else if (msg == 0xFE) { // batch packet
        if (![self handleBatchPacket:packet error:nil]) {
            [server disconnectRemoteGUID:packet.guid sendNotification:YES];
        }
    } else {
    }
}

- (BOOL)handleBatchPacket:(RNPacket *)packet error:(NSError **)error {
    NSData *data = [[packet.data subdataWithRange:NSMakeRange(1, packet.data.length - 1)] inflatedData];
    RNBitStream* dataStream = [[RNBitStream alloc] initWithData:data copy:NO];
    while (dataStream.readOffset < data.length) {
        NSData *packetData;
        if (![dataStream readVarData:&packetData error:error]) return NO;
        if (![self handleDataPacket:packetData from:packet.guid error:error]) return NO;
    }
    return YES;
}

- (BOOL)handleDataPacket:(NSData*)data from:(uint64_t)sender error:(NSError **)error {
    if (data.length < 3) {
        return NO;
    }
    const uint8_t *buf = data.bytes;
    PacketType packetId = buf[0];
    uint8_t senderSubID = buf[1];
    uint8_t recipientSubID = buf[2];
    if (senderSubID != 0 && recipientSubID != 0) {
        // unexpected split-screen bytes
        return NO;
    }
    switch (packetId) {
        case LoginPacket:
            return [self handleLoginPacket:[data subdataWithRange:NSMakeRange(3, data.length-3)] from:sender error:error];
            
        default:
            NSLog(@"unhandled data packet %@", data);
            return NO;
    }
}

- (BOOL)handleLoginPacket:(NSData*)data from:(uint64_t)sender error:(NSError **)error {
    RNBitStream *stream = [[RNBitStream alloc] initWithData:data copy:NO];
    uint32_t protocol;
    if (![stream readUInt32:&protocol error:error]) return NO;
    
    NSData *loginData;
    if (![stream readVarData:&loginData error:error]) return NO;
    NSData *chainData = [loginData subdataWithRange:NSMakeRange(4, OSReadLittleInt32(loginData.bytes, 0))];
    NSDictionary *chain = [NSJSONSerialization JSONObjectWithData:chainData options:0 error:error];
    if (chain == nil) return NO;
    for (NSString *link in chain[@"chain"]) {
        NSDictionary *token = [self decodeJWTPayload:link];
        NSString *displayName = [token valueForKeyPath:@"extraData.displayName"];
        NSString *identity = [token valueForKeyPath:@"extraData.identity"];
        if (displayName && identity) {
            [self.delegate mcServer:self didLogInUser:[[NSUUID alloc] initWithUUIDString:identity] withDisplayName:displayName];
        }
        
    }
    
    // can't be bothered to send a disconnect message
    return NO;
}

- (NSDictionary*)decodeJWTPayload:(NSString*)token {
    // don't verify, just decode payload
    NSArray<NSString*> *parts = [token componentsSeparatedByString:@"."];
    if (parts.count != 3) return nil;
    NSMutableString *base64payload = parts[1].mutableCopy;
    [base64payload replaceOccurrencesOfString:@"-" withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, base64payload.length)];
    [base64payload replaceOccurrencesOfString:@"_" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0, base64payload.length)];
    while (base64payload.length % 4) {
        [base64payload appendString:@"="];
    }
    NSData *payloadData = [[NSData alloc] initWithBase64EncodedString:base64payload options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:nil];
}

@end
