use v6;

use DOM::Tiny;

=begin pod

=NAME Template::Anti - The anti-template templating tool

=begin SYNOPSIS

    use Template::Anti;

    my $source = q:to/END_OF_SOURCE/;
    <html><head><title>Hello World</title></head>
    <body>
        <h1>Hello World</h1>
        <ul class="people">
            <li><a href="/person1'>Alice</a></li>
            <li><a href="/person2'>Bob</a></li>
            <li><a href="/person3'>Charlie</a></li>
        </ul>
    </body></html>
    END_OF_SOURCE

    my &hello = template :$source, -> $dom, $_ {
        $dom('title, h1')».content(.<title>);
        $dom('h1')».attr(title => .<motto>);
        $dom('ul.people li:not(:first-child)')».remove;
        $dom('ul.people li:first-child', :one)\
            .duplicate(.<sith-lords>, -> $item, $_ {
                $item('a', :one).content(.<name>).attr(href => .<url>);
            });
    }

    # Render the output:
    print hello(
        title      => 'Sith Lords',
        motto      => 'The Force shall free me.',
        sith-lords => [
            { name => 'Vader',   url => 'http://example.com/vader' },
            { name => 'Sidious', url => 'http://example.com/sidious' },
        ],
    );

    # Or if you must mix your code and presentation, you can embed the rules
    # within a <script/> tag in the source, which is still better than mixing it
    # all over your HTML:
    my $emb-source = q:to/END_OF_SOURCE/;
    <html><head><title>Hello World</title></head>
    <body>
        <h1>Hello World</h1>
        <ul class="people">
            <li><a href="/person1">Alice</a></li>
            <li><a href="/person2">Bob</a></li>
            <li><a href="/person3">Charlie</a></li>
        </ul>
        <script type="application/anti+perl6" data-dom="$dom">
            $dom('title, h1')».content(.<title>);
            $dom('h1')».attr(title => .<motto>);
            $dom('ul.people li:not(:first-child)')».remove;
            $dom('ul.people li:first-child', :one)\
                .duplicate(.<sith-lords>, -> $item, $_ {
                    $item('a', :one).content(.<name>).attr(href => .<url>);
                });
        </script>
    </body></html>
    END_OF_SOURCE

    my &hello-again = template :source($emb-source), :html, :embedded;
    print hello-again(%vars);

=end SYNOPSIS

=begin DESCRIPTION

It is a generally accepted principle that you should avoid mixing code with
presentation. Yet, whenever a software engineer needs to render some custom HTML
or text or something, the first tool she pulls out of her toolbelt is a
templating engine, which does that very thing. Rather than building a file that
is either some nice programming language like Perl 6 or a decent document
language like HTML5, she ends up with some evil hybrid that:

=item Confuses tools made to read either (or both) of those languages,

=item Adds training overhead and burdensome syntax for your front-end developers to work around,

=item Generally uglifies your code making your templates harder to read as they mix two or three language syntaxes together inline.

This "templating" engine allows you to put an end to that.

This module, L<Template::Anti>, is the anti-templating engine. This library
splits your presentation from your code in a way that is familiar to many
front-end developers, using a select-and-modify methodology similar to jQuery.

It borrows ideas from tools like
L<Template::Pure|https://metacpan.org/pod/HTML::Zoom>,
L<Template::Semantic|https://metacpan.org/pod/Template::Semantic>, and
L<pure.js|https://beebole.com/pure/>.

=end DESCRIPTION

=head1 Template Source

To build a template you need two components:

=item 1. You need some HTML or XML source to work with.

=item 2. You need a block of code to execute against the parsed representation of that source.

There are two different ways to process your templates, inline and out-of-line.
Let's consider the latter first.

=head2 Out-of-Line Processing

This is the pure use-case that completely separates your template from your view
processor, which maximizes reuse. It works like the L</SYNOPSIS> where you
create a template and then apply a set of rules and node-set modifications, like
this:

    my $source = 'index.html'.IO.slurp;
    my &index = template(:$source, -> $dom, $data {
        $dom('title')».content($data<title>);
    });
    say index(:title<Star Wars>);

This is generally the preferred way of using this module.

=head2 Inline Processing

However, it may be convenient to keep your processing code with the template
itself. It would still be appalling to mix template code with code willy-nilly,
but HTML provides a reasonable interface for embedded scripting. Therefore, if
your template contains one or more C«<script></script>» tags formatted properly,
you may use this style instead. For example, here is a simple template you might
have in your assets folder:

    <html>
        <head>
            <title>Hello</title>
            <script type="application/anti+perl6" data-dom="$tmpl" data-stash="$data">
            $tmpl('title', h1').text($data<title>);
            </script>
        </head>
        <body>
            <h1>Hello</h1>
        </body>
    </html>

Both the C<type="application/anti+perl6"> is required. The C<data-dom> and C<data-stash> attributes are optional. These attributes the names of the template variables the engine will provide to the block.

The C<data-dom> names the variable to use for the DOM representation, which will already have the C<script> tag stripped. The default C<data-dom> name is C<"$dom">. The C<data-stash> attribute names the variable to use for the data stash passed in when running the template. The default C<data-stash> name is C<"$_">.

This works whether the template is HTML or XML. However, when templating with XML, it is also recommended that you wrap your code in a C«<![CDATA[ ]]>» section to avoid problems with greater than signs (">"), less than signs ("<"), and ampersands in your code confusing the parser.

To process this template, you can run something like this:

    my $source = 'index.html'.IO.slurp;
    my &index = template(:$source);
    say index(:title<Star Wars>);

If no code reference is passed to C<template>, Template::Anti will attempt to find script tags in the markup itself.

=head1 Exported Routines

=head2 sub template

    sub template(&process?, Str:D :$source!, Str:D :$format = 'html') returns Routine:D

This routine builds a template routine and returns it. The returned routine completely encapsulates the processing of the template.

The C<&process> is optional. When given, it names the routine to call to transform a template source and stash into a final version of the template source. If not given, it is assumed that any processing will be embedded within the template. When given, it must have a signature like the following:

    sub ($dom, %stash) { ... }

The return value of this method is ignored and it should modify the C<$dom> object in place. The type of that C<$dom> object depends on the value of C<$format>.

The C<$source> is required and contains the complete contents of the template source. For HTML, this would be a regular HTML file. For XML, it would be a regular XML file, etc.

The C<$format> tells the C<template> method which format the file is in and how to parse and process it. Template::Anti provides two built-in formats, "html" and "xml", both use a slightly extended L<DOM::Tiny> to parse and process the file. Custom formats can also be crafted. See L</Advanced Formats>.

The format also determines how to extract embedded templates. In the case of "xml" and "html", the embedding is handled via C«<script>» tags that have the type set to "application/anti+perl6". These actually support the use of multiple C«<script>» tags, which are process in order they appear in the file, each getting it's own C<data-dom> and C<data-stash> settings (see L</Inline Processing>).

The returned routine will have the following signature:

    sub (*%stash) returns Str:D { ... }

When called with a stash, that stash will be passed into the C<&process> method (or embedded equivalent). Once C<&process> has been called, the template object (C<$dom> in the signature above), will be stringified by calling the C<Str> method on it. That value is returned.

=head2 multi get-format-object

    multi get-format-object('html')
    multi get-format-object('xml')

These each return a format object that will parse the source using a slightly extended version of L<DOM::Tiny> and return it. They will also extract embedded processing code from C«<script>» tags in the source.

New multis can be defined to extend the formats available to Template::Anti. See L</Advanced Formats> for details.

=head1 DOM::Tiny Customization

Template::Anti uses a slightly customized subclass of L<DOM::Tiny> that provide a couple additional features that are useful when templating. Some or all of these might be rolled up into L<DOM::Tiny> in the future, but they are here for now:

=head2 method postcircumfix:<( )>

    multi method postcircumfix:<( )> ($selector) returns Seq:D
    multi method postcircumfix:<( )> ($selector, Bool :$one) returns DOM::Tiny:D

This allows for a slightly shortened notation when using L<DOM::Tiny>. Basically, the following are equivalent:

    # Long notation
    @ps = $dom.find('p');
    $p  = $dom.at('p');

    # Short notation
    @ps = $dom('p');
    $p  = $dom('p', :one);

Use whichever you prefer.

=head2 method duplicate

    method duplicate(@items, &dup) returns DOM::Tiny:D

This performs a complicated operation that is useful when you want to loop over several stash values and duplicate some part of your DOM using variants. Here's a simple example to illustrate:

    $dom.at('li').duplicate([ 1, 2, 3 ], -> $li, $number {
        $li.content($number);
    });

If our source started out as:

    <ul>
        <li>demo</li>
    </ul>

It would now rea:

    <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
    </ul>

=end pod

my class Template::Anti::DOM::Tiny is DOM::Tiny {
    multi method CALL-ME($selector) {
        self.find($selector);
    }
    multi method CALL-ME($selector, Bool :$one!) {
        self.at($selector);
    }

    multi method duplicate(@items, &dup) {
        my $orig = self.render;
        self.append([~] gather for @items -> $item {
            my $copy = Template::Anti::DOM::Tiny.parse($orig, :xml(self.xml));
            dup($copy, $item);
            take $copy;
        });
        self.remove;
        self;
    }
}

my class Template::Anti::Format::DOM::Tiny {
    method parse($source) {
        Template::Anti::DOM::Tiny.parse($source)
    }
    method embedded-source($dom) {
        my @codes = gather for $dom.find('script[type="application/anti+perl6"]') -> $script {
            my $dom   = $script.attr('data-dom')   // '$dom';
            my $stash = $script.attr('data-stash') // '$_';

            use MONKEY-SEE-NO-EVAL;
            take EVAL "sub ($dom, $stash) \{ {$script.content} }";

            $script.remove;
        }

        sub ($dom, $stash) {
            @codes».($dom, $stash);
        }
    }
}

proto sub get-format-object(|) { * }
multi sub get-format-object('html') is export { Template::Anti::Format::DOM::Tiny }
multi sub get-format-object('xml') is export { Template::Anti::Format::DOM::Tiny }

my sub grab-format($format) {
    CATCH {
        default {
            die qq[unable to build a template for the format named "$format"]
        }
    }

    get-format-object($format);
}

proto sub template(|) { * }
multi sub template(&process, Str:D :$source!, Str:D :$format = 'html') returns Routine:D is export {
    my $format-object = grab-format($format);

    die qq[no format type named "$format" is defined]
         unless $format-object.^can('parse');

    my $struct = $format-object.parse($source);

    sub (*%vars) {
        process($struct, %vars);
        ~$struct;
    }
}

multi sub template(Str:D :$source!, Str:D :$format = 'html') returns Routine:D is export {
    my $format-object = grab-format($format);

    my $struct = $format-object.parse($source);

    die qq[embedded templates are not available for source formatted as "$format"]
        unless $format-object.^can('embedded-source');

    my &process = $format-object.embedded-source($struct);

    sub (*%vars) {
        process($struct, %vars);
        ~$struct;
    }
}

=begin pod

=head1 Advanced Formats

While this library has been built using L<DOM::Tiny> to implement XML and HTML parsing and rendering of template sources, it is possible to extend Template::Anti to support parsing sources in any other format. To do this, you need to define a custom C<multi sub> named C<get-format-object> in your code. For example, here is one built with a couple anonymous classes that will work with plain text files that contain specially formatted blanks.

    multi sub get-format-object('blanktext') {
        class {
            method parse($source) {
                class {
                    has $.source is rw;

                    method set($blank, $value) {
                        $!source ~~ s:g/ < "_$blank_" > /$value/;
                        Mu
                    }

                    method Str { $.source }
                }.new(:$source);
            }

            method embedded-source($struct) {
                my $code;
                ($struct.source, $code) = $struct.source.split("\n__CODE__\n", 2);

                use MONKEY-SEE-NO-EVAL;
                my $sub = $code.EVAL;

                $sub;
            }
        }
    }

This also adds support for embedding the code part of the template in the source following a C<__CODE__> annotation. Here's a couple examples using this custom object:

    my $source = q:to/END_OF_EMAIL/;
    Subject: Welcome _name_ to the Dark Side

    _name_

    Welcome to the Dark Side. Enclosed you will find instructions on how
    to reach the Sith planet to begin your training.

    Love,
    _dark-lord_
    END_OF_EMAIL;

    my &hello = template :$source, -> $email, %data {
        $email.set($var, %data{ $var }) for <name dark-lord>;
    };
    say hello(:name<Starkiller>, :dark-lord<Darth Vader>);

Or if you want to use the embedded version:

    my $source = q:to/END_OF_EMAIL/;
    Subject: Welcome _name_ to the Dark Side

    _name_

    Welcome to the Dark Side. Enclosed you will find instructions on how
    to reach the Sith planet to begin your training.

    Love,
    _dark-lord_

    __CODE__
    sub ($email, %data) {
        $email.set($var, %data{ $var }) for <name dark-lord>;
    }
    END_OF_EMAIL;

    my &hello = template :$source;
    say hello(:name<Starkiller>, :dark-lord<Darth Vader>);

And there you go. You can get code separated from your templates in any format you like.

If your format object does not have an C<embedded-source> method defined, attempting to us the embedded form of C<template> will result in an exception.

Finally, whatever object is used as the parsed structure for your template (i.e., takes the place of the L<DOM::Tiny> object provided with the built-in "xml" and "html" formats) must supply a C<Str> method to render the object to string.

=end pod
