#Monitor-Name:HTTPS_WithAuthToken

use strict;
use warnings;
########################################################################################################
# Edgenexus custom health checking Copyright jetNEXUS 2017
########################################################################################################
#
#
# This is a Perl script for Edgenexus custom health checking
# The monitor name as above is displayed in the dropdown of Available health checks
# There are 7 values passed to this script (see below)
#
# This script first sends a POST request "username=$user&password=$password&f=json" to an URL 
# defined as $host:$port$notes in order to obtain an authentication token string and stores it
# in $token variable. 
# Then the script sends a GET request to an URL defined as $host:$port$page$token and looks for
# a string $content in the GET response.
# If the string $content is found, the script returns success, otherwise fail.
#
# The script returns the following values:
# 1 if the test is successful
# 2 if the test is unsuccessful
#
# Please see JNALB-8165 for details.
#


sub monitor
{
    my $host       = $_[0];     ### Host IP or name
    my $port       = $_[1];     ### Host Port
    my $content    = $_[2];     ### Content to look for (in the web page and HTTP headers)
    my $notes      = $_[3];     ### Authentication POST request path (part of the URL after host address and port)
    my $page       = $_[4];     ### Data GET request path (part of the URL after host address and port)
    my $user       = $_[5];     ### Username
    my $password   = $_[6];     ### Password
    my $token;

    if (!defined($host) || !defined($content) || !defined($notes) || !defined($page) || !defined($user) || !defined($password)) {
        print "Usage: $0 <host address>[:port] <content> <authentication POST request path> <data GET request path> <user name> <password>\n";
        return(2);
    }

    if ($port) 
    {
        $host = "$port:$host";
    }

    my $auth_path = $notes;
    my $auth_post = "username=$user&password=$password&f=json";
    my $data_path = $page;

    # Get auth token
    #
    # Example response:
    # { 
    #  "token":"00000060\/Bwn6JXuLbCOoSOlPyg1Cv+hvH+wIWvvUnFAICAgvKgIEQ\/0LyFKRQbHTMv68y8wrtqe9E6XcDkI4Kg2KBxuCw==",
    #  "expires":1495453595272
    # }

    my $url = "'https://${host}${auth_path}'";
    my @lines = `curl -s -i --retry 1 --max-time 1 -k -d "$auth_post" $url 2>&1`;
    if (join("", @lines) =~ /"token":"(\S+)"/)
    {   
        $token = $1;
    }
    else
    {
        print "https://${host}${auth_path} failed to get authentication token - Healthcheck check failed.\n";
        return(2);
    }

    # Check content
    $url = "'https://${host}${data_path}${token}'";
    @lines = `curl -s -i --retry 1 --max-time 1 -k $url 2>&1`;
    if (join("", @lines) =~ /$content/)
    {   
        print "https://${host}${data_path} looking for - $content - Healthcheck check successful.\n";
        return(1);
    }
    else
    {
        print "https://${host}${data_path} looking for - $content - Healthcheck check failed.\n";
        return(2);
    }
}

monitor(@ARGV);
