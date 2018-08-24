use v6;

use Test;
use lib 't/lib';
use MyEmails;
use Template::Anti;

class Slurpish {
    has $.file;
    method slurp() { $.file.slurp }
}

my %fake-resources = %(
    "things/welcome.txt" => Slurpish.new(file => "t/resources/welcome.txt".IO),
    "things/welcome-embedded.txt" => Slurpish.new(file => "t/resources/welcome-embedded.txt".IO),
);

my $ta = Template::Anti::Library.new(
    path => Template::Anti::ResourcesPath.new(
        resources => %fake-resources,
        prefix    => 'things',
    ),
    views => { :email(MyEmails.new) },
);

my $expect = "t/resource-extend.out".IO.slurp;

is $ta.process('email.hello', :name<Starkiller>, :dark-lord<Darth Vader>), $expect, "custom format works";
is $ta.process('email.hello-embedded', :name<Starkiller>, :dark-lord<Darth Vader>), $expect, "custom format with embedded code works";

done-testing;
