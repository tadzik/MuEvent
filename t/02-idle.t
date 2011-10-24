use Test;
use MuEvent;

# all events sleep for 1 second, the first one is run after 2 seconds
# (in 3rd second), the last one stops the program after 5,
# so idle should run 3 times: 0th, 1st, 2nd and 4th second
plan 5;

my $start;

MuEvent::timer(
    after => 2,
    cb    => sub {
        ok ($start + 2 <= time <= $start + 3), 'after 2';
        sleep 1;
    }
);

MuEvent::timer(
    after => 5,
    cb    => sub {
        ok ($start + 5 <= time <= $start + 6), 'after 5';
        exit 0;
    }
);

MuEvent::idle(cb => { pass 'idle'; sleep 1 });

$start = time;
MuEvent::run;
