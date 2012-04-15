package ox4li::View::HTML;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    WRAPPER => 'wrapper.tt',
);

=head1 NAME

ox4li::View::HTML - TT View for ox4li

=head1 DESCRIPTION

TT View for ox4li.

=head1 SEE ALSO

L<ox4li>

=head1 AUTHOR

Charlie Harvey,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
