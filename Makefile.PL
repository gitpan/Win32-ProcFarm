use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Win32::ProcFarm::Pool',
  'VERSION_FROM' => 'Win32/ProcFarm/Pool.pm', # finds $VERSION
  'PM' => {
    'Win32/ProcFarm/Child.pl' =>          '$(INST_LIBDIR)/Child.pl',
    'Win32/ProcFarm/Parent.pm' =>         '$(INST_LIBDIR)/Parent.pm',
    'Win32/ProcFarm/PerpetualPool.pm' =>  '$(INST_LIBDIR)/PerpetualPool.pm',
    'Win32/ProcFarm/Pool.pm' =>           '$(INST_LIBDIR)/Pool.pm',
    'Win32/ProcFarm/Port.pm' =>           '$(INST_LIBDIR)/Port.pm',
    'Win32/ProcFarm/TkPool.pm' =>         '$(INST_LIBDIR)/TkPool.pm',
  },
);

