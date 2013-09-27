#! /usr/bin/perl
 
## script to launch snmp requests to the routers farm                        ##
## to get and save all kinds of information (uptime,firmware,hardware,..)    ##
## into the DB for the dynamic inventory web tool                            ##

use Net::SNMP;
use Switch;
use DBI;

# snmp connection details #

$comunity = "comunity";			   # authentication 
 
# end snmp connection details #

# OID declaration     #

my $OID_version    = '1.3.6.1.2.1.1.1.0';  # Complete Device Description
my $OID_sysUpTime   = '1.3.6.1.2.1.1.3.0'; # Uptime
my $OID_Hw   = '1.3.6.1.2.1.1.2.0';        # Hardware details

# end OID declaration #

# hashes    #

my %hash;
my %firmhash;
my %hardhash;
my %equipohash;
my %proveedorhash;
my %idshash;

# end hashes #

# dB connection details #

$dbh = DBI->connect('DBI:mysql:db_name', 'db_user','db_pass',
            {
             'PrintError' => 1,
             'RaiseError' => 1
            });

# end dB connection details #

# we load the most used information to avoid latencies    #
# due to the high number of devices to request            #  
# every new information found is automatically update it  #

#loads ids vs names from the data table

get_ids();

#loads the hostnames

hash_equipos();

#loads the cisco hardware

hash_ciscoid();

#loads the ios

hash_ios();

#loads hw

hash_hw();

#loads provider information

hash_proveedor();


# Launch the snmp requests with the right OID's #

foreach $equipo (sort keys %equipohash) {

my ($session, $error) = Net::SNMP->session(
      -hostname  => shift || $equipo,
      -community => shift || $comunity,
   );

   if (!defined $session) {
      printf "ERROR: %s.\n", $error;
      next; #evito q salga el proceso
   }

   my $result = $session->get_request(-varbindlist => [$OID_sysUpTime,$OID_version,$OID_Hw]);

   if (!defined $result) {
      printf "ERROR: %s.\n", $session->error();
      $session->close();
      next;
   }

## R.E. matchs the provider information to get useful values of the hardware, ios and uptime from each host.

    if ( ($tecnologia) = ( $result->{$OID_version} =~ m/(Juniper Networks|Cisco|Alcatel-Lucent).*/) ){

		switch($tecnologia) {
  			
  
			case "Juniper Networks" {

			if ( ($hw,$ios) = ( $result->{$OID_version} =~ m/^Juniper Networks\,\s+Inc\.\s+(.*)\,\s+kernel JUNOS\s+(.*)\#.*/) ){}; }
									 
  
			case "Cisco" {


			if ( ($ios) = ( $result->{$OID_version} =~ m/.*IOS.*Version\s+(.*).\s+.*/) ){}$hw=$hash{$result->{$OID_Hw}};}
				    	
                        case "Alcatel-Lucent" {


                        if ( ($ios,$hw) = ( $result->{$OID_version} =~ m/(.*)\s+.*\s+ALCATEL\s+(.*\s+.*)\s+Copyright.*Alcatel.Lucent.*/) ){}; }
                                        

				     }


					    }


    if ( ($uptime) = ( $result->{$OID_sysUpTime} =~ m/^(.*\s+.*),.*/) ){
                                        }


  
   #updates the ios hash + db if it does not exist
 
   if ( $firmhash{$ios} == 0 ){inserta_ios($ios);}

   #updates the hardware hash + db if it does not exist

   if ( $hardhash{$hw} == 0 ){inserta_hw($hw);}

   #updates the hostname hash + db if it does not exist

   if ( $idshash{$equipo} == 0 ){ 

		inserta_datos($equipohash{$equipo},$firmhash{$ios},$hardhash{$hw},$proveedorhash{$tecnologia},$uptime);
   
                                }else{ updatea_datos($equipohash{$equipo},$firmhash{$ios},$hardhash{$hw},$proveedorhash{$tecnologia},$uptime);
   									
				     } 

   $session->close();


}#del foreach


close IN;
$dbh->disconnect;
exit 0;

sub inserta_ios
{


    $query="INSERT into firmware (firmware) VALUES ('". $_[0] . "')";

    $sth = $dbh->prepare($query);
    $sth->execute();

    #updates the hash with the new firmware information
    hash_ios();


    $sth->finish;



}

sub inserta_hw
{

    $query="INSERT into hardware (hardware) VALUES ('". $_[0] . "')";
 
    $sth = $dbh->prepare($query);
    $sth->execute();

    #updates the hash with the new hardware information
    hash_hw();

  
    $sth->finish;

}

sub inserta_datos
{

    #0 hostname
    #1 ios
    #2 hw
    #3 provider
    #4 uptime	


    $query="INSERT into datos (equipo,firmware,hardware,proveedor,uptime,sede,servicio,capa) VALUES ('". $_[0] . "','". $_[1] . "','". $_[2] . "','" . $_[3] . "','" . $_[4] . "','4','4','7')";

  
    $sth = $dbh->prepare($query);
    $sth->execute();
    $sth->finish;


}

sub updatea_datos
{

    #0 hostname
    #1 ios
    #2 hw
    #3 provider
    #4 uptime


    $query="update datos set uptime='".$_[4]."',firmware='".$_[1]."',hardware='".$_[2]."' where equipo='".$_[0]."'";

 

    $sth = $dbh->prepare($query);
    $sth->execute();
    $sth->finish;


}



sub hash_equipos
{

    %equipohash = ();

    $query="SELECT id_equipo,equipo from equipos";

    $sth = $dbh->prepare($query);
    $sth->execute();

while (@data = $sth->fetchrow_array()) {

        $idequipo = $data[0];
        $equipo = $data[1];
        $equipohash{"$equipo"} .= exists $equipohash{"$equipo"} ? "$idequipo" : $idequipo;
 	


}#while hash firmwares

     $sth->finish;

}


sub hash_ios
{

    %firmhash = ();

    $query="SELECT id_firmware,firmware from firmware";

    $sth = $dbh->prepare($query);
    $sth->execute();

while (@data = $sth->fetchrow_array()) {

        $idfirmware = $data[0];
        $firmware = $data[1];
        $firmhash{"$firmware"} .= exists $firmhash{"$firmware"} ? "$idfirmware" : $idfirmware;


}#while hash firmwares

     $sth->finish;

}

sub hash_hw
{

    %hardhash = ();

    #cargo el hw en un hash

    $query="SELECT id_hardware,hardware from hardware";

    $sth = $dbh->prepare($query);
    $sth->execute();

while (@data = $sth->fetchrow_array()) {

        $idhardware = $data[0];
        $hardware = $data[1];
        $hardhash{"$hardware"} .= exists $hardhash{"$hardware"} ? "$idhardware" : $idhardware;



}#while hash hardwares

     $sth->finish;

}

sub hash_ciscoid
{

#loads the Cisco SysOid into the hash

open(IN, "/home/scripts/oidhwcisco")
  or die "No puedo abrir file por: $!";
while (<IN>) {

  chomp;
  my ($val, $key) = split /==/;
  $hash{$key} .= exists $hash{$key} ? "$val" : $val;

}

}

sub get_ids

{

    %idshash = ();

    $query="select equipos.equipo,datos.equipo as id_equipo from equipos,datos where equipos.id_equipo=datos.equipo;";

    $sth = $dbh->prepare($query);
    $sth->execute();

while (@data = $sth->fetchrow_array()) {

	$id_equipo = $data[1];
        $nombre_equipo = $data[0];
        $idshash{"$nombre_equipo"} .= exists $idshash{"$nombre_equipo"} ? "$id_equipo" : $id_equipo;

}#while hash firmwares

     $sth->finish;

}

sub hash_proveedor
{

    $query="select id_proveedor,proveedor from proveedor";

    $sth = $dbh->prepare($query);
    $sth->execute();

while (@data = $sth->fetchrow_array()) {

        $idprovider = $data[0];
        $provider = $data[1];
        $proveedorhash{"$provider"} .= exists $proveedorhash{"$provider"} ? "$idprovider" : $idprovider;


}#while hash hardwares

     $sth->finish;

}
