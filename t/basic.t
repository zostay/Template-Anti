#!/usr/bin/env perl6

use v6;

use Test;
use Template::Anti;

my $at = Template::Anti.new(:html("t/basic.html".IO.slurp));

$at('title, h1').text('Sith Lords');
$at('h1').attrib(title => 'The Force shall free me.');
$at('ul.people').truncate(1);
$at('ul.people li').apply([
    { name => 'Vader',   url => 'http://example.com/vader' },
    { name => 'Sidious', url => 'http://example.com/sidious' },
]).via: -> $item, $sith-lord {
    my $a = $item.find('a');
    $a.text($sith-lord<name>);
    $a.attrib(href => $sith-lord<url>);
};

my $output = $at.render;

is "$output\n", "t/basic.out".IO.slurp, 'output is as expected';

done;
