package ox4li::Controller::Auth;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

ox4li::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub login :Local :Args(0) {
    my ($self, $c) = @_;
    
    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};

    if ($username && $password) {
        if ($c->authenticate({ username => $username,
                               password => $password  } )) {
            $c->response->redirect($c->uri_for(
                $c->controller('Root')->action_for('index')));
            return;
        } 
				else {
            $c->stash(error_msg => "Bad username or password.");
        }
    } 
		else {
        $c->stash(error_msg => "You need to login")
            unless ($c->user_exists);
    }
    
    $c->stash(template => 'login.tt');
}

sub logout :Local :Args(0) {
    my ($self, $c) = @_;

    $c->logout;
	$c->response->redirect($c->uri_for('/'));
}



=head1 AUTHOR

Charlie Harvey,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
