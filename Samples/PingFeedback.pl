use Win32::ProcFarm::Pool;

$ARGV[0] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/ or
    die "Pass me the range to ping in the format start_address-end (i.e. 135.40.94.1-40).\n";
($base, $start, $end) = ($1, $2, $3);

$poolsize = int(sqrt(($end-$start+1)*2));
print "Creating pool with $poolsize threads . . .\n"; &set_timer;

$Pool = Win32::ProcFarm::Pool->new($poolsize, 9000, 'PingChild.pl', Win32::GetCwd);
print "Pool created in ".&get_timer." seconds.\n";

&set_timer;

foreach $i ($start..$end) {
  $ip_addr = "$base.$i";
  $Pool->add_waiting_job($ip_addr, 'ping', $ip_addr);
}

$retval = 0;
foreach $i ($start..$end) {
  $ip_addr = "$base.$i";
  until (exists $Pool->{return_data}->{$ip_addr}) {
    $Pool->cleanse_and_dispatch;
    Win32::Sleep(100);
  }
  if ($Pool->{return_data}->{$ip_addr}->[0]) {
    print "$ip_addr\n";
    $retval++;
  }
}

print "Total of $retval addresses responded in ".&get_timer." seconds.\n";

sub set_timer {
  $start_clock = Win32::GetTickCount();
}

sub get_timer {
  return (Win32::GetTickCount()-$start_clock)/1000;
}
