package ox4li;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90011;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Authentication
    Authorization::Roles
    Session
    Session::Store::File
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in ox4li.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'ox4li',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    'Plugin::Authentication' => {
        default => {
            class               => 'SimpleDB',
            user_model          => 'DB::User',
            password_type       => 'hashed',
            password_hash_type  => 'SHA-1',
            password_pre_salt   => 'djksdjskkkdsk38291829',
        },
    },
);

# Start the application
__PACKAGE__->setup();


=head1 NAME

ox4li - Catalyst based application

=head1 SYNOPSIS

    script/ox4li_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<ox4li::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Charlie Harvey,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
