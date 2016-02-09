#Monitor-Name: https custom
use strict;
use warnings;
########################################################################################################
# jetNEXUS custom health checking Copyright jetNEXUS 2013
########################################################################################################
#
#
# This is a Perl script for jetNEXUS customer health checking
# The monitor name as above is displayed in the dropdown of Available health checks
# There are 4 value passed to this script
#
# _[0] IP address of the server to be health checked
# _[1] Port of the server to be health checked
# _[2] Required content - additional data can be passed to health check from the GUI
# _[3] Server Notes - rom that content server, allowing server-unique values, like username and password
#
# The script will return the following values
# 1 is the test is successful
# 2 if the test is un successful
#
# The script can also send information to be logged by:


sub monitor
{
    my $host       = $_[0];	### Host IP or name
    my $port       = $_[1];	### Host Port
    my $content    = $_[2];	### INPUT: domain/username%password
    my $notes      = $_[3];	### INPUT: Path i.e.  /gary/index.html
    my $page       = $_[4];	### Not used yet: Future WEB ADDRESS from the CSM Page Location Column
    #my ($uid,$pwd) = split /\%/, $content;

    if ($port)
    {
        $host = "$host:$port";
    }
    my @lines      = `/usr/bin/wget -q -S --tries=1 --timeout=1 --no-check-certificate --output-document=- https://$host$notes 2>&1`;
    if (join("",@lines) =~ "$content")
    {	
	print "https://$host$notes looking for - $content - Healhcheck check successful\n";
	return(1);
    }
    else
    {
	print "https://$host$notes looking for - $content - Healhcheck check failed.\n";
	return(2)
    }

}

monitor(@ARGV);
