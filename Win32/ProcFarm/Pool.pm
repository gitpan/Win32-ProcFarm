#############################################################################
#
# Win32::ProcFarm::Pool - manages a pool of child processes
#
# Author: Toby Everett
# Revision: 2.10
# Last Change: Internals rearchitected to factor code more completely
#############################################################################
# Copyright 1999, 2000, 2001 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#############################################################################


=head1 NAME

Win32::ProcFarm::Pool - manages a pool of child processes

=head1 SYNOPSIS

  use Win32::ProcFarm::Pool;

  $Pool = Win32::ProcFarm::Pool->new($poolsize, $portnum, $scriptname, Win32::GetCwd);

  foreach $i (@list) {
    $Pool->add_waiting_job($i, 'child_sub', $i);
  }

  $Pool->do_all_jobs(0.1);

  %ping_data = $Pool->get_return_data;
  $Pool->clear_return_data;

  foreach $i (@list) {
    print "$i:\t$ping_data{$i}->[0]\n";
  }

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head2 More usage instructions

See C<Docs/tutorial.pod> for more information.

=head1 METHODS

=cut

use Win32::ProcFarm::Parent;
use Win32::ProcFarm::Port;

package Win32::ProcFarm::Pool;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.10';

=head2 new

The C<new> method creates a new C<Win32::ProcFarm::Pool> object (amazing, eh!).  It takes 5
parameters:

=over 4

=item $num_threads

This indicates the number of threads that should be created.

=item $port_num

This indicates the port number to use for the listener.

=item $script

The script name to execute for the child processes.

=item $curdir

The working directory to use when running the script.  If this is the same directory the script is
in, the script name can be specified without a path.

=item %options

A hash of options.  The current options are:

=over 4

=item timeout

Indicates how long jobs should be allowed to execute before they are deemed to have blocked.
Blocked jobs will be terminated and a new process created to take their place.

=back

=back

=cut

sub new {
  my $class = shift;

  my($num_threads, $port_num, $script, $curdir, %options) = @_;
  my $self = {
    'num_threads' => $num_threads,
    'port_obj' => undef,
    'thread_pool' => [],
    'waiting_pool' => [],
    'return_data' => {},
  };

  foreach my $i (qw(timeout)) {
    exists $options{$i} and $self->{$i} = $options{$i};
  }

  $self->{port_obj} = Win32::ProcFarm::Port->new($port_num, $num_threads);
  foreach my $i (0..($num_threads-1)) {
    my $temp = Win32::ProcFarm::Parent->new_async($self->{port_obj}, $script, $curdir, $self->{timeout});
    push(@{$self->{thread_pool}}, {
      'key' => undef,
      'Parent' => $temp
    });
  }

  foreach my $i (@{$self->{thread_pool}}) {
    $i->{Parent}->connect;
  }

  bless $self, $class;
  return $self;
}

=head2 add_waiting_job

The C<add_waiting_job> method adds a job to the waiting pool.  It takes three parameters:

=over 4

=item $key

This should be a unique identifier that will be used to retrieve the return values from the
return data hash.

=item $command

The name of the subroutine that the child process will execute.

=item @params

A list of parameters for that subroutine.

=back

=cut

sub add_waiting_job {
  my $self = shift;
  my($key, $command, @params) = @_;

  unshift(@{$self->{waiting_pool}}, {'key' => $key, 'command' => $command, 'params' => [@params]});
}

=head2 do_all_jobs

The C<do_all_jobs> command will execute all the jobs in the waiting pool.  The single passed
parameter specifies the number of seconds to wait between sweeps through the thread pool to check
for completed jobs.  The number of seconds can be fractional (i.e. 0.1 for a tenth of a second).

=cut

sub do_all_jobs {
  my $self = shift;
  my($sleep) = @_;

  while ($self->count_waiting + $self->count_running) {
    $self->cleanse_and_dispatch;
    $sleep and Win32::Sleep($sleep*1000);
  }
}

=head2 get_return_data

Return the return_data hash, indexed on the unique key passed initially.

=cut

sub get_return_data {
  my $self = shift;

  return (%{$self->{return_data}});
}

=head2 clear_return_data

Clears out the return_data hash.

=cut

sub clear_return_data {
  my $self = shift;

  $self->{return_data} = {};
}

=head1 INTERNAL METHODS

These methods are considered internal methods.  Child classes of Win32::ProcFarm::Pool may modify
these methods in order to change the behavior of the resultant Pool object.

=cut

sub count_waiting {
  my $self = shift;

  return scalar(@{$self->{waiting_pool}});
}

sub count_running {
  my $self = shift;

  return scalar(grep {$_->{Parent}->get_state ne 'idle'} @{$self->{thread_pool}});
}



sub cleanse_pool {
  my $self = shift;

  my $retval;

  foreach my $i (@{$self->{thread_pool}}) {
    $retval += $self->cleanse_thread($i);
  }
  return $retval;
}

sub dispatch_jobs {
  my $self = shift;

  my $retval;

  foreach my $i (@{$self->{thread_pool}}) {
    $retval += $self->dispatch_job($i);
  }

  return $retval;
}

sub cleanse_and_dispatch {
  my $self = shift;

  my($retval_c, $retval_d, $job);

  foreach my $i (@{$self->{thread_pool}}) {
    $retval_c += $self->cleanse_thread($i);
    $retval_d += $self->dispatch_job($i);
  }

  return ($retval_c, $retval_d);
}



sub cleanse_thread {
  my $self = shift;
  my($thread) = @_;

  $thread->{Parent}->get_state eq 'fin' or return 0;

  $self->{return_data}->{$thread->{key}} = [$thread->{Parent}->get_retval];
  $thread->{key} = undef;
  return 1;
}

sub dispatch_job {
  my $self = shift;
  my($thread) = @_;

  $thread->{Parent}->get_state eq 'idle' or return 0;
  my $job = $self->get_next_job() or return 0;
  $thread->{Parent}->execute($job->{command}, @{$job->{params}});
  $thread->{key} = $job->{key};
  return 1;
}

sub get_next_job {
  my $self = shift;

  return pop(@{$self->{waiting_pool}});
}

1;
