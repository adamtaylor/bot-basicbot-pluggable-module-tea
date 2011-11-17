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
    my @selected_nick_list;
    my $last_used = DateTime->now;

    sub select_brew_maker {
        my $self = shift;
        my $chan = shift;

        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );

        for my $nick (@all_nicks) {
            # insert new nick if not already in list and isn't the bot itself
            unless (scalar(grep {$_ eq $nick} @nick_list) || ($nick eq $self->bot->nick)) {
                splice(@nick_list, int(rand(@nick_list - 1)), 0, $nick);
            }
        }

        my $extra = '';
        if (DateTime->now > $last_used->clone->add(hours => 8)) {
            @nick_list = shuffle(@nick_list);
            @selected_nick_list = [];
            $extra = ' (the rota was rewritten due to inactivity)';
        }

        # rotate list until first nick is in the room
        while (!grep {$nick_list[0] eq $_} @all_nicks) {
            push @nick_list, shift @nick_list;
        }

        my $brew_maker = $nick_list[0];

        # take the first nick and put them to the back of the list
        push @nick_list, shift @nick_list;
        # maintain a list of previously selected tea makers
        push @selected_nick_list, $brew_maker;

        $last_used = DateTime->now;

        return ($brew_maker,$extra);
    }

    sub told {
        my ( $self, $msg ) = @_;

        my $body = $msg->{body};
        my $who  = $msg->{who};
        my $chan = $msg->{channel};

        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );

        if ( $body =~ /^!tea$/ ) {

            my ($brew_maker,$extra) = $self->select_brew_maker( $chan );

            my $resp = "$who would like a brew! $brew_maker: your turn!$extra";
            return $resp;
        }

        # Process tea commands
        if ( $body =~ /^!tea.*$/ ) {

            my @commands = split /\s/, $body;

            if ( $commands[1] eq 'away' ) {
                # Choose a new tea maker and pop the previous maker back
                my $previous_tea_maker = pop @selected_nick_list;
                my ($brew_maker, $extra) = $self->select_brew_maker( $chan );
                unshift @nick_list, $previous_tea_maker;
                return "$who says $previous_tea_maker is AWOL. $brew_maker, take over!";
            }
            elsif ( $commands[1] eq 'volunteer' ) {
                # If you volunteer, go to back of list
                @nick_list = grep {!/$who/} @nick_list;
                push @nick_list, $who;
                return "$who has volunteered to make a round. $who++";
            }
            elsif ( $commands[1] eq 'random' ) {
                # Choose a random nick from the channel
                my $brew_maker;
                do {
                    $brew_maker = $all_nicks[int(rand(scalar @all_nicks - 1))];
                } until $brew_maker ne $self->bot->nick;

                return "$who would like a brew! $brew_maker: your turn!";
            }
            elsif ( $commands[1] eq 'status' ) {
                return "Tea round status is: " . join ',', @nick_list;
            }
            else {
                return "$who-- # Imbecile! [unknown command]";
            }

        }

        # No coffee allowed!
        if ( $body =~ /^!coffee/ ) {
            return "$who-- # no coffee here!";
        }

        return;
    }
}

1;
