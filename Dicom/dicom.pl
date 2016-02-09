#Monitor-Name:DICOM
use strict;
use warnings;

sub monitor
{
  my $ipaddr = $_[0];
  my $port = $_[1];
  my $param = $_[2];

  my $cmd = "/preset/echoscu";

  my $status;

  my $timeout = 5;

  if ($param ne '') {
    $status = system("/bin/sh", "-c",
      "setsid /bin/sh -c ".
      "'(sleep $timeout; kill 0) & ".
      "($cmd -aet \"$param\" $ipaddr $port >/dev/null 2>&1)'");
  }
  else {
    $status = system("/bin/sh", "-c",
      "setsid /bin/sh -c ".
      "'(sleep $timeout; kill 0) & ".
      "($cmd $ipaddr $port >/dev/null 2>&1)'");
  }

  if($status == 0) {
    return 1;
  }
  print "DICOM health-check failed\n";
  return 2;
}
