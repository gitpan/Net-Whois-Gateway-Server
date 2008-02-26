#!/usr/bin/perl -w
use strict;

use strict;
use POE qw(Component::Client::TCP Filter::Reference);
use Test::More;

plan tests => 6;
my @domains = qw(     
    freshmeat.net
    freebsd.org
    reg.ru
    ns1.nameself.com.NS
    perl.com
);

use_ok('Net::Whois::Gateway::Server');

my $main_session_id = POE::Session->create(
    inline_states => {
        _start        => \&_start,
        _start_client => \&_start_client,
        std_null      => \&std_null,
    },
);
    
# The show must go on!
$poe_kernel->run();
# Thats all!
ok(1, 'disconnected from server');


sub _start{
    my $kernel = $_[KERNEL];
    $kernel->delay_add('_start_client', 2);
    Net::Whois::Gateway::Server::start();    
}
sub _start_client {
    ok(1, "server started");
    POE::Component::Client::TCP->new(
        RemoteAddress => 'localhost',
        RemotePort    => 54321,
        Filter        => "POE::Filter::Reference",
        Started       => \&_starting_client,
        Connected     => \&_send_whois_request,
        ServerInput   => \&_got_answer,
    );    
}
sub _starting_client {
    ok(1, "client started");
}
sub _send_whois_request {
    ok(1, "client connected to server");
    $_[HEAP]->{server}->put( [ { query => \@domains } , ] );
};
sub _got_answer {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
    ok(@$input, 'got answer from server');    
    Net::Whois::Gateway::Server::stop();
    $kernel->yield('shutdown');    
    1==1;
}
sub std_null {
    1;
}
1;