# Template::Anti

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

Everyone knows that you should not mix your code with your presentation. Yet,
whenever a software engineer needs to render some custom HTML or text or
something, the first tool she pulls out of her toolbelt is a templating engine,
which does that very thing. Rather than building a file that is neither some
nice programming language like Perl6 nor a nice document language like HTML5,
she ends up with some evil hybrid that confuses tools made to read either of
both of those. Stop it!

There's a better way, Template::Anti, the anti-templating engine. This
library splits your presentation from your code in a way that is familiar to
many front-end developers, using a select-and-modify methodology similar to
jQuery.

