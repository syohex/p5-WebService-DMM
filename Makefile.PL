use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'WebService-DMM';
all_from 'lib/WebService/DMM.pm';

author_tests('xt');
auto_set_repository();
WriteAll;
