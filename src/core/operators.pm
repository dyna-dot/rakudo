our multi infix:<~~>(Mu $topic, Mu $matcher) {
    $matcher.ACCEPTS($topic)
}

our multi infix:<~~>(Mu $topic, Regex $matcher) {
    Q:PIR {
        $P0 = find_lex '$matcher'
        $P1 = find_lex '$topic'
        %r = $P0.'ACCEPTS'($P1)
        store_dynamic_lex '$/', %r
    };
}

our multi infix:<!~~>(Mu $topic, Mu $matcher) {
    $matcher.REJECTS($topic)
}

our multi prefix:<?>(Mu $a) {
    $a.Bool;
}

our multi sub prefix:<->($a) {
    pir::box__PN(pir::neg__NN($a))
}

our multi sub infix:<+>($a, $b) {
    pir::box__PN(pir::add__NNN($a, $b))
}

our multi sub infix:<->($a, $b) {
    pir::box__PN(pir::sub__NNN($a, $b))
}

our multi sub infix:<*>($a, $b) {
    pir::box__PN(pir::mul__NNN($a, $b))
}

our multi sub infix:</>($a, $b) {
    pir::box__PN(pir::div__NNN($a, $b))
}

our multi sub infix:<%>($a, $b) {
    pir::box__PN(pir::mod__NNN($a, $b))
}

our multi sub infix:<**>($a, $b) {
    pir::box__PN(pir::pow__NNN($a, $b))
}

our multi sub infix:<&>(*@items) {
    Junction.new(@items, :all)
}

our multi sub infix:<|>(*@items) {
    Junction.new(@items, :any)
}

our multi sub infix:<^>(*@items) {
    Junction.new(@items, :one)
}

our sub all(*@items) {
    Junction.new(@items, :all);
}

our sub any(*@items) {
    Junction.new(@items, :any);
}

our sub one(*@items) {
    Junction.new(@items, :one);
}

our sub none(*@items) {
    Junction.new(@items, :none);
}

our multi prefix:<not>($x) { !$x }

our multi prefix:<so>($x) { ?$x }

our sub undefine(\$x) {
    my $undefined;
    $x = $undefined;
}

our multi infix:<does>(Mu \$do-it-to-me, Role $r) {
    my $specific_role = $r!select;
    my $applicator    = $specific_role.^applier_for($do-it-to-me);
    $applicator.apply($do-it-to-me, [$r]);
    $do-it-to-me
}

our multi infix:<but>(Mu $do-it-to-me is copy, \$r) {
    $do-it-to-me does $r
}

our multi infix:<before>($a, $b) {
    ($a cmp $b) == -1;
}

our multi infix:<after>($a, $b) {
    ($a cmp $b) == +1;
}

our multi infix:<?|>($a, $b) {
    ?(?$a +| ?$b)
}

our multi infix:<?&>($a, $b) {
    ?(?$a +& ?$b)
}

our multi infix:<?^>($a, $b) {
    ?(?$a +^ ?$b)
}

our multi infix:<min>(*@args) {
    @args.min;
}

our multi infix:<max>(*@args) {
    @args.max;
}

our multi infix:«=>»($key, $value) {
    Pair.new(key => $key, value => $value);
}

our multi infix:<~>($a, $b) {
    my $result = pir::new__Ps('Str');
    pir::assign__vPS($result, pir::concat__SSS(~$a, ~$b));
    $result
}

our sub circumfix:<{ }>(*@elements) {
    my %h = @elements;
    %h
}

# XXX Wants to be a macro when we have them.
our sub WHAT(\$x) {
    $x.WHAT
}

class Whatever { ... }

# the magic one that handles stuff like
# 'a' ... 'z' and 'z' ... 'a'
our multi sub infix:<...>($lhs, $rhs) {
    if $rhs ~~ Whatever {
        my $i = $lhs;
        return gather {
            loop {
                my $j = $i++;
                take $j;
            }
        }
    }

    gather {
        take $lhs;
        if ($lhs cmp $rhs) == 1 {
            my $x = $lhs;
            # since my $a = 'a'; $a-- gives
            # "Decrement out of range" we can't easily
            # decrement over our target, which is why the
            # case of going backwards is slighly more complicated
            # than going forward
            while (--$x cmp $rhs) == 1 {
                # need to make a fresh copy here because of RT #62178
                my $y = $x;
                take $y;
            }
            take $x if ($x cmp $rhs) == 0;
        } elsif ($lhs cmp $rhs) == -1 {
            my $x = $lhs;
            while (++$x cmp $rhs) <= 0 {
                my $y = $x;
                take $y;
            }
        }
    }
}

our multi sub infix:<...>($lhs, Code $rhs) {
    if $rhs.count != 1 {
        die "Series operator currently cannot handle blocks with count != 1";
    }

    my $i = $lhs;
    gather {
        my $j = $i;
        take $j;
        my $last = $i;
        loop {
            $i = $rhs.($last);
            my $j = $i;
            take $j;
            $last = $i;
        }
    }
}

our multi sub infix:<...>(@lhs, Whatever) {
    given @lhs.elems {
        when 2 {
            @lhs[0] ... { $_ + (@lhs[1] - @lhs[0]) };
        }
        when 3 {
            if @lhs[1] - @lhs[0] == @lhs[2] - @lhs[1] {
                @lhs[0] ... { $_ + (@lhs[1] - @lhs[0]) };
            } elsif @lhs[1] / @lhs[0] == @lhs[2] / @lhs[1] {
                @lhs[0] ... { $_ * (@lhs[1] / @lhs[0]) };
            } else {
                fail "Unable to figure out pattern of series";
            }
        }
        default { fail "Unable to figure out pattern of series"; }
    }
}
