#!/usr/bin/perl -w

#to connect by telnet to Cisco routers launch the show interfaces command and catch the response

use Net::Telnet;

$telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die');

$telnet->open($ARGV[0]);
$telnet->waitfor('/sername:($|\s)/i');
$telnet->print('userx');
$telnet->waitfor('/assword:($|\s)/i');
$telnet->print('xxx');
$telnet->waitfor('/(>|#)/');

#to avoid the terminal pause and get the full response of the commands

$telnet->print("terminal length 0");
$telnet->waitfor('/#/');

$telnet->print('sh interfaces'); 
($buff) = $telnet->waitfor("/#/");

print $buff;
