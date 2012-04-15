package ox4li::Controller::Root;
use Moose;
use Net::Blacklist::Client;
use Domain::PublicSuffix;
use HTML::Strip;
use Math::Base36 ':all';
use Data::Validate::URI qw(is_web_uri);
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

=head1 NAME

ox4li::Controller::Root - Root Controller for ox4li

=head1 DESCRIPTION

ox4li is yet another url shortener, it does very little of note. It does not log ip addresses and such. 
it does keep track of the number of times a link is clicked.

## TODO: Custom URL should be a new col in the database, not implemented except in a kludgey way by using the code column
#        which will be a bit breaky

=head1 METHODS

=head2 list

Should require authentication, list all links. TODO pagination

=cut

# Note that 'auto' runs after 'begin' but before your actions and that
# 'auto's "chain" (all from application path to most specific class are run)
# See the 'Actions' section of 'Catalyst::Manual::Intro' for more info.
sub auto :Private {
    my ($self, $c) = @_;
	$c->response->header('Cache-Control' => 'no-cache');

    if ($c->controller eq $c->controller('Auth')) {
        return 1;
    }

    # If a user doesn't exist, force login for particular actions
    if (!$c->user_exists && ( $c->action eq 'list' 
				|| $c->action eq 'delete'
				|| $c->action eq 'update_url')) {
        $c->log->debug('***Root::auto User not found, forwarding to /login');
        $c->response->redirect($c->uri_for('/auth/login'));
        # Return 0 to cancel 'post-auto' processing and prevent use of application
        return 0;
    }

    # User found, so return 1 to continue with processing after this 'auto'
    return 1;
}



=head2 list

Should require authentication, list all links. 

=cut

sub list :Local {
    my ($self, $c) = @_;
	my $page     = $c->req->params->{page} || 1;
	my $per_page = $c->req->params->{per_page} || 10;
	$per_page = 5 unless ($per_page > 4);
	$per_page = 50 unless ($per_page < 51);
	my $links = $c->model('DB::Links')
		        ->search(undef, { rows => $per_page })->page( $page );

    $c->stash( links => [$links->all], pager => $links->pager);
    $c->stash(template => 'links/list.tt');    
}


=head2 index

The root page (/)

=cut

sub index :Path Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'home.tt' );
}

=head2 index_redirect

index_redirect

=cut

sub index_redirect : Chained('/') PathPart('') Args(1) {
    my ( $self, $c, $code ) = @_;
    $c->stash(code=>$code );
    my $link = $c->model('DB::Links')->find({code => $code});
    if($link) {
        $link->update({count => $link->count+1});
        $c->res->redirect($link->url,301);
    }
    else {
        $c->stash(template => 'home.tt' );
    }
}

=head2 index_stats

index_stats

=cut

sub index_stats : Chained('/') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $code ) = @_;
    $c->stash(code=>$code);
}

=head2 stats

stats page

=cut

sub stats :Chained('index_stats') :Args(0) {
    my ( $self, $c ) = @_;
    my $link = $c->model('DB::Links')->find({code => $c->stash->{'code'} });
    if($link) {
        $c->stash(template => 'link.tt', link => $link);
    }
    else {
        $c->stash(template => 'home.tt' );
    }

}

=head2 stats

stats page

=cut

sub kitteh :Chained('index_stats') :Args(0) {
    my ( $self, $c ) = @_;
    my $link = $c->model('DB::Links')->find({code => $c->stash->{'code'} });
    my $rand = int(rand(11)); # NB: Number of images shouldn't be hardcoded if we start using this a lot.
    if($link) {
        $c->stash(
                no_logo => 1,
                template   => 'kitteh.tt',
                kitteh     => "/static/kitteh/$rand.jpg",
                url        => $link->url,
        );
    }
    else {
        $c->stash(template => 'home.tt' );
    }

}

=head2 delete
    
    Delete a link TODO authentication
    
=cut
    
sub delete :Chained('index_stats') PathPart('delete') Args(0) {
    my ($self, $c) = @_;

    my $link = $c->model('DB::Links')->find({code => $c->stash->{'code'} });
    if($link) {
        $link->delete;
        $c->stash(
            status_msg => 'Deleted link with code ' . $c->stash->{'code'}
        );
        $c->res->redirect($c->uri_for($self->action_for('index')));
    }
    else {
        $c->stash(
            template  => 'home.tt', 
            error_msg => 'Cannot delete link with code ' . $c->stash->{'code'}
        );
    }
}

=head2 update
    
    Update a link TODO authentication
    
=cut
    
sub update_url :Chained('index_stats') PathPart('update_url') Args(0) {
    my ($self, $c) = @_;

    my $code = $c->stash->{code};
    my $url  = $c->req->params->{url};
    my $link = $c->model('DB::Links')->find({code => $code});
    if($link) {
        $url="http://$url" unless($url =~ /https?:\/\//); 
    
        unless(is_web_uri($url)) {
            $c->stash(template => 'home.tt', error_msg =>'Woah there! What kind of crazy URL is that?' );
            return;
        }
        
        $link->update({ url => $url });
        $c->stash(
            template    => 'create_done.tt', 
            link        => $link,
            status_msg  => 'Link with code ' . $c->stash->{'code'} . ' updated',
        );
        $c->res->redirect($c->uri_for($self->action_for('index')));

    }
    else {
        $c->stash(
            template  => 'home.tt', 
            error_msg => 'Sorry, can\'t find link with code ' . $c->stash->{'code'}
        );
    }
}
=head2 create

standard create method

=cut

sub create :Chained('/') Args(0) {
    my ( $self, $c ) = @_;
    
    my $url    = $c->req->params->{url};
    my $custom = $c->req->params->{custom}; 
	my $hs = HTML::Strip->new();
	$custom = $hs->parse($custom);
	$hs->eof;
    my $code   = '';
    
    ## Check length of code, url params 
    if(length $url > 500 || length $url < 10 ) {
            $c->stash(template => 'home.tt', error_msg =>'Only URLs from 10 to 500 characters long.' );
            return;
    }
    if ($url eq '') {
            $c->stash(template => 'home.tt', error_msg =>'Cannot cope with blank URLs.' );
            return;
    }
    if($custom && (length $custom < 3 || length $custom > 50)) {
            $c->stash(template => 'home.tt', error_msg =>'Custom URLs should be from 10 to 50 characters long.' );
            return;
    }

    # add http/s as protocol
    $url="http://$url" unless($url =~ /https?:\/\//); 
    
    # check we got a valid URL
    unless(is_web_uri($url)) {
            $c->stash(template => 'home.tt', error_msg =>'Woah there! What kind of crazy URL is that?' );
            return;
    }

    my $host = URI->new($url)->host;
    $c->log->debug("Submitted host was $host");
    unless($host) {
            $c->stash(template => 'home.tt', error_msg =>'Woah there! What kind of crazy URL is that?' );
            return;
    }


    # Do a spam lookup and block if it is listed 
    my $rbl     = Net::Blacklist::Client->new;
    $c->log->debug("Doing lookup on host $host");
    my $result0 = $rbl->lookup_domain( $host );
    my $suffix  = new Domain::PublicSuffix;
    my $root = $suffix->get_root_domain($host);
    unless($root) {
            $c->stash(template => 'home.tt', error_msg =>'Woah there! What kind of crazy URL is that?' );
            return;
    }

    $c->log->debug("Doing lookup on root $root");
    my $result1 = $rbl->lookup_domain($root);
    my $lookup  = '';

    foreach my $list (keys %$result0){
                $lookup .= sprintf "%s: %s (%s)\n", $list, $result0->{$list}->{a}, $result0->{$list}->{txt};
    }
    foreach my $list (keys %$result1){
                $lookup .= sprintf "%s: %s (%s)\n", $list, $result1->{$list}->{a}, $result1->{$list}->{txt};
    }


    if($lookup) {
            sleep 5;
            $c->stash(template => 'home.tt', error_msg =>'Error: Spam URLs are not supported.' );
            return;
    }

    if($custom ne ''){
            my $link = $c->model('DB::Links')->find({code => $custom});
            if($link){
                $c->stash(template => 'home.tt', error_msg =>'Sorry that short URL is taken.' );
                return;
            }
            $code = $custom;
    }
    else {
        # get last index from db, Base36 encode it and set that as code    
        my $max_id = $c->model('DB::Links')->get_column('id')->max;
        my $code_ok = 0;
        while (!$code_ok) {
            $code   = lc encode_base36(++$max_id);
            my $link = $c->model('DB::Links')->find({code => $code});
            $code_ok = 1 unless($link);
        }
    }

    # TODO: atm only one instance of an URL can exist -- is that OK? 
    my $link = $c->model('DB::Links')->find({url => $url});
    if($link){
        $c->stash(status_msg=>'Cool. Someone else already shortened that URL!' );
        $c->stash(link => $link, template => 'create_done.tt');
        $c->response->header('Cache-Control' => 'no-cache');
    }        
    else {
        my $new_link = $c->model('DB::Links')->create({
                code  => $code,
                url   => $url,
                count => 0,
        });
        $c->stash(status_msg=>'Link created!' );
        $c->stash(link => $new_link, template => 'create_done.tt');
        $c->response->header('Cache-Control' => 'no-cache');
    }
}

=head2 index

The root page (/)

=cut

sub about :Local Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'about.tt' );
}
=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Charlie Harvey,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
