use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'WebService-DMM';
all_from 'lib/WebService/DMM.pm';

requires 'URI';
requires 'Furl' => '0.41';
requires 'XML::LibXML';
requires 'Class::Accessor::Lite' => '0.05';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Mock::Guard';

author_tests('xt');
auto_set_repository();
WriteAll;
