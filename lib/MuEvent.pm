#= Event-driven programming in Perl 6
unit module MuEvent;

use nqp;

my @timers;
my @sockets;
my @idlers;
my $since;

class MuEvent::Condvar {
    has &.cb;
    has $.sent is rw;
    has $.flag is rw = False;

    method send($data?) {
        &.cb() if &.cb;
        $.sent = $data if $data.defined;
        $.flag = True;
    }
    method recv() {
        $since = clock() unless $since.defined;
        MuEvent::_poll until $.flag;
        $.sent;
    }
}

sub http_get(:$url!, :&cb!) is export {
    my $sock = IO::Socket::INET.new(host => $url, port => 80);
    my $req = "GET / HTTP/1.1\r\n"
            ~ "Connection: Close\r\n"
            ~ "Host: $url\r\n"
            ~ "User-Agent: MuEvent/0.0 Perl6/$*PERL<compiler><ver>\r\n"
            ~ "\r\n";
    my $callback = sub {
        &cb($sock.recv);
        $sock.close;
    }

    MuEvent::socket(
        socket => $sock,
        poll   => 'r',
        cb     => $callback,
    );

    $sock.send($req);
}

#= Add an event run after a certain amount of time
our sub timer(:&cb!, :$after!, :$interval, :%params) {
    @timers.push: {
        :$after, :$interval, :&cb,
        :%params,
        keep => 1, lastrun => 0
    };
}

#= Add an IO::Socket to observe
our sub socket(:&cb!, :$socket!, :$poll where 'r'|'w', :%params) {
    my $p = $poll eq 'r' ?? 1 !! 2;
    @sockets.push: {
        :$socket, :poll($p), :&cb,
        :%params,
        keep => 1
    };
}

#= Add an event to be run when event loop is idle
our sub idle(:&cb!, :%params) {
    @idlers.push: { :&cb, :%params }
}

#= Run the event loop
our sub run {
    $since = clock();
    loop {
        run-once()
    }
}

our sub _poll {
    run-once()
}

#= Condvar
our sub condvar(:&cb?) {
    MuEvent::Condvar.new( cb => &cb );
}

sub run-timers {
    my $seen-action = False;
    for @timers -> $e is rw {
        if clock() > $since + $e<after> {
            if defined $e<interval> {
                if clock() > $e<lastrun> + $e<interval> {
                    $e<lastrun> = clock();
                    $e<cb>.(|$e<params>);
                    $seen-action = True;
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

sub clock {
    nqp::p6box_n(nqp::time_n)
}

sub run-once {
    my $seen-action = False;
    $seen-action   += run-timers();
    $seen-action   += run-sockets();
    if not $seen-action {
        for @idlers { $_<cb>.(|$_<params>) }
    }
}
