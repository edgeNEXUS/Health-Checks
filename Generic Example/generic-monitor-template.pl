#Monitor-Name:My Custom Monitor v2.0

########################################################################################################
# EdgeNEXUS Custom Health Check Monitor Template
# Copyright edgeNEXUS 2026
########################################################################################################
#
# DESCRIPTION:
#   This is a template for creating custom health check monitors for EdgeADC.
#   The monitor name on line 1 (after #Monitor-Name:) appears in the EdgeADC GUI
#   dropdown list of available health checks.
#
# HOW IT WORKS:
#   - EdgeADC calls this script periodically to check if a real server is healthy
#   - Return 1 = Server is UP (healthy)
#   - Return 2 = Server is DOWN (unhealthy)
#   - The script MUST exit within the timeout period or the server is marked DOWN
#
# PARAMETERS PASSED BY EDGEADC:
#   $host      - Target server IP address or hostname
#   $port      - Target server port (may be empty if using default)
#   $content   - Content field from monitor configuration (use for custom data)
#   $notes     - Notes field (typically not used in scripts)
#   $page      - Page/URL field from monitor configuration
#   $user      - Username field from monitor configuration
#   $password  - Password field from monitor configuration
#   $threshold - Threshold value from monitor configuration
#   $rsaddr    - Real Server IP (differs from $host for out-of-band monitoring)
#   $rsport    - Real Server Port (differs from $port for out-of-band monitoring)
#   $timeout   - Timeout value in seconds (use alarm() to enforce)
#
# TIPS:
#   - Always implement a timeout to prevent hanging
#   - Use the $content field to pass custom configuration data
#   - Test your script from command line before uploading to EdgeADC
#
########################################################################################################

use strict;
use warnings;

# Add any additional Perl modules your monitor requires here
# Example: use IO::Socket::INET;
# Example: use LWP::UserAgent;
# Example: use Net::Ping;

sub monitor {
    #---------------------------------------------------------------------------------------
    # PARAMETER EXTRACTION - Do not modify this section
    #---------------------------------------------------------------------------------------
    my $host       = $_[0];     # Target host IP or hostname
    my $port       = $_[1];     # Target port (optional - may be empty)
    my $content    = $_[2];     # Custom content field - use for your configuration
    my $notes      = $_[3];     # Notes field (typically unused)
    my $page       = $_[4];     # Page/URL field
    my $user       = $_[5];     # Username for authentication
    my $password   = $_[6];     # Password for authentication
    my $threshold  = $_[7];     # Threshold value
    my $rsaddr     = $_[8];     # Real Server IP (for out-of-band monitoring)
    my $rsport     = $_[9];     # Real Server Port (for out-of-band monitoring)
    my $timeout    = $_[10];    # Timeout value in seconds

    # Set a default timeout if not provided
    my $timeout = 5 unless defined $timeout && $timeout =~ /^\d+$/;  # Default to 5 seconds if not provided

    # Timeout handler - ensures script exits cleanly on timeout
    $SIG{ALRM} = sub {
        print "Health check for $host:$port timed out after $timeout seconds\n";
        exit 2;  # Return DOWN status on timeout
    };
    alarm($timeout);  # Start the timeout countdown

    #---------------------------------------------------------------------------------------
    # YOUR CUSTOM MONITORING CODE GOES HERE
    #---------------------------------------------------------------------------------------
    # 
    # Replace this section with your actual health check logic.
    # 
    # Examples of what you might check:
    #   - TCP connection to a specific port
    #   - HTTP/HTTPS request and response validation
    #   - Database connectivity
    #   - Custom protocol checks
    #   - File existence or content checks
    #   - API endpoint health
    #
    # Remember:
    #   - Return 1 for SUCCESS (server is healthy)
    #   - Return 2 for FAILURE (server is unhealthy)
    #   - Always clear the alarm with alarm(0) before returning
    #
    
    # --- EXAMPLE: Simple TCP port check ---
    # use IO::Socket::INET;
    # my $target = $port ? "$host:$port" : $host;
    # my $socket = IO::Socket::INET->new(
    #     PeerAddr => $host,
    #     PeerPort => $port || 80,
    #     Proto    => 'tcp',
    #     Timeout  => $timeout
    # );
    # if ($socket) {
    #     close($socket);
    #     alarm(0);
    #     print "SUCCESS: Connected to $target\n";
    #     return 1;
    # } else {
    #     alarm(0);
    #     print "FAILURE: Cannot connect to $target\n";
    #     return 2;
    # }
    # --- END EXAMPLE ---

    # Placeholder - replace with your check
    my $check_passed = 0;  # Set to 1 if your check succeeds

    #---------------------------------------------------------------------------------------
    # RETURN RESULT - Modify the condition above, not this section
    #---------------------------------------------------------------------------------------
    alarm(0);  # Clear the timeout alarm BEFORE returning

    if ($check_passed) {
        print "Health check PASSED for $host\n";
        return 1;  # Server is UP
    } else {
        print "Health check FAILED for $host\n";
        return 2;  # Server is DOWN
    }
}

#---------------------------------------------------------------------------------------
# MAIN EXECUTION - Do not modify below this line
#---------------------------------------------------------------------------------------
if (@ARGV < 1) {
    print "Usage: $0 <host> [port] [content] [notes] [page] [user] [password] [threshold]\n";
    print "This script is designed to be called by EdgeADC for server health checking.\n";
    exit 2;
}

exit(monitor(@ARGV));

