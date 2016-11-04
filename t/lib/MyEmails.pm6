
use Template::Anti;

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

class MyEmails {
    method hello($email, *%data)
    is anti-template(
        :source<welcome.txt>,
        :format<blanktext>,
    ) {
        $email.set($_, %data{ $_ }) for <name dark-lord>;
    }

    method hello-embedded($email, %adata)
    is anti-template(
        :source<welcome-embedded.txt>,
        :format<blanktext>,
    ) {
        ...
    }
}

