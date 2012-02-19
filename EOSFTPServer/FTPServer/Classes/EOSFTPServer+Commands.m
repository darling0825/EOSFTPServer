/*******************************************************************************
 * Copyright (c) 2012, Jean-David Gadina <macmade@eosgarden.com>
 * Distributed under the Boost Software License, Version 1.0.
 * 
 * Boost Software License - Version 1.0 - August 17th, 2003
 * 
 * Permission is hereby granted, free of charge, to any person or organization
 * obtaining a copy of the software and accompanying documentation covered by
 * this license (the "Software") to use, reproduce, display, distribute,
 * execute, and transmit the Software, and to prepare derivative works of the
 * Software, and to permit third-parties to whom the Software is furnished to
 * do so, all subject to the following:
 * 
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated by
 * a source language processor.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 * FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

/* $Id$ */

/*!
 * @file            ...
 * @author          Jean-David Gadina <macmade@eosgarden>
 * @copyright       (c) 2012, eosgarden
 * @abstract        ...
 */

#import "EOSFTPServer+Commands.h"
#import "EOSFTPServer+Private.h"
#import "EOSFTPServerConnection.h"
#import "EOSFTPServerUser.h"

@implementation EOSFTPServer( Commands )

- ( void )processCommandUSER: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    BOOL shouldAcceptUser;
    
    shouldAcceptUser         = YES;
    connection.authenticated = NO;
    
    if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:shouldAcceptUser: ) ] )
    {
        shouldAcceptUser = [ _delegate ftpServer: self shouldAcceptUser: args ];
    }
    
    if( shouldAcceptUser && [ self userCanLogin: args ] == YES )
    {
        connection.username = args;
        
        EOS_FTP_DEBUG( @"Username OK: %@", args );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 331 ] code: 331 ] ];
    }
    else
    {
        EOS_FTP_DEBUG( @"Wrong username: %@", args );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
    }
}

- ( void )processCommandPASS: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOSFTPServerUser * user;
    
    connection.authenticated = NO;
    
    if( connection.username != nil )
    {
        user = [ EOSFTPServerUser userWithName: connection.username password: args ];
        
        if( [ self authenticateUser: user ] == YES )
        {
            if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:userDidAuthentify: ) ] )
            {
                [ _delegate ftpServer: self userDidAuthentify: connection.username ];
            }
            
            connection.authenticated = YES;
            
            EOS_FTP_DEBUG( @"Password OK for user %@", connection.username );
            
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 230 ] code: 230 ] ];
        }
        else
        {
            if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:userDidFailAuthentify: ) ] )
            {
                [ _delegate ftpServer: self userDidFailAuthentify: connection.username ];
            }
            
            EOS_FTP_DEBUG( @"Invalid password for user %@", connection.username );
            
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
        }
    }
    else
    {
        EOS_FTP_DEBUG( @"No username" );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
    }
}

- ( void )processCommandACT:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandCWD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandCDUP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSMNT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandREIN: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandQUIT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOS_FTP_DEBUG( @"Quitting" );
    
    ( void )args;
    
    if( _quitMessage.length > 0 )
    {
        [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: @"%@\n%@", [ self messageForReplyCode: 221 ], _quitMessage ] code: 221 ] ];
    }
    else
    {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 221 ] code: 221 ] ];
    }
    
    [ connection close ];
}

- ( void )processCommandPORT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandPASV: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandTYPE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSString                 * typeString;
    EOSFTPServerConnectionType type;
    
    typeString = [ args uppercaseString ];
    
    if( [ typeString isEqualToString: @"A" ] )
    {
        EOS_FTP_DEBUG( @"Switching to ASCII connection type" );
        
        type = EOSFTPServerConnectionTypeASCII;
    }
    if( [ typeString isEqualToString: @"E" ] )
    {
        EOS_FTP_DEBUG( @"Switching to EBDIC connection type" );
        
        type = EOSFTPServerConnectionTypeEBCDIC;
    }
    else
    {
        EOS_FTP_DEBUG( @"Unknown type %@. Switching to ASCII connection type", typeString );
        
        type = EOSFTPServerConnectionTypeASCII;
    }
    
    connection.type = type;
    
    [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: @"%@\nType set to %@", [ self messageForReplyCode: 200 ], typeString ] code: 200 ] ];
}

- ( void )processCommandSTRU: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandMODE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandRETR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSTOR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSTOU: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandAPPE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandALLO: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandREST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandRNFR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandRNTO: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandABOR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandDELE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandRMD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandMKD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandPWD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandLIST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandNLST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSITE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSYST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandSTAT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

- ( void )processCommandHELP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSRange    range;
    NSString * name;
    
    range = [ args rangeOfString: @" " ];
    
    if( range.location != NSNotFound )
    {
        name = [ args substringToIndex: range.location ];
    }
    else
    {
        name = args;
    }
    
    EOS_FTP_DEBUG( @"Getting help for command %@", name );
    
    [ connection sendMessage: [ self formattedMessage: [ self helpForCommand: name ] code: 214 ] ];
}

- ( void )processCommandNOOP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )connection;
    ( void )args;
}

@end
