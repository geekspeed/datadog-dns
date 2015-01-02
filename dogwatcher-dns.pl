#!/usr/bin/perl 


use DataDog::DogStatsd;

my $QFILE = "/var/log/named/queries.log";
open(Q, $QFILE) or die "$! -> $QFILE";

my $HOSTNAME= `hostname`;
chomp($HOSTNAME);
my %OPTS;
$OPTS->{'tags'} = $HOSTNAME;
my %CLIENT_STATS;
my %REQUEST_STATS;
my %CLASS_STATS; 
my %TYPE_STATS;

my @DATA = <Q>;
close(QFILE);
my $stat = DataDog::DogStatsd->new();

foreach $l (@DATA){
	my @L = split(' ',$l);
	my $i = 0;
	my $client = $L[3];
	$client =~ s/#.*//;
	my $request = $L[5];
	my $class = $L[6];
	my $type = $L[7];
	#print "Request from $client for $request $class $type\n";
	if($client){
		$CLIENT_STATS{"$client"}++;
		$stat->set('dns.query.client',$client,%OPTS);
	}
	$REQUEST_STATS{"$request"}++;
	$CLASS_STATS{"$class"}++;
	$TYPE_STATS{"$type"}++;
	if ($type eq "A"){
		$stat->set('dns.query.a',$request,%OPTS);
	}
	elsif ($type eq "PTR"){
		$stat->set('dns.query.ptr',$request,%OPTS);
	}
	elsif ($type eq "SRV"){
		$stat->set('dns.query.srv',$request,%OPTS);
	}
	elsif ($type eq "SOA"){
		$stat->set('dns.query.soa',$request,%OPTS);
	}
	elsif ($type eq "IXFR"){
		$stat->set('dns.query.ixfr',$request,%OPTS);
	}
}
foreach (keys %CLIENT_STATS){
		#print "$_ ".$CLIENT_STATS{"$_"}."\n";
}
foreach (keys %REQUEST_STATS){
		#print "$_ ".$REQUEST_STATS{"$_"}."\n";
}

