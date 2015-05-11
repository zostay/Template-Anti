use v6;

use HTML::Parser::XML;
use XML;

use Template::Anti::NodeSet;
use Template::Anti::Selector;

class Template::Anti {
    has Str $.html;

    has $!parser = HTML::Parser::XML.new;
    has $!source = $!parser.parse($!html);
    has $!sq = Template::Anti::Selector.new(:$!source);

    method postcircumfix:<( )>(Str $selector) {
        my @nodes = $!sq($selector);
        return Template::Anti::NodeSet.new(:@nodes);
    }

    method render {
        return $!source.Str;
    }
}
