#Monitor-Name:Multi port TCP monitor
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

  my @ports = split(',', $param1);
  if(scalar @ports == 0) {
    @ports = split(',', $param0);
  }
  my ( $err, @res, $ind, $r);
  my $socket;
  my $proto = getprotobyname('tcp');
  foreach my $port (@ports) {
    ( $err, @res ) = getaddrinfo( $ipaddr, $port, { socktype => SOCK_STREAM, protocol => $proto } );
    debprt "err=$err res=@res ipaddr=$ipaddr port=$port";
    if( $err ) {
      print "TCP health-check failed (hostname): $err\n";
      debprt "TCP health-check failed (hostname): $err";
      return 2;
    }
    $cnt = scalar @res;
    if( $cnt == 0 ) {
      print "TCP health-check failed (hostname)\n";
      debprt "TCP health-check failed (hostname)";
      return 2;
    }
    $ind = int(rand($cnt));
    debprt("selected $ind-th of $cnt");
    $r = $res[$ind];
    debaif ($r);
    
    if(!socket($socket, $r->{family}, SOCK_STREAM, $proto)) {
      print "TCP health-check failed (socket): $!\n";
      debprt "TCP health-check failed (socket): $!";
      return 2;
    }

    if(!connect($socket, $r->{addr})) {
      print "TCP health-check failed (connect): $!\n";
      debprt "TCP health-check failed (connect): $!";
      close ($socket);
      return 2;
    }
    
    close ($socket);
  }

  debprt("success");
  return 1;
}

# Test from command line - enter something like
# perl tcpmulti.pl 192.168.2.200 80 "80,443"
print "Entered @ARGV\n";
my $res = monitor(@ARGV);
print "result=$res\n";
