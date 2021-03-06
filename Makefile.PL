use inc::Module::Install;
use Module::Install::Repository;

name 'Catalyst-View-JSON';
all_from 'lib/Catalyst/View/JSON.pm';

build_requires 'Test::More';

requires 'JSON::MaybeXS', '1.003000';
requires 'Catalyst', 5.60;
requires 'MRO::Compat';
test_requires 'YAML';

auto_set_repository;
WriteAll;
