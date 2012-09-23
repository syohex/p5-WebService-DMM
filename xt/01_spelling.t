use strict;
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;

my $spell_cmd;
foreach my $path (split(/:/, $ENV{PATH})) {
    -x "$path/spell"  and $spell_cmd="spell", last;
    -x "$path/ispell" and $spell_cmd="ispell -l", last;
    -x "$path/aspell" and $spell_cmd="aspell list", last;
}
plan skip_all => "no spell/ispell/aspell" unless $spell_cmd;

set_spell_cmd($spell_cmd);

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Syohei YOSHIDA
syohex
gmail
WebService::DMM
ItemList
akb
alice
anime
animech
avstation
bandai
cinepara
co
com
dgc
doujin
dvd
fleague
hmp
houseware
jp
jukujo
kaden
kmp
momotarobb
moodyz
nikkatsu
paradisetv
pcgame
pcsoft
playgirl
shirouto
shochikugeino
ske
toei
videoa
videoc
waap
webservice
lod
nandemo
ppm
API
