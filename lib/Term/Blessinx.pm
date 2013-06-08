use NCurses;

my @COLORS = <on_ bright_ on_bright_> X~ <black red green yellow blue magenta cyan white>;
my @PARTS  = @COLORS, <bold underline reverse blink dim italic shadow standout subscript superscript>;

my %SUGARY = <
        save sc
        restore rc

        clear_eol el
        clear_bol el1
        clear_eos ed
        position cup
        enter_fullscreen smcup
        exit_fullscreen rmcup
        move cup
        move_x hpa
        move_y vpa
        move_left cub1
        move_right cuf1
        move_up cuu1
        move_down cud1

        hide_cursor civis
        normal_cursor cnorm

        reset_colors op

        normal sgr0
        reverse rev
        italic sitm
        no_italic ritm
        shadow sshm
        no_shadow rshm
        standout smso
        no_standout rmso
        subscript ssubm
        no_subscript rsubm
        superscript ssupm
        no_superscript rsupm
        underline smul
        no_underline rmul>;

my @SUGARY = %SUGARY.keys;

sub capability_string($name) {
    tigetstr($name);
}

enum Styling <Force-off Detect Force-on>;
class Blessinx::Terminal {
    has $.is-tty;
    has $.does-styling;

    method new(Str $kind, Styling $style-mode) {
        my $is-tty = $*OUT ~~ :t;
        my $does-styling = do given $style-mode {
            when Force-off { False }
            when Force-on { False }
            when Detect { $is-tty }
        }
        setupterm(%*ENV<TERM>);
        return self.bless(*, :$is-tty, :$does-styling);
    }
}

sub make_escape(Str $name) {
    my $begin = $name ~~ /^^on_$$/
       ?? capability_string("setab") // capability_string("setb")
       !! capability_string("setaf") // capability_string("setf");
    
}

grammar PropString {
    rule TOP {
        ^^ <capability>+ % \_ $$
        { make $<capability>>>.ast.join() }
    }
    proto token capability { <...> }
    token capability:sugary { @SUGARY { make make_escape(%SUGARY{$0.Str}) } }
    token capability:regular { @PARTS { make make_escape($0.Str) } }
}

Blessinx::Terminal.^add_fallback(
    -> $, $ { True },
    -> $obj, $methname {
        my $propstr = PropString.parse($methname).ast;
        my $m = method ($text?) {
            if $text.defined {
                $propstr ~ $text ~ self.normal
            } else {
                $propstr
            }
        }
        Blessinx.^add_method($methname, $m);
        return $m;
    });
