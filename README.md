![Edgenexus Logo](/edgenexus_logo_small.png)

# Healthchecks

Server and application Health Checks monitors. 

The edgeNEXUS load balancer and ADP platform can run customised application health checks.

They are based on Perl and can be passed a number of  parameters from the GUI.

There are a number of examples on github you can use

Information is passed to the script using the following variables:

my $host            = $_[0];               ### Host IP or name taken from the Real server IP address

my $port            = $_[1];               ### Host Port taken from the Real Server config

my $content      = $_[2];               ### INPUT: required content to check e.g. Server Up

my $notes          = $_[3];               ### INPUT: url/Path i.e.  192.168.101.201/gary/index.html

my $page           = $_[4];                ### Data GET request path (part of the URL after host address and port)

my $user            = $_[5];                ### Username

my $password  = $_[6];                ### Password

The script will return the following values

1 is the test is successful

2 if the test is un-successful
