module MuEvent;

my @timers;
my @sockets;
my @idlers;
my $since;

sub clock {
    nqp::p6box_n(pir::time__n())
}

our sub timer(:&cb!, :$after!, :$interval, :%params) {
    @timers.push: {
        :$after, :$interval, :&cb,
        :%params,
        keep => 1, lastrun => 0
    };
}

our sub socket(:&cb!, :$socket!, :$poll where 'r'|'w', :%params) {
    my $p = $poll eq 'r' ?? 1 !! 2;
    @sockets.push: {
        :$socket, :poll($p), :&cb,
        :%params,
        keep => 1
    };
}

sub run-timers {
    my $seen-action = False;
    for @timers -> $e is rw {
        if clock() > $since + $e<after> {
            if defined $e<interval> {
                if clock() > $e<lastrun> + $e<interval> {
                    $e<cb>.(|$e<params>);
                    $seen-action = True;
                    $e<lastrun> = clock();
                }
            } else {
                $e<cb>.(|$e<params>);
                $seen-action = True;
                $e<keep> = 0;
            }
        }
    }
    my @tmp = @timers.grep: { $_<keep> == 1 };
    @timers = @tmp;
    return $seen-action;
}

sub run-sockets {
    my $seen-action = False;
    for @sockets -> $e is rw {
        if $e<socket>.poll($e<poll>, 0.01) {
            $e<cb>.(|$e<params>) or $e<keep> = 0;
            $seen-action = True;
        }
    }
    my @tmp = @sockets.grep: { $_<keep> == 1 };
    @sockets = @tmp;
    return $seen-action;
}

our sub idle(:&cb!, :%params) {
    @idlers.push: { :&cb, :%params }
}

our sub run {
    $since = clock();
    loop {
        run-once()
    }
}

sub run-once {
    my $seen-action = False;
    $seen-action = run-timers();
    $seen-action = run-sockets();
    if not $seen-action {
        for @idlers { $_<cb>.(|$_<params>) }
    }
}
