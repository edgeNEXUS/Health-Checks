#Monitor-Name:TCP Out of Band

use strict;
use warnings;
use lib '/jetnexus/etc/logs/monitoring/preset'; # For load from Pascal, at this moment no current dir
#use Sys::Syslog;
use jnIpv6;
use Socket;

# To debug, uncomment use Sys::Syslog, openlog and desired line(s) in debprt
sub debprt {
  #print @_,"\n";
  #syslog('notice',@_);
}
sub debaif {
  my $r = $_[0];
  my $fam;
  my $adr;
  my $len;
  my $prot;
  my ( $err, $host, $service );
  my $typ;
  $fam = $r->{family};
  $typ = $r->{socktype};
  $prot = $r->{protocol};
  $adr = $r->{addr};
  $len = length($adr);
  ( $err, $host, $service ) = getnameinfo( $adr, 3 );
  debprt("fam=$fam typ=$typ prot=$prot len=$len err=$err host=$host service=$service");
}
sub debaifs {
  my $cnt = scalar @_;
  my $i;
  for ($i=0;$i<$cnt;$i++) {
    debprt ("i=$i");
    debaif ($_[$i]);
  }
}

sub monitor
{
  #openlog('custommonitor','ndelay,pid','user');
  my $cnt = scalar @_;
  my $ipaddr = $_[0];
  my $param0 = $_[1];
  my $param1 = ($cnt>2) ? $_[2] : ""; #required content
  my $param2 = ($cnt>3) ? $_[3] : ""; #server notes
  my $port;
  
  # Take a decision for setting to use
  # Look to Notes first
  $port = $param2;
  if($port eq "") {
    # Use some default setting from Content otherwise
    $port = $param1;
  }
  if($port eq "") {
    # Use port setting from content servers
    $port = $param0;
  }

  my ( $err, @res );
  my $proto = getprotobyname('tcp');

  debprt ("ipaddr=$ipaddr port=$port proto=$proto");
  ( $err, @res ) = getaddrinfo( $ipaddr, $port, { socktype => SOCK_STREAM, protocol => $proto } );
  debprt "err=$err res=@res";
  debaifs(@res);
  
  if( $err ) {
    print "TCP health-check failed (hostname): $err\n";
    return 2;
  }
  
  $cnt = scalar @res;
  my $ind = int(rand($cnt));
  debprt("selected $ind -th of $cnt");
  my $socket;

  if(!socket($socket, $res[$ind]->{family}, SOCK_STREAM, $proto)) {
    print "TCP health-check failed (socket): $!\n";
    debprt ("socket S!");
    return 2;
  }
  
  if(!connect($socket, $res[$ind]->{addr})) {
    print "TCP health-check failed (connect): $!\n";
    debprt("connect $!");
    close ($socket);
    return 2;
  }

  debprt("success");
  close ($socket);
  return 1;  
}

# Test from command line - enter something like
# perl tcp.pl www.google.com 80
print "Entered @ARGV\n";
my $res = monitor(@ARGV);
print "result=$res\n";
