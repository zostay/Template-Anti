#!/usr/bin/env perl6

use v6;

use Test;
use Template::Anti::Selector;

use HTML::Parser::XML;

plan *;

my $parser = HTML::Parser::XML.new;
my $xml = $parser.parse("t/basic.html".IO.slurp);

my $helper = Template::Anti::NodeHelper.new(:origin($xml));

my @expected = <
    html head title
    body h1
    ul
    li a
    li a
    li a
>;

for @expected -> $expected {
    my $node = $helper.next-node;
    flunk("did not get something when $expected") unless $node;
    isa_ok $node, XML::Element;
    is $node.name, $expected, "expecting $expected";
}

nok $helper.next-node, "the end";

done;
