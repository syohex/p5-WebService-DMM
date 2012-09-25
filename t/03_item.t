use strict;
use warnings;
use Test::More;

use WebService::DMM::Item;

subtest 'constructor' => sub {
    my $item = WebService::DMM::Item->new(
        content_id   => 10,
        product_id   => 20,
        URI          => 'http://example.com/',
        affiliateURL => 'http://example.com/test-999',
        title        => 'title',
        date         => '2012/09/10',
        keywords     => [qw/apple melon/],
        actresses    => [qw/alice kate/],
        directors    => [qw/bob/],
        author       => [qw/deen/],
        maker        => 's1',
        label        => 'deeps',
        jancode      => '111',
        stock        => '100',
        price        => 1000,
        list_price   => 2000,
    );

    ok $item, 'constructor';
    isa_ok $item, 'WebService::DMM::Item';
};

subtest 'accessors' => sub {
    my @accessors = qw/content_id product_id url affiliate_url title price list_price
                       date keywords actresses directors author maker label
                       jancode isbn stock/;

    my $item = WebService::DMM::Item->new;
    for my $accessor (@accessors) {
        can_ok $item, $accessor;
    }
};

subtest 'image' => sub {
    my %image = (
        list  => 'aa',
        small => 'bb',
        large => 'cc',
    );

    my $item = WebService::DMM::Item->new(
        image => \%image,
    );

    for my $key (keys %image) {
        my $img = $item->image($key);
        is $img, $image{$key}, "Image type '$key'";
    }

    eval {
        $item->image('not_found');
    };
    like $@, qr/Invalid type 'not_found'/, 'invalid image type';
};

done_testing;
