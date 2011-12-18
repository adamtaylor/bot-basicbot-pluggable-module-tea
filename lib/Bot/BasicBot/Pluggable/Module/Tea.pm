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

    sub select_brew_maker {
        my $self = shift;
        my $chan = shift;
        
        my $extra = '';
        if (DateTime->now > $last_used->clone->add(hours => 8)) {
            @nick_list = shuffle(@nick_list);
            $extra = ' (the rota was rewritten due to inactivity)';
        }

        my $brew_maker = $nick_list[0];

        # take the first nick and put them to the back of the list
        push @nick_list, shift @nick_list;

        $last_used = DateTime->now;

        return ($brew_maker,$extra);
    }

    sub chanjoin {
        my ( $self, $msg ) = @_;
		# someone joined look at the current array of nicks and add the new person in a random place
		my @all_nicks = $self->bot->pocoirc->channel_list( $msg->{channel} );

        for my $nick (@all_nicks) {
            # insert new nick if not already in list and isn't the bot itself
            unless (scalar(grep {$_ eq $nick} @nick_list) || ($nick eq $self->bot->nick)) {
                splice(@nick_list, int(rand(@nick_list - 1)), 0, $nick);
            }
        }
	}
	
	#didn't work so instead we tidy_lists as part of the start of told
    # sub chanpart {
    #         my ( $self, $msg ) = @_;
    #       # someone left the room rebuild the lists but don't change the order
    #         $self->tidy_lists( $msg->{channel} );
    #   }

    sub tidy_lists {
        my ( $self, $chan ) = @_;
        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );
        # don't tell Gianni I used ~~
        @nick_list = grep { $_ ~~ @all_nicks && $_ ne $self->bot->nick } @nick_list;
        # @selected_nick_list = grep { $_ ~~ @all_nicks } @selected_nick_list;
    }
    
    sub told {
        my ( $self, $msg ) = @_;

        my $body = $msg->{body};
        my $who  = $msg->{who};
        my $chan = $msg->{channel};

        my @all_nicks = $self->bot->pocoirc->channel_list( $chan );
        #init the nick list if we don't have it already
        $self->chanjoin( $msg ) unless $#nick_list > 0;
        $self->tidy_lists( $msg->{channel} );
        
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
                my $person_away = pop @nick_list;
                my ($brew_maker, $extra) = $self->select_brew_maker( $chan );
                unshift @nick_list, $person_away;
                return "$who says $person_away is AWOL. $brew_maker, take over!";
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
