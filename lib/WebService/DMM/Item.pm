package WebService::DMM::Item;
use strict;
use warnings;

use Carp ();

use Class::Accessor::Lite (
    rw => [ qw/content_id product_id URL affiliateURL title
               date keywords actresses directors author maker label
               jancode isbn stock / ],
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

=item content_id(:string)

=item product_id(:string)

=item URL(:string)

=item affiliateURL(:string)

=item title(:string)

=item date(:string)

=item keywords(:Array[string])

=item actresses(:Array[string])

=item directors(:Array[string])

=item author(:string)

=item maker(:string)

=item labal(:string)

=item jancode(:string)

=item isbn(:string)

=item stock(:int)

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
