#NOT IN USE: RedisVSIO

########################################################################################################
# jetNEXUS custom health checking Copyright jetNEXUS 2015
########################################################################################################

# _[0] IP address of the server to be health checked
# _[1] Port of the server to be health checked
# 
# The script will return the following values
# 1 is the test is successful
# 2 if the test is unsuccessful


use IO::Socket;

sub monitor
{
    my $req   = "info\r\nquit\r\n"; # send command
    my $expect = "role:master"; # expect reply

    my $host   = $_[0];
    my $port   = $_[1];

    if (!$port) {
      $port = 6379;
    }

    my $socket = new IO::Socket::INET ( 
      PeerAddr => $host,
      PeerPort => $port,
      Proto    => 'tcp',
    ) or $err_msg = $@;

    if ($err_msg) {
      print "Redis health-check failed (socket): $err_msg\n";
      return(2);
    }

    $socket->autoflush(1);
    # $socket->timeout(5);

    # data to send to a server
    my $size = $socket->send($req);
    if ($size <= 0) {
      print "Redis health-check failed (send $size): $!\n";
      return(2);
    }
 
    # notify server that request has been sent
    # shutdown($socket, 1);
 
    # receive a response of up to 65535 characters from server
    my $response = "";
    $socket->recv($response, 65535);

    $socket->close();

    if ($response =~ /$expect/) {
      return(1);
    }

    print "Redis health-check $host:$port failed (expected response was not received)\n";
    return(2);
}

exit(monitor(@ARGV));
