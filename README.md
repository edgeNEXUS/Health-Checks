![Edgenexus Logo](/edgenexus_logo_small.png)

# Health Checks

Custom server and application health check monitors for EdgeADC.

The edgeNEXUS load balancer and ADC platform can run customised application health checks using Perl scripts. These monitors allow you to check the health of backend servers beyond simple TCP/HTTP checks.

## Getting Started

See the **[Generic Example](Generic%20Example/)** folder for a fully commented template you can use as a starting point for your own custom monitors.

## Script Format

Every monitor script must have a `#Monitor-Name:` comment on the first line. This name appears in the EdgeADC GUI dropdown:

```perl
#Monitor-Name:My Custom Monitor v1.0
```

## Parameters

EdgeADC passes the following parameters to your script:

| Parameter | Variable | Description |
|-----------|----------|-------------|
| Host | `$_[0]` | Target server IP address or hostname |
| Port | `$_[1]` | Target server port (may be empty) |
| Content | `$_[2]` | Content field - use for custom configuration data |
| Notes | `$_[3]` | Notes field (typically unused) |
| Page | `$_[4]` | Page/URL path for the request |
| Username | `$_[5]` | Username for authentication |
| Password | `$_[6]` | Password for authentication |
| Threshold | `$_[7]` | Threshold value from monitor config |
| RS Address | `$_[8]` | Real Server IP (for out-of-band monitoring) |
| RS Port | `$_[9]` | Real Server Port (for out-of-band monitoring) |
| Timeout | `$_[10]` | Timeout value in seconds |

## Return Values

Your script must return one of these values:

| Return Code | Meaning |
|-------------|---------|
| **1** | Health check **PASSED** - server is UP |
| **2** | Health check **FAILED** - server is DOWN |

## Timeout Handling

Always implement a timeout to prevent your script from hanging. Use the `alarm()` function:

```perl
my $timeout = $_[10] // 5;  # Use provided timeout or default to 5 seconds

$SIG{ALRM} = sub {
    print "Health check timed out after $timeout seconds\n";
    exit 2;
};
alarm($timeout);

# ... your check code here ...

alarm(0);  # Clear alarm before returning
```

**Important:** Always call `alarm(0)` after your check completes to clear the timeout.

## Available Examples

| Monitor | Description |
|---------|-------------|
| [Generic Example](Generic%20Example/) | Template with full documentation |
| [Radius](Radius/) | RADIUS authentication check |
| [DNS Server Check](DNS%20Server%20Check/) | DNS query validation |
| [Dicom](Dicom/) | DICOM medical imaging protocol |
| [HTTP Custom](HTTP%20Custom/) | Custom HTTP/HTTPS checks |
| [HTTPS 401 Challenge](HTTPS%20401%20challenge/) | HTTP authentication challenge |
| [Redis](Redis/) | Redis server health check |
| [TCP Multi Monitor](TCP%20Multi%20Monitor/) | Multiple TCP port checks |
| [TCP Out of Band](TCP%20Out%20of%20Band/) | Out-of-band TCP monitoring |

## Usage

1. Download or create your monitor script
2. Upload to EdgeADC via **Library > Real Server Monitors > Custom Monitors**
3. Assign the monitor to your virtual service under **IP Services > [Service] > Real Servers**

## Testing

Test your script from the command line before uploading:

```bash
perl my-monitor.pl 192.168.1.100 80 "content" "" "/" "user" "pass" "3" "" "" "5"
echo "Exit code: $?"
```
