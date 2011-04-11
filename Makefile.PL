use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

mkdir 'build';
my $pkg = ExtUtils::Depends->new( 'Hiredis::Raw', 'XS::Object::Magic' );

$pkg->set_inc('-I/usr/local/include/hiredis');
$pkg->set_libs('-L/usr/local/lib -lhiredis');
$pkg->add_xs('hiredis.xs');
$pkg->add_pm(
    './lib/Hiredis/Raw.pm'            => '$(INST_LIBDIR)/Raw.pm',
    './lib/Hiredis/Async.pm'          => '$(INST_LIBDIR)/Async.pm',
    './lib/Hiredis/Async/AnyEvent.pm' => '$(INST_LIBDIR)/Async/AnyEvent.pm',
    './lib/Hiredis/Raw/Constants.pm'  => '$(INST_LIBDIR)/Raw/Constants.pm',
);
$pkg->add_typemaps('typemap');
$pkg->save_config('build/IFiles.pm');

# use DDS;
# warn Dump({$pkg->get_makefile_vars});
makemaker_args(
    $pkg->get_makefile_vars,
);

name 'Hiredis-Raw';
license 'BSD3';
all_from 'lib/Hiredis/Raw.pm';
ppport;

configure_requires 'ExtUtils::Depends';
configure_requires 'XS::Object::Magic';
requires 'Sub::Exporter';
requires 'XS::Object::Magic';
test_requires 'AnyEvent';
test_requires 'File::Which';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::TCP';

# NOTE: running Hiredis::Async::AnyEvent requires Moose,
# namespace::autoclean, and AnyEvent.

WriteAll;
