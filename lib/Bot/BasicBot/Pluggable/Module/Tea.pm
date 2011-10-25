# ABSTRACT: Tea round organising IRC bot
package Bot::BasicBot::Pluggable::Module::Tea;

use Moose;
extends 'Bot::BasicBot::Pluggable::Module';

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

sub help {
    my $help = "This plugin helps facilitae tea making within a team. Simply "
        . "issue the `!tea` command when you fancy a brew and someone will "
        . "be selected at random from the channel to make the tea round";

    return $help;
}

sub told {
    my ( $self, $msg ) = @_;

    my $body = $msg->{body};
    my $who  = $msg->{who};
    my $chan = $msg->{channel};

    if ( $body =~ /!tea/ ) {

        my @nicks = $self->bot->pocoirc->channel_list( $chan );

        my $brew_maker;
        do {
            $brew_maker = $nicks[int(rand(scalar @nicks - 1))];
        } until $brew_maker ne $self->bot->nick;

        my $resp = "$who would like a brew! $brew_maker: your turn!";

        return $resp;
    }

    return;

}

1;
