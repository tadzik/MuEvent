use Test;
use MuEvent;

# the tests should run as follows:
# 0th second: idle
# 1st second: idle
# 2nd second: after 2
# 3rd second: idle
# 4th second: idle
# 5th second: after 5
plan 6;

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
