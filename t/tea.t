#!perl

use Findbin::libs;
use Test::More;
use Test::Bot::BasicBot::Pluggable;
use Test::POE::Component::IRC::State;

# Swap in a minimal testing version of Test::POE::Component::IRC::State
# so we can test stuff with channel nicks etc.
local *Test::Bot::BasicBot::Pluggable::pocoirc = sub {
    return Test::POE::Component::IRC::State->new();
};

my $bot = Test::Bot::BasicBot::Pluggable->new();
$bot->load('Tea');

# Quickly check our monkey-patching worked
is_deeply( $bot->pocoirc->channel_list, [ 'foo', 'bar', 'baz', 'qux' ], 'Monkey-patched channel list' );

my $resp = $bot->tell_direct('!tea');

use Data::Dump qw( pp );
warn pp $resp;

my $resp2 = $bot->tell_direct('!tea status');

warn pp $resp2;
