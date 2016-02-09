#NOT IN USE:RedisVSNC
#
########################################################################################################
# jetNEXUS custom health checking Copyright jetNEXUS 2015
########################################################################################################
#
# _[0] IP address of the server to be health checked
# _[1] Port of the server to be health checked
# 
# The script will return the following values
# 1 is the test is successful
# 2 if the test is unsuccessful

sub monitor
{
    my $send   = "info\r\nquit\r\n"; # send command

    my $host   = $_[0];
    my $port   = $_[1];
    my $expect = $_[2]; # required content - expected reply

    if (!$host) {
      print "Redis health-check failed (host address not specified)\n";
      return(2);
    }


    if (!$port) {
      $port = 6379;
    }

    my $response = `echo -e "$send" |nc -w 5 $host $port`;

    if ($response =~ /$expect/) {
      return(1);
    }

    print "Redis health-check $host:$port failed (expected response was not received)\n";
    return(2);
}

exit(monitor(@ARGV));
