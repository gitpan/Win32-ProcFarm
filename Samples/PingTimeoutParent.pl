use Win32::ProcFarm::Pool;

$ARGV[0] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/ or
    die "Pass me the range to ping in the format start_address-end (i.e. 135.40.94.1-40).\n";
($base, $start, $end) = ($1, $2, $3);

$poolsize = int(sqrt(($end-$start+1)*2));
20 < $poolsize and $poolsize = 20;

print "Creating pool with $poolsize threads . . .\n"; &set_timer;

$Pool = Win32::ProcFarm::Pool->new($poolsize, 9000, 'PingTimeoutChild.pl', Win32::GetCwd, timeout => 2);
print "Pool created in ".&get_timer." seconds.\n";

&set_timer;

foreach $i ($start..$end) {
  $ip_addr = "$base.$i";
  $Pool->add_waiting_job($ip_addr, 'ping', $ip_addr, rand(3));
}

$Pool->do_all_jobs(0.1);

%ping_data = $Pool->get_return_data;
$Pool->clear_return_data;

$retval = 0;
foreach $i ($start..$end) {
  $ip_addr = "$base.$i";
  print "$ip_addr\t".($ping_data{$ip_addr}->[0] || 'Child process terminated')."\n";
  $ping_data{$ip_addr}->[0] eq 'Host present' and $retval++;
}
print "Total of $retval addresses responded in ".&get_timer." seconds.\n";

sub set_timer {
  $start_clock = Win32::GetTickCount();
}

sub get_timer {
  return (Win32::GetTickCount()-$start_clock)/1000;
}
