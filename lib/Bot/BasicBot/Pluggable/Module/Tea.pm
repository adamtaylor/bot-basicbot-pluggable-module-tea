# ABSTRACT: Tea round organising IRC bot
package Bot::BasicBot::Pluggable::Module::Tea;

use Moose;
use DateTime;
use List::Util qw(shuffle);

extends 'Bot::BasicBot::Pluggable::Module';

# VERSION

=head1 NAME

Bot::BasicBot::Pluggable::Module::Tea - Organise tea rounds via IRC.

=head1 SYNOPSIS

You will need to load the module into your instance:

    $bot->load('Tea');

Then when you fancy a brew, just issue the C<!tea> command:

    <adam> !tea
    <George> adam would like a brew! kristian: your turn!
    <kristian> d'oh!

=cut

sub help {

    return <<HELPMSG;
        This plugin helps facilitae tea making within a team. Simply
        issue the `!tea` command when you fancy a brew and a new tea round
        will begin.

        If the user selected is away, issue `!tea away` and another user
        will be selected.

        If you want to jump in the queue and make a round of tea, issue the
        `!tea volunteer` command.

        If you want to see the current tea round status, issue `!tea status`.

        If a user is lurking but not particpating in the round, or fails to
        make tea, issue `!tea ban <user>`, to have them removed from the round.
        They are only able to rejoin by volunteering to make a round.

        If you want to live on the edge issue the `!tea random` command to have
        someone at random selected to make the tea
HELPMSG

}

{
    # List of usersin the tea round
    my @nick_list;
    # XXX we should store this list
    # List of ignored/banned users
    my @ban_list;
    my $last_used = DateTime->now;

    sub select_brew_maker {
        my $self = shift;
        my $chan = shift;

        my $brew_maker = $nick_list[0];

        # take the first nick and put them to the back of the list
        push @nick_list, shift @nick_list;

        $last_used = DateTime->now;

        return $brew_maker;
    }

    sub chanjoin {
        my ( $self, $msg ) = @_;
        # someone joined look at the current array of nicks and add the new person in a random place
        my @all_nicks = $self->bot->pocoirc->channel_list( $msg->{channel} );

        for my $nick (@all_nicks) {
            # insert new nick if not already in list and isn't the in the ban list
            unless (scalar(grep {$_ eq $nick} @nick_list) || scalar(grep {$_ eq $nick} @ban_list)) {
                splice(@nick_list, int(rand(@nick_list - 1)), 0, $nick);
            }
        }
    }

    sub tidy_lists {
        my ( $self, $chan ) = @_;
        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );
        # don't tell Gianni I used ~~
        @nick_list = grep { $_ ~~ @all_nicks && $_ ne $self->bot->nick } @nick_list;

        my $extra = '';
        if (DateTime->now > $last_used->clone->add(hours => 8)) {
            @nick_list = shuffle(@nick_list);
            $extra = ' (the rota was rewritten due to inactivity)';
        }
        return $extra;
    }

    sub told {
        my ( $self, $msg ) = @_;

        my $body = $msg->{body};
        my $who  = $msg->{who};
        my $chan = $msg->{channel};

        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );
        # init the nick list if we don't have it already
        $self->chanjoin( $msg ) unless @nick_list;
        # push the bot's nick into the ban list if it's currently empty
        push @ban_list, $self->bot->nick unless @ban_list;

        my $extra = $self->tidy_lists( $msg->{channel} );

        if ( $body =~ /^!tea$/ ) {

            my $brew_maker = $self->select_brew_maker( $chan );

            my $resp = "$who would like a brew! $brew_maker: your turn! Current members of the round @nick_list. $extra";
            return $resp;
        }

        # Process tea commands
        if ( $body =~ /^!tea.*$/ ) {

            my @commands = split /\s/, $body;

            if ( $commands[1] eq 'away' ) {
                # Choose a new tea maker and pop the previous maker back
                my $person_away = pop @nick_list;
                my $brew_maker = $self->select_brew_maker( $chan );
                unshift @nick_list, $person_away;
                return "$who says $person_away is AWOL. $brew_maker, take over!";
            }
            elsif ( $commands[1] eq 'volunteer' ) {
                # Reset the list, if needs be
                $self->tidy_lists( $msg->{channel} );
                # If you volunteer, go to back of list
                @nick_list = grep {!/$who/} @nick_list;
                push @nick_list, $who;
                # If you were in the ban list, you are now removed
                @ban_list = grep {!/$who/} @ban_list;
                return "$who has volunteered to make a round. $who++. Current memebers of the round @nick_list";
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
            elsif ( $commands[1] eq 'version' ) {
                return "This is teabot version $VERSION";
            }
            elsif ( $commands[1] eq 'ban' ) {
                my $user = $commands[2];

                return "The `ban` command expects a user to ban: !tea ban <user>"
                    unless $user;

                push @ban_list, $user; # push the user to the ban list
                @nick_list = grep {!/$user/} @nick_list; # remove from user list

                return "$who has banned $user from the tea round. They can rejoin the round by volunteering.";
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

=head1 CONTRIBUTORS

Kristian Flint - <bmxkris@cpan.org>

Pete Smith - <pete@cubabit.net>

=begin Pod::Coverage

    select_brew_maker
    tidy_lists

=end Pod::Coverage

=cut
