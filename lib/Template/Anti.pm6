use v6;

use HTML::Parser::XML;
use XML;

use Template::Anti::NodeSet;
use Template::Anti::Selector;

=begin pod

=TITLE class Template::Anti

=SUBTITLE The anti-template templating tool

=begin SYNOPSIS

    use Template::Anti;
    my $tmpl = Template::Anti.new(
        html => '<html><head><title>Hello World</title>...',
    );

    # But you might just want to work with NodeSets like this:
    $tmpl('title, h1').text('Sith Lords');
    $tmpl('h1').attrib(title => 'The Force shall free me.');
    $tmpl('ul.people').truncate(1).find('li').apply([
        { name => 'Vader',   url => 'http://example.com/vader' },
        { name => 'Sidious', url => 'http://example.com/sidious' },
    ]).via: -> $item, $sith-lord {
        my $a = $item.find('a');
        $a.text($sith-lord<name>);
        $a.attrib(href => $sith-lord<url>);
    });

=end SYNOPSIS

=begin DESCRIPTION

Everyone knows that you should not mix your code with your presentation. Yet, whenever a software engineer needs to render some custom HTML or text or something, the first tool she pulls out of her toolbelt is a templating engine, which does that very thing. Rather than building a file that is neither some nice programming language like Perl6 nor a nice document language like HTML5, she ends up with some evil hybrid that confuses tools made to read either of both of those. Stop it!

There's a better way, L<Template::Anti>, the anti-templating engine. This library splits your presentation from your code in a way that is familiar to many front-end developers, using a select-and-modify methodology similar to jQuery.

=end DESCRIPTION

=head1 Attributes

=head2 has $.html

    has Str $.html

This is the HTML file to use as your template.

=head1 Methods

=head2 method postcircumfix:<( )>

    method postcircumfix:<( )>(Template::Anti:D: Str $selector) returns Template::Anti::NodeSet

Given a selector, this method locates all the matching nodes within the document and returns a L<Template::Anti::NodeSet> which can be used to manipulate all of the matching nodes.

=head2 method render

    method render(Template::Anti:D:) returns Str

Returns the rendered template with all modifications that have been applied thus far.

=head1 Selectors

The following selectors are supported. If these look similar to CSS or jQuery selectors, there's good reason for that. The full set of either of those might not be supported.

For the purpose of matching, selectors only match against element nodes in the document tree and all other nodes are ignored for determining sibling relationships and such.

Any place a string is needed, you may delimiter your string using either a double quote or a single quote. No escapes are provided at this time.

=head2 A B

    body p
    .foo .bar .baz

This is the B<ancestor-child selector>. This matches any node that matches the selector C<B>, which has any ancestor that matches selector C<A>.

=head2 A > B

    ul > li
    .foo > .bar > .baz

This is the B<parent-child selector>. This matches any node that matches the selector C<B>, which is the immediate descendent of a node matching the selector C<A>.

=head2 A + B

    li + li
    .foo + .bar + .baz

This is the B<immediate-sibling selector> This matches any node that matches the selector C<B>, which is the immediate sibling (comes right after within the same parent element) of C<A>.

=head2 *

This is the B<wildcard selector>. It matches any element.

=head2 tagname

    body
    p

This is the B<tag name selector>. It matches any element with a matching tag name.

=head2 .class

    .foo
    .bar.baz

This is the B<class name selector>. It matches any element that has an attribute named C<class> that contains the given word.

=head2 #id

This is the B<id selector>. It matches any element that has an attribute named C<id> which is exactly the same as the given name.

=head2 :contains("text")

This is the B<contains-text selector>. It matches any element that contains that text. This matches both immediate parents of a matched text node and all ancestors.

=head2 [attr|="prefix"]

This is the B<attribute-prefix selector>. It matches any element that contains the named attribute that has a value equal to the given string or whose value starts with that string followed by a hyphen ("-").

=head2 [attr*="string"]

This is the B<attribute-contains selector>. It matches any element that contains the named attribute that has a value that contains the given string.

=head2 [attr~="word"]

This is the B<attribute-word selector>. It matches any element that contains the named attribute that has a value that contains the given word (i.e., the string separated by word boundary).

=head2 [attr$="ending"]

This is the B<attribute-ending selector>. It matches any element that contains the named attribute that has a value that ends with the given string.

=head2 [attr="value"]

This is the B<attribute-equals selector>. It matches any element that contains the named attribute that has a value equal to the given string.

=head2 [attr!="value"]

This is the B<attribute-not-equals selector>. It matches any element that contains the named attribute that has a value not equal to the given string.

=head2 [attr^="start"]

This is the B<attribute start selector>. It matches any element that starts with the named attribute that has a value that starts with the given string.

=end pod

class Template::Anti {
    has Str $.html; #= The HTML source to parse and use for templating.

    has $!parser = HTML::Parser::XML.new;
    has $!source = $!parser.parse($!html);
    has $!sq = Template::Anti::Selector.new(:$!source);

    method postcircumfix:<( )>(Str $selector) {
        my @nodes = $!sq($selector);
        return Template::Anti::NodeSet.new(:@nodes);
    }

    method render {
        multi sub render-walk($print, XML::Document $doc) {
            $print('<!DOCTYPE ' ~ $doc.doctype<type> ~ $doc.doctype<value> ~ '>')
                if $doc.doctype;
            render-walk($print, $doc.root);
        }

        multi sub render-walk($print, XML::Element $el) {
            $print('<' ~ $el.name);
            render-walk($print, $el.attribs);
            if $el.nodes {
                $print('>');
                render-walk($print, $el.nodes);
                $print('</' ~ $el.name ~ '>');
            }
            else {
                $print('/>');
            }
        }

        multi sub render-walk($print, XML::Text $text) {
            $print($text.Str);
        }
        
        multi sub render-walk($print, XML::Comment $comment) {
            $print($comment.Str);
        }
        
        multi sub render-walk($print, XML::PI $pi) { }
        
        multi sub render-walk($print, XML::CDATA $c) {
            my $cdata = $c.data;
            $cdata.=trans('<' => '&lt;', '>' => '&gtl;', '&' => '&amp;');
            $print($cdata);
        }

        multi sub render-walk($print, %attribs) {
            for %attribs.kv -> $k, $v {
                $print(qq[ $k="{$v.trans('"' => '&quot;')}"]);
            }
        }

        multi sub render-walk($print, @nodes) {
            for @nodes -> $node { render-walk($print, $node) };
        }

        multi sub render-walk($print, $anything-else) { !!! }

        my $output = '';
        my $print = -> $str { $output ~= $str };
        render-walk($print, $!source);
        $output;
    }
}
