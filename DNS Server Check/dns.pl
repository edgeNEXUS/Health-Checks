#Monitor-Name:DNS Server check
# Usage
# RS IP should be DNS server
# RS port ignored, 53 used
# Page Location - address to resolve using this DNS
# Required Content (optional) - numeric ipv4 or ipv6, which should be received by resolving
#   If multiple addresses returned, Required Content should match any of them
#   If Required Content not specified, any reasonable answer is considered good
# To debug, uncomment use Sys::Syslog, openlog and desired line(s) in debprt
use strict;
use warnings;
use lib '/jetnexus/etc/logs/monitoring/preset'; # For load from Pascal, at this moment no current dir
#use Sys::Syslog;
use jnIpv6;
use Socket;
use bytes;

my $respsize;
my $buf;

# to debug from command line, uncomment print, from program - uncomment syslog
sub debprt {
  #print @_,"\n";
  #syslog('notice',@_);
}
# print always uncommented. to debug from program, uncoment syslog
sub prt {
  print @_,"\n";
  #syslog('notice',@_);
}
sub tohex {
  my $r = $_[0];
  my $n = length($r);
  my $i = 0;
  my $res = "";
  for ($i=0; $i<$n; $i++) {
    $res .= unpack("x[$i]H2",$r);
  }
  return $res;
}
sub getbytes {
  my $r = $_[0];
  my $pos = $_[1];
  my $len = $_[2];
  my $n = length($r);
  if (($pos + $len) > $n) {
    $len = $n - $pos;
    if ($len <=0) {
      return "";
    }
  }
  my $res = unpack("x[$pos]A$len",$r);
  return $res;
}
sub getsinaddr {
  my $r = $_[0];
  my $n = length($r);
  my $res = "";
  if ($n==16) {
    $res = getbytes($r,4,4);
  }
  if ($n==28) {
    $res = getbytes($r,8,16);
  }
  return $res;
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

sub monitor
{
  #openlog('custommonitor','ndelay,pid','user');
  my $args = @_;
  if ($args < 5) {
    prt "Too few arguments: @_";
    return 2;
  }
  my ($host,$port,$content,$notes,$page) = @_;
  $host =~ s/^\s+|\s+$//g;
  $content =~ s/^\s+|\s+$//g;
  $page =~ s/^\s+|\s+$//g;
  my $page0 = $page;
  if($page eq '') {$page = "www.jetnexus.com";}
  debprt "args=$args host=$host port=$port content=$content notes=$notes page=$page";
  
  my ( $err, @res );
  my $cnt;
  # if content specified, it should be numeric IP, otherwise we never get anything
  my $contentbin = "";
  if ($content ne '') {
    ( $err, @res ) = getaddrinfo( $content, 53);
    debprt "err=$err res=@res";
    if( $err ) {
      prt "DNS health-check failed (invalid Required Content): $err";
      return 2;
    }
    $cnt = scalar @res;
    if( $cnt == 0 ) {
      prt "DNS health-check failed (invalid Required Content): $err";
      return 2;
    }
    $contentbin = getsinaddr($res[0]->{addr});
    debprt "contentbin=".tohex($contentbin);
  }
  
  my $timeout=3; # 3 seconds
  
  my ($header,$question,$lformat,@labels,$count,$sock,$rc);
  my ($position,$qname,$qtype,$qclass);
  my $id = 0;
  
  $header = pack("n C2 n4", 
    ++$id,  # query id
    1,  # qr, opcode, aa, tc, rd fields (only rd set)
    0,  # rd, ra
    1,  # one question (qdcount)
    0,  # no answers (ancount)
    0,  # no ns records in authority section (nscount)
    0); # no addtl rr's (arcount)

  for (split(/\./,$page)) {
    $lformat .= "C a* ";
    $labels[$count++]=length;
    $labels[$count++]=$_;
  }
  debprt "id=$id lformat=$lformat labels=@labels";
  
  my $proto = getprotobyname('udp');
  debprt "proto=$proto";
  ( $err, @res ) = getaddrinfo( $host, 53, { socktype => SOCK_DGRAM, protocol => $proto } );
  debprt "err=$err res=@res";
  if( $err ) {
    prt "DNS health-check failed (hostname): $err\n";
    return 2;
  }
  $cnt = scalar @res;
  if( $cnt == 0 ) {
    prt "TCP health-check failed (hostname)";
    return 2;
  }
  my $ind = int(rand($cnt));
  debprt("selected $ind -th of $cnt");
  my $resdns = $res[$ind];
  debaif($resdns);
  
  foreach my $qtypereq (1,28) {
    debprt "qtypereq=$qtypereq";
    $question = pack($lformat."C n2",
  		@labels,
  		0,  # end of labels
  		$qtypereq,  # qtype of A 
  		1); # qclass of IN
  
    my ($deb1, $deb2);
      
    if(!socket($sock, $resdns->{family}, SOCK_DGRAM, $proto)) {
    #if(!socket($sock, PF_INET, SOCK_DGRAM, $proto)) {
      prt "DNS health-check failed (socket): $!\n";
      return 2;
    }
    debprt "socket done";
    $deb1 = setsockopt($sock, SOL_SOCKET, SO_RCVTIMEO, pack('l!l!', $timeout, 0));
    debprt "setsockopt=$deb1";
    my $sndlen = send($sock, $header.$question, 0, $resdns->{addr});
    debprt "sndlen=$sndlen";
    my $rcvrc = recv($sock, $buf, 512, 0);
    close($sock);
    if (! defined $rcvrc) {
      prt "DNS health-check failed (recv): $!\n";
      return 2;
    }
    $respsize = length($buf);
    debprt "respsize=$respsize";
    if ($respsize==0) {
      prt "DNS health check failed ($host could not resolve $page)";
      return 2;
    }
    
  
    my ($qr_opcode_aa_tc_rd,$rd_ra,$qdcount,$ancount,$nscount,$arcount);
    ($id,
       $qr_opcode_aa_tc_rd,
       $rd_ra,
       $qdcount,
       $ancount,
       $nscount,
       $arcount) = unpack("n C2 n4",$buf);
    debprt "qr_opcode_aa_tc_rd=$qr_opcode_aa_tc_rd rd_ra=$rd_ra qdcount=$qdcount ancount=$ancount nscount=$nscount arcount=$arcount";
    if ($page0 eq '') { # received answer - therefore, it is DNS
      return 1;
    }
    if (!$ancount) {
      prt "DNS health check failed ($host could not resolve $page)";
      return 2;
    }
    if ($content eq '') {
      return 1;
    }
    
  
    ($position,$qname) = &decompress(12);
    debprt "position=$position qname=$qname";
    ($qtype,$qclass)=unpack('@'.$position.'n2',$buf);
    debprt "qtype=$qtype qclass=$qclass";
    $position += 4;
    
    my $resbin;
    my ($rname,$rtype,$rclass,$rttl,$rdlength);
    for ( ;$ancount;$ancount--){
  	  ($position,$rname) = &decompress($position);
      debprt "position=$position rname=$rname";
  	  ($rtype,$rclass,$rttl,$rdlength) = unpack('@'.$position.'n2 N n',$buf);
  	  debprt("rtype=$rtype rclass=$rclass rttl=$rttl rdlength=$rdlength ");
  	  $position +=10;
      # this next line could be changed to use a more sophisticated 
      # data structure, it currently picks the last rr returned  
      if ($rtype==1 || $rtype==28) { 
        $resbin = getbytes($buf,$position,$rdlength);
        debprt "resbin=".tohex($resbin);
        if (($resbin cmp $contentbin)==0) {
          debprt "success";
          return 1;
        }
      }
  	  $position +=$rdlength;
      debprt "position=$position rname=$rname";
    }
  }
  prt "DNS health check failed ($host did not return $content for $page)";
  return 2;
  
}

sub decompress { 
    my($start) = $_[0];
    my($domain,$i,$lenoct);
    
    for ($i=$start;$i<=$respsize;) { 
	    $lenoct=unpack('@'.$i.'C', $buf); # get the length of label

	    if (!$lenoct){        # 0 signals we are done with this section
	        $i++;
	        last;
	    }

	    if ($lenoct == 192) { # we've been handed a pointer, so recurse
	        $domain.=(&decompress((unpack('@'.$i.'n',$buf) & 1023)))[1];
	        $i+=2;
	        last
	    }
	    else {                # otherwise, we have a plain label
	        $domain.=unpack('@'.++$i.'a'.$lenoct,$buf).'.';
	        $i += $lenoct;
	    }
    }
    return($i,$domain);
}

# test from command line
# usage:
# perl dns.pl DNS-server something desired-result-or-empty something name-to-resolve-or-empty
print "Entered @ARGV\n";
my $res = monitor(@ARGV);
print "result=$res\n";
