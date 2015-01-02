#!/usr/bin/perl 


use DataDog::DogStatsd;
use File::Tail;
my $VERSION = "0.02";
my $PIDFILE = "/var/run/dogwatcher.pid";
my $LOGWAITINT=1;
my $QFILE = "/var/log/named/queries.log";
my $HOSTNAME= `hostname`;
chomp($HOSTNAME);
my %OPTS;
$OPTS->{'tags'} = $HOSTNAME;
open(PID,">$PIDFILE");
print PID $$ or die;
close(PID);


my %CLIENT_STATS;
my %REQUEST_STATS;
my %CLASS_STATS; 
my %TYPE_STATS;

my $stat = DataDog::DogStatsd->new();

@query_list=("A", "PTR", "ANY", "MX", "NS", "CNAME", "SOA", "SRV", "AAAA");
$SIG{'HUP'}='dump';
sub init {

}
sub getlogline {
	if(!defined($LFFD)){
		$LFFD = File::Tail->new(name=>$QFILE,maxinterval=>5,interval=>$LOGWAITINT);
		if(!defined $LFFD) {
			die "Can't open $QFILE.";
		}
	}
	return $LFFD->read;
}

init();
while ($l=getlogline) {
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
	elsif ($type eq "NS"){
		$stat->set('dns.query.ns',$request,%OPTS);
	}
	elsif ($type eq "MX"){
		$stat->set('dns.query.mx',$request,%OPTS);
	}
}

sub dump {
	foreach (keys %CLIENT_STATS){
		print "$_ ".$CLIENT_STATS{"$_"}."\n";
	}
	foreach (keys %REQUEST_STATS){
		print "$_ ".$REQUEST_STATS{"$_"}."\n";
	}
	die;
}
