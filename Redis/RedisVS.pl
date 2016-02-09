#NOT IN USE: RedisVS

########################################################################################################
# jetNEXUS custom health checking Copyright jetNEXUS 2015
########################################################################################################

# _[0] IP address of the server to be health checked
# _[1] Port of the server to be health checked
#
# The script will return the following values
# 1 is the test is successful
# 2 if the test is unsuccessful

use Socket;

sub monitor
{
    my $msg    = "info\r\nquit\r\n"; # send command
    my $expect = "role:master"; # expect reply

    my $host   = $_[0];
    my $port   = $_[1];

    if (!$port) {
        $port = 6379;
    }

    $| = 1;

    my ($sock, $addr, $proto);

    $addr = sockaddr_in($port, inet_aton($host));
    $proto = getprotobyname('tcp');

    if(!socket($sock, PF_INET, SOCK_STREAM, $proto)) {
        print "Redis health-check $host:$port failed (socket): $!\n";
        return 2;
    }

    if(!connect($sock, $addr)) {
        print "Redis health-check $host:$port failed (connect): $!\n";
        close ($sock);
        return 2;
    }

    if(!send ($sock, $msg, 0)) {
        print "Redis health-check $host:$port failed (send): $!\n";
        close ($sock);
        return 2;
    }

    while (my $line = <$sock>) {
        if ($line =~ /$expect/) {
            close ($sock);
            return(1);
        }
    }

    close ($sock);
    print "Redis health-check $host:$port failed (expected response was not received)\n";
    return(2);
}

exit(monitor(@ARGV));
