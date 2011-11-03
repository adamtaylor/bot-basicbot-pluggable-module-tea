# ABSTRACT: Tea round organising IRC bot
package Bot::BasicBot::Pluggable::Module::Tea;

use Moose;
use DateTime;
use List::Util qw(shuffle);

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
        . "issue the `!tea` command when you fancy a brew and a new tea round"
        . "will begin. If you want to live on the edge issue the `!russiantea`"
        . "command to have someone at random selected to make the tea";

    return $help;
}

{
    my @nick_list;
    my $last_used = DateTime->now;

    sub told {
        my ( $self, $msg ) = @_;

        my $body = $msg->{body};
        my $who  = $msg->{who};
        my $chan = $msg->{channel};

        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );

        if ( $body =~ /^!tea$/ ) {
            for my $nick (@all_nicks) {
                # insert new nick if not already in list and isn't the bot itself
                unless (scalar(grep {$_ eq $nick} @nick_list) || ($nick eq $self->bot->nick)) {
                    splice(@nick_list, int(rand(@nick_list - 1)), 0, $nick);
                }
            }

            my $extra = '';
            if (DateTime->now > $last_used->clone->add(hours => 8)) {
                @nick_list = shuffle(@nick_list);
                $extra = ' (the rota was rewritten due to inactivity)';
            }

            # rotate list until first nick is in the room
            while (!grep {$nick_list[0] eq $_} @all_nicks) {
                push @nick_list, shift @nick_list;
            }

            my $brew_maker = $nick_list[0];

            my $resp = "$who would like a brew! $brew_maker: your turn!$extra";

            # take the first nick and put them to the back of the list
            push @nick_list, shift @nick_list;

            $last_used = DateTime->now;

            return $resp;
        }

        if ( $body =~ /^!russiantea$/ ) {
            # Choose a random nick from the channel
            my $brew_maker;
            do {
                $brew_maker = $all_nicks[int(rand(scalar @all_nicks - 1))];
            } until $brew_maker ne $self->bot->nick;

            my $resp = "$who would like a brew! $brew_maker: your turn!";

            return $resp;
        }

        return;
    }
}

1;
