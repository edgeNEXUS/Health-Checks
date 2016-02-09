#Monitor-Name: 401 Challenge HTTPS
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
# _[3] Server Notes - that content server, allowing server-unique values, like username and password
# _[4] Page location - use this to set the path or page
# _[5] Used if the server needs authentication
# _[6] Used if the server needs authentication
# _[7] Used if the monitor requires a threshold such as CPU or memory percentage
# 
# The script will return the following values
# 1 is the test is successful
# 2 if the test is un successful
#
# The script can also send information to be logged by:


sub monitor
{
	my $host       = $_[0];	### Host IP
	my $port       = $_[1];	### Host Port
	my $content    = $_[2];	## INPUT: domain/username%password
	my $notes      = $_[3];	### Not used in this monitor
    my $page       = $_[4];     ### Not used yet: Future WEB ADDRESS from the CSM Page Location Column
	my $username   = $_[5]; ### Used if the server needs authentication
	my $password   = $_[6]; ### Used if the server needs authentication
    my $threshold  = $_[7]; ### Not used in this monitor
	
	args[0] := address
    args[1] := port
    args[2] := content
    args[3] := notes
    args[4] := page
    args[5] := username
    args[6] := password
    args[7] := threshold
#	my ($uid,$pwd) = split /\%/, $content;
#	my @lines      = `/preset/wget -q --user=${uid} --password=${pwd} --no-check-certificate --output-document=- https://${host}:${port}${notes}`; 	
    my @lines      = `/preset/wget -q --user=${username} --password=${password} --no-check-certificate --output-document=- https://${host}:${port}${page}`;

	if ($#lines > -1)
	{	
		print "401 Challenge check successful\n";
		return(1);
	}
	else
	{
		print "401 Challenge check failed.\n";
		return(2)
	}			
}	