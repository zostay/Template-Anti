use v6;

use HTML::Parser::XML;
use XML;

use Template::Anti::Selector;

class Template::Anti::NodeSet {
    has @.nodes;
    has @.data;

    method text(Str $text) {
        self.truncate;
        for @!nodes -> $node {
            $node.append(XML::Text.new(:$text));
        }

        self
    }

    method attrib(*%attribs) {
        for @!nodes -> $node {
            for %attribs.kv -> $name, $value {
                $node.set($name, $value);
            }
        }

        self
    }

    method truncate(Int $keep = 0) {
        for @!nodes -> $node {
            my $kept = 0;

            for $node.nodes {
                when XML::Element { .remove if $kept++ >= $keep }
                default           { .remove }
            }
        }


        self
    }

    method apply(@!data) { self }

    method via(&code) {
        my $needs-cloning = False;
        for @!data -> $d {
            my @nodes = @!nodes;
            if $needs-cloning++ {
                @nodes.=map: {
                    my $clone = $^orig.cloneNode;
                    $orig.parent.append($clone);
                    $clone
                }
            }

            my $node-set = Template::Anti::NodeSet.new(:@nodes);
            &code($node-set, $d);
        }

        self
    }

    method find($selector) {
        my @new-nodes = @!nodes.map: -> $source {
            my $sq = Template::Anti::Selector.new(:$source);
            $sq($selector)
        }

        Template::Anti::NodeSet.new(:nodes(@new-nodes));
    }
}

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
