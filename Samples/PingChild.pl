use Net::Ping;

require 'Win32/ProcFarm/Child.pl';

&init;
while(1) { &main_loop };

sub ping {
  my($host) = @_;

  $p or $p = Net::Ping->new('icmp', 1);
  return $p->ping($host);
}
