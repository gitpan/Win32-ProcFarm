#############################################################################
#
# Win32::ProcFarm::TickCount - method for safely comparing GetTickCount values
#
# Author: Toby Everett
# Revision: 2.12
# Last Change: Created
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

package Win32::ProcFarm::TickCount;

use strict;
use vars qw($VERSION);

$VERSION = '2.12';

sub compare {
  my($a, $b) = @_;

  $a = $a % 2**32;
  $b = $b % 2**32;

  $a == $b and return 0;
  return (abs($a-$b) > 2**31 ? -1 : 1)*($a<=>$b);
}

1;
