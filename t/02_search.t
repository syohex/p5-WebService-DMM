use strict;
use warnings;
use Test::More;

use WebService::DMM;

subtest 'search' => sub {
    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-950',
        api_id       => 'test',
    );

    can_ok $dmm, 'search';
};

done_testing;
