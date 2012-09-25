package WebService::DMM::Item;
use strict;
use warnings;

use Carp ();

use Class::Accessor::Lite (
    rw => [ qw/content_id product_id title price list_price
               date keywords actresses directors author maker label sample_images
               jancode isbn stock series/ ],
);

sub new {
    my ($class, %args) = @_;

    bless {
        %args,
    }, $class;
}

sub image {
    my ($self, $type) = @_;

    unless ($type eq 'list' || $type eq 'small' || $type eq 'large') {
        Carp::croak("Invalid type '$type': it should be (list, small, large)");
    }

    return $self->{image}->{$type};
}

sub url { $_[0]->{URL}; }
sub affiliate_url { $_[0]->{affiliateURL}; }

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Item - DMM webservice item

=head1 DESCRIPTION

WebService::DMM::Item is object which stands for DMM item.

=head1 INTERFACES

=head2 Accessor

=over

=item content_id(:String)

=item product_id(:String)

=item url(:String)

=item affiliate_url(:String)

=item title(:String)

=item price(:String)

=item list_price(:Int)

=item date(:String)

=item keywords(:Array[String])

=item sample_images(:Array[String])

=item actresses(:Array[String])

=item directors(:Array[String])

=item author(:String)

=item maker(:String)

=item labal(:String)

=item jancode(:String)

=item isbn(:String)

=item stock(:Int)

=back

=head2 Instance Methods

=head3 $item->image($type)

Return URL string. C<$type> should be 'list' or 'small' or 'large'.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2012 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
