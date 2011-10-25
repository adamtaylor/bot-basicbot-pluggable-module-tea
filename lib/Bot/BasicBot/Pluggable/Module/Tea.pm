# ABSTRACT: Tea round organising IRC bot
package Bot::BasicBot::Pluggable::Module::Tea;

use warnings;
use strict;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Tea - Organise tea rounds via IRC.

=head1 SYNOPSIS

You will need to load the module into your instance:

    $bot->load('Tea');

Then when you fancy a brew, just issue the C<!tea> command:

    <adam> tea!
    <George> adam wants a brew. kristian make a tea round!
    <kristian> d'oh!

=cut

extends 'Bot::BasicBot::Pluggable::Module';

sub help {
    return "This plugin helps facilitae tea making within a team. Simply
        issue the `!tea` command when you fancy a brew and someone will
        be selected at random from the channel to make the tea round".
}

sub seen {
    my ( $self, $msg ) = @_;

    my $body = $msg->{body};

    if ( $body =~ /!tea/ ) {
        my @nicks = $self->bot->pocoirc->nicks;
        my $brew_maker = $nicks[int(rand(scalar @nicks - 1))] # randomly selected
        return "would like a brew! $brew_maker: your turn!";
    }

    return;

}

1;
