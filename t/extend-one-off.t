use v6;

use Test;
use lib 't/lib';
use Template::Anti :one-off;

multi sub get-anti-format-object('blanktext') {
    class {
        method parse($source) {
            class {
                has $.source is rw;

                method set($blank, $value) {
                    $!source ~~ s:g/ "_{$blank}_" /$value/;
                    Mu
                }

                method Str { $.source }
            }.new(:$source);
        }

        method prepare-original($master) {
            $master.clone;
        }

        method embedded-source($master) {
            my $code;
            ($master.source, $code) = $master.source.split("\n__CODE__\n", 2);

            use MONKEY-SEE-NO-EVAL;
            my $sub = $code.EVAL;

            $sub;
        }
    }
}

my $welcome = "t/view/welcome.txt".IO.slurp;
my &hello = anti-template :source($welcome), :format<blanktext>, -> $email, *%data {
    $email.set($_, %data{ $_ }) for <name dark-lord>;
}

my $welcome-embedded = "t/view/welcome-embedded.txt".IO.slurp;
my &hello-embedded = anti-template :source($welcome-embedded), :format<blanktext>;

my $expect = "t/extend.out".IO.slurp;

is hello(:name<Starkiller>, :dark-lord<Darth Vader>), $expect, "custom format works";
is hello-embedded(:name<Starkiller>, :dark-lord<Darth Vader>), $expect, "custom format with embedded code works";

done-testing;
