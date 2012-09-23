package WebService::DMM;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use URI;
use POSIX qw/strftime/;
use Furl;
use Encode ();
use XML::LibXML;
use WebService::DMM::Item;

our $VERSION = '0.01';

my $agent_name = __PACKAGE__ . "/$VERSION";
our $UserAgent = Furl->new(agent => $agent_name);

sub __ua {
    $UserAgent ||= Furl->new(agent => $agent_name);
    $UserAgent;
}

sub new {
    my ($class, %args) = @_;

    for my $param (qw/affiliate_id api_id/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }
    }

    _validate_affiliate_id($args{affiliate_id});

    bless {
        %args,
    }, $class;
}

sub _validate_affiliate_id {
    my $account = shift;

    unless ($account =~ m{9[0-9]{2}$}) {
        Carp::croak("Postfix of affiliate_id is '900--999'");
    }

    return 1;
}

my %validate_table = (
    hits   => \&_validate_hits_param,
    offset => \&_validate_offset_param,
    sort   => \&_validate_sort_param,
);

sub search {
    my ($self, %args) = @_;

    my %param;

    # mandatory parameters
    $param{affiliate_id} = $self->{affiliate_id};
    $param{api_id}       = $self->{api_id};
    $param{operation}    = $args{operation} || 'ItemList';
    $param{version}      = '1.00';
    $param{timestamp}    = $args{timestamp} || _format_date();
    $param{site}         = _validate_site_param($args{site});

    # optional parameters
    for my $p (qw/hits offset sort/) {
        if ($args{$p}) {
            $param{$p} = $validate_table{$p}->($args{$p});
        }
    }

    if ($args{service}) {
        my ($service, $floor)
            = _validate_service_floor(@args{'site', 'service', 'floor'});

        $param{service} = $service;
        $param{floor}   = $floor if defined $floor;
    }

    if ($args{keyword}) {
        $param{keyword} = _encode_keyword($args{keyword});
    }

    $self->_send_request(%param);
}

sub _encode_keyword {
    my $keyword = shift;
    Encode::encode('euc-jp', $keyword);
}

sub _validate_sort_param {
    my $sort = shift;
    my @sort_values = qw(rank +price -price date review);

    unless (grep {$sort eq $_} @sort_values) {
        Carp::croak("'sort' parameter should be (@sort_values)");
    }

    return $sort;
}

sub _validate_site_param {
    my $site = shift;

    unless (defined $site) {
        Carp::croak("'site' parameter is mandatory parameter");
    }

    unless ($site eq 'DMM.co.jp' || $site eq 'DMM.com') {
        Carp::croak("'site' parameter should be 'DMM.co.jp' or 'DMM.com'");
    }

    return $site;
}

sub _validate_hits_param {
    my $hits = shift;

    unless ($hits >= 1 && $hits <= 100) {
        Carp::croak("'hits' parameter should be 1 <= n <= 100");
    }

    return $hits;
}

sub _validate_offset_param {
    my $offset = shift;

    unless ($offset >= 1) {
        Carp::croak("'offset' parameter should be positive number(n >= 1)");
    }

    return $offset;
}

sub _format_date {
    strftime '%Y-%m-%d %T', localtime;
}

sub _send_request {
    my ($self, %args)  = @_;

    my $uri = URI->new('http://affiliate-api.dmm.com/');
    $uri->query_form(%args);

    my $res = __ua()->get( $uri->as_string );
    unless ($res->is_success) {
        Carp::croak("Download failed: " . $uri->as_string);
    }

    $self->_parse_responce( \$res->content );
    return @{$self->{items}};
}

sub _parse_responce {
    my ($self, $content_ref) = @_;
    my $decoded = _decode_xml_utf8( $content_ref );

    my $dom = XML::LibXML->load_xml(string => $decoded);
    my @items_nodes = $dom->findnodes('/responce/result/items/item');

    for my $item_node (@items_nodes) {
        my %param;

        for my $p (qw/content_id product_id URL affiliateURL title date/) {
            $param{$p} = $item_node->findvalue($p);
        }

        my $image_url;
        for my $p (qw/list small large/) {
            $image_url->{$p} = $item_node->findvalue("imageURL/$p");
        }
        $param{image} = $image_url;

        $param{sample_images} = [
            map { $_->textContent } $item_node->findnodes('sampleImageURL/sample_s/image')
        ];

        $param{price} = $item_node->findnodes('prices/price')->[0]->textContent();
        $param{list_price} = _get_or_none($item_node, 'prices/list_price', 'TEXT');

        $param{keywords} = [
            map { $_->findvalue('name') } $item_node->findnodes('iteminfo/keyword')
        ];

        $param{actresses} = _personal_info($item_node, 'iteminfo/actress');
        $param{directors} = _personal_info($item_node, 'iteminfo/director');

        $param{series} = _get_or_none($item_node, 'iteminfo/series', 'name');
        $param{maker} = _get_or_none($item_node, 'iteminfo/maker', 'name');
        $param{label} = _get_or_none($item_node, 'iteminfo/label', 'name');

        push @{$self->{items}}, WebService::DMM::Item->new(%param);
    }
}

sub _get_or_none {
    my ($node, $path, $tag) = @_;

    my @nodes = $node->findnodes($path);
    if (@nodes) {
        if ($tag eq 'TEXT') {
            return $nodes[0]->textContent;
        } else {
            return $nodes[0]->findvalue($tag);
        }
    } else {
        return;
    }
}

sub _personal_info {
    my ($node, $path) = @_;

    my @persons;
    my @person_nodes = $node->findnodes($path);
    for my $person_node (@person_nodes) {
        my $name = $person_node->findvalue('name');
        my $id = $person_node->findvalue('id');
        next unless $id =~ m{^\d+$};

        push @persons, $name;
    }

    return \@persons;
}

# parsing XML encoded EUC-jp is difficult.
sub _decode_xml_utf8 {
    my $content_ref = shift;
    $$content_ref =~ s{encoding="euc-jp"}{encoding="utf-8"};

    return Encode::decode('euc-jp', $$content_ref);
}

sub items {
    my $self = shift;
    return @{$self->{items}};
}

my %service_floor = (
    'DMM.com' => {
        lod          => [qw/akb48 ske48/],
        digital      => [qw/bandai anime video idol cinema fight/],
        monthly      => [qw/toei animate shochikugeino idol cinepara dgc fleague/],
        digital_book => [qw/comic novel magazine photo audio movie/],
        pcsoft       => [qw/pcgame pcsoft/],
        mono         => [qw/dvd cd book game hobby kaden houseware gourmet/],
        rental       => [qw/rental_dvd ppr_dvd rental_cd ppr_cd set_dvd set_cd comic/],
        nandemo      => [qw/fashion_ladies fashion_mems rental_iroiro/],
    },

    'DMM.co.jp' => {
        digital => [qw/videoa videoc nikkatsu anime photo/],
        monthly => [qw/shirouto nikkatsu paradisetv animech dream avstation
                       playgirl alice crystal hmp waap momotarobb moodyz
                       prestige jukujo sod mania s1 kmp/],
        ppm     => [qw/video videoc/],
        pcgame  => [qw/pcgame/],
        doujin  => [qw/doujin/],
        book    => [qw/book/],
        mono    => [qw/dvd goods anime pcgame book doujin/],
        rental  => [qw/rental_dvd ppr_dvd set_dvd/],
    },
);

sub _validate_service_floor {
    my ($site, $service, $floor) = @_;

    unless (defined $floor) {
        return ($service, undef);
    }

    unless (exists $service_floor{$site}->{$service}) {
        my @keys = keys %service_floor;
        Carp::croak("Invalid service '$service': (@keys)");
    }

    my @floors = @{$service_floor{$site}->{$service}};
    unless (grep { $floor eq $_ } @floors) {
        Carp::croak("Invalid floor '$floor'(service $service): (@floors)");
    }

    return ($service, $floor);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM - DMM webservice module

=head1 SYNOPSIS

  use WebService::DMM;
  use Config::Pit;

  my $config = pit_get('dmm.co.jp', require => {
      affiliate_id => 'DMM affiliate ID',
      api_id       => 'DMM API ID',
  });

  my $dmm = WebService::DMM->new(
      affiliate_id => $config->{affiliate_id},
      api_id       => $config->{api_id},
  );

  my @items = $dmm->search( %params );


=head1 DESCRIPTION

WebService::DMM is DMM webservice module.
DMML<http://www.dmm.com> is Japanese shopping site.

=head1 INTERFACES

=head2 Class Methods

=head3 C<< WebService::DMM->new(%args) :WebService::DMM >>

Create and return a new WebService::DMM instance with I<%args>.

I<%args> must have following parameter:

=over

=item affiliate_id

Affiliate ID of DMM. Postfix of affliate_id should be 900-999.

=item api_id

API ID of DMM. Register your account in DMM and you can get API ID.

=back

=head2 Instance Method

=head3 $dmm->search(%param)

I<%params> mandatory parameters are:

=over

=item operation :Str = "ItemList"

=item version :Str = "1.00"

=item timestamp :Str = current time

Time format should be 'Year-Month-Day Hour:Minute:Second'
(strftime format is '%Y-%m-%d %T')

=item site :Str

Site, 'DMM.co.jp' or 'DMM.com'.

=back

I<%param> optional parameters are:

=over

=item hits :Int = 20

Number of items

=item offset :Int = 1

Number of page

=item sort :Str = "rank"

Type of sort, 'rank', '+price', '-price', 'date', 'review'.

=item service :Str

See "SERVICE AND FLOOR" section

=item floor :Str

See "SERVICE AND FLOOR" section

=item keyword :Str

Search keyword. You can use DMM search keyword style.
Keyword should be string(not byte sequence).

=back

=head1 SERVICE AND FLOOR

DMM.com services are:

=over

=item lod

akb48, ske48

=item digital

bandai, anime, video, idol, cinema, fight

=item monthly

toei, animate, shochikugeino, idol, cinepara, dgc, fleague

=item digital_book

comic, novel, magazine, photo, audio, movie

=item pcsoft

pcgame, pcsoft

=item mono

dvd, cd, book, game, hobby, kaden, houseware, gourmet

=item rental

rental_dvd, ppr_dvd, rental_cd, ppr_cd, set_dvd, set_cd, comic

=item nandemo

fashion_ladies, fashion_mems, rental_iroiro

=back

DMM.co.jp services are:

=over

=item digital

videoa, videoc, nikkatsu, anime, photo

=item monthly

shirouto, nikkatsu, paradisetv, animech, dream, avstation, playgirl, alice,
crystal, hmp, waap, momotarobb, moodyz, prestige, jukujo, sod, mania, s1, kmp

=item ppm

video, videoc

=item pcgame

pcgame

=item doujin

doujin

=item book

book

=item mono

dvd, good, anime, pcgame, book, doujin

=item rental

rental_dvd, ppr_dvd, set_dvd

=back

=head1 CUSTOMIZE USER AGENT

You can specify your own instance of L<Furl> to set $WebService::DMM::UserAgent.

    $WebService::DMM::UserAgent = Furl->new( your_own_paramter );

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2012- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Official Guide L<https://affiliate.dmm.com/api/guide/>

=cut
