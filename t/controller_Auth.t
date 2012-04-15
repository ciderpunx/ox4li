use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ox4li' }
BEGIN { use_ok 'ox4li::Controller::Auth' }

ok( request('/auth')->is_success, 'Request should succeed' );
done_testing();
