#!/usr/bin/perl -w

#script use to connect to Cisco Router by script and launch the show interfaces command

use Net::Telnet;

$telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die');

$telnet->open($ARGV[0]);
$telnet->waitfor('/sername:($|\s)/i');
$telnet->print('userx');
$telnet->waitfor('/assword:($|\s)/i');
$telnet->print('xxx');
$telnet->waitfor('/(>|#)/');

$telnet->print("terminal length 0");
$telnet->waitfor('/#/');

$telnet->print('sh interfaces'); 
($buff) = $telnet->waitfor("/#/");

print $buff;
