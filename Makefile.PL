use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

mkdir 'build';
my $pkg = ExtUtils::Depends->new( 'Hiredis::Raw', 'XS::Object::Magic' );

$pkg->set_inc('-I/home/wjackson/hiredis');
$pkg->set_libs('-L/home/wjackson/hiredis -lhiredis');
$pkg->add_xs('hiredis.xs');
$pkg->add_pm(
    './lib/Hiredis/Raw.pm'           => '$(INST_LIBDIR)/Raw.pm',
    './lib/Hiredis/Raw/Constants.pm' => '$(INST_LIBDIR)/Raw/Constants.pm',
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
requires 'XS::Object::Magic';
test_requires 'Test::More';
test_requires 'Test::Exception';

WriteAll;
