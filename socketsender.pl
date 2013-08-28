#!/usr/bin/perl

#script to tail multiple files , parser the right events and send them to a receiver to collect and process into a log file or DB

use File::Tail::Multi;
use IO::Socket;
use Data::Dumper;
use Env qw(LD_LIBRARY_PATH);
use Carp qw( croak );
use Switch;


# files to tail

@files = ('/var/opt/SUNWappserver/nodeagents/am-agent01/am-instance01/logs/gclog','/var/opt/SUNWam/logs/amAuthentication.access');

#Receiver connection parameters

$receiver = "coloso51.wnet";
$port = "7075";

#number lines to tail => tail -100

$logline = 100;

#variables to store memory information

$mem_total;
$mem_used ;


#load its own old library files to avoid imcompatibity with older Solaris versions.

BEGIN {

push (@INC, "/aplicaciones/monitoriza/lib/");

push (@LD_LIBRARY_PATH, "/aplicaciones/monitoriza/lib:/usr/openwin/lib:/usr/local/lib/");


}


#connects with the receiver at coloso51.wnet:7075

$socket = new IO::Socket::INET (PeerAddr => $receiver,
                                    PeerPort => $port,
                                    Proto    => "tcp",
                                    Type     => SOCK_STREAM)
or die "Can't connect to $remote_host:$remote_port : $!\n";


$tail = File::Tail::Multi->new (  OutputPrefix => "p",
                      Function => \&_read_line,
                      Debug => "0",
                      RemoveDuplicate => "0",
                      NumLines => $logline,
                      Files => @files
        			
				);


while(1) {

                $tail->read;
                my $timestamp = Timestamp(time);
                print $socket "gclog --> [$timestamp] $mem_total -- $mem_used \n";
			
         }


$tail->close_all_files;
close($socket);

sub Timestamp {

  my ($time) = (@_);

  my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($time);

  if(length($hour) == 1) {
    $hour = "0" . $hour;
  }

  if(length($min) == 1) {
    $min = "0" . $min;
  }

  if(length($sec) == 1) {
    $sec = "0" . $sec;
  }

  # Set to 2 digit month from 01 to 12
  $month += 1;

  if(length($month) == 1) {
    $month = "0" . $month;
  }

  # Set to 2 digit day

  if(length($mday) == 1) {
    $mday = "0" . $mday;
  }

  # Use four digit year ($year is a value based on # of years since 1900)

  $year += 1900;

  return("$mday-$month-$year:$hour:$min:$sec");
}

sub _read_line {

	$lines_ref = shift;

        foreach ( @{$lines_ref} ) {

		#delete the CR

                chomp;

		#extracts the log filename from the line that contains the path + filename
            
		if ( ($log) = ( $_ =~ m/^\/var\/.*\/logs\/(\w+|\w+\.\w+)\s+\:\s+.*/ ) ){


		switch ($log) {

                        case "amAuthentication.access"  {

				if ( ($ano,$mes,$dia,$hora,$min,$sec,$op) = ( $_ =~ m/^\/var\/.*\/logs\/amAuthentication.access\s+\:\s+\"(\d{4})\-(\d{2})\-(\d{2})\s+(\d{2})\:(\d{2})\:(\d{2})\".*(AUTHENTICATION\-\d+)\s+.*/ ) ){}

		
                                                                                                           }
							}#case del amAuthentication.access


			 case "gclog"    {

                		if ( ($mem_total_tmp,$mem_used_tmp) = ( $_ =~ m/^\/var\/.*\/logs\/gclog\s+\:.*concurrent mark\-sweep\s+generation\s+total\s+(\d+)K\,\s+used\s+(\d+)K\s+\[.*/ )){}

                                                        }#case gclog


				}#switch
             
										}#del if del $log

                next if $_ =~ //;

                                if (!defined($socket)) {

                                	close($socket);
                                	exit(0);
                                                	}

                     }


}
