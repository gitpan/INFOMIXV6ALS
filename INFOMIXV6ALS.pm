package INFOMIXV6ALS;
######################################################################
#
# INFOMIXV6ALS - "Yet Another JPerl" Source code filter to escape INFOMIX V6 ALS
#
#                  http://search.cpan.org/dist/INFOMIXV6ALS/
#
# Copyright (c) 2008, 2009, 2010 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use strict;
use 5.00503;
use Einfomixv6als;
use vars qw($VERSION);

$VERSION = sprintf '%d.%02d', q$Revision: 0.49 $ =~ m/(\d+)/oxmsg;

use Fcntl;
use Symbol;

use Carp qw(carp croak confess cluck verbose);
local $SIG{__DIE__}  = sub { confess @_ } if exists $ENV{'SJIS_DEBUG'};
local $SIG{__WARN__} = sub { cluck   @_ } if exists $ENV{'SJIS_DEBUG'};
local $^W = 1;

$| = 1;

BEGIN {
    if ($^X =~ m/ jperl /oxmsi) {
        croak __FILE__, ": need perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
}

sub import() {}
sub unimport() {}
sub INFOMIXV6ALS::escape_script;

# regexp of character
my $your_char = q{\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF]};
my $qq_char   = qr/\\c[\x40-\x5F]|\\?(?:$your_char)/oxms;
my  $q_char   = qr/$your_char/oxms;

# P.1023 Appendix W.9 Multibyte Anchoring
# of ISBN 1-56592-224-7 CJKV Information Processing

my $your_gap = q{\G(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFD])*?};

use vars qw($nest);

# regexp of nested parens in qqXX

# P.340 Matching Nested Constructs with Embedded Code
# in Chapter 7: Perl
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

my $qq_paren   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\? \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\ [\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_brace   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\? \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\ [\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_bracket = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\? \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\ [\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_angle   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\? \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\ [\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_scalar  = qr{(?: \{ (?:$qq_brace)*? \} |
                       (?: ::)? (?:
                             [a-zA-Z_][a-zA-Z_0-9]*
                       (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                         (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                   ))
                 }xms;
my $qq_variable = qr{(?: \{ (?:$qq_brace)*? \} |
                        (?: ::)? (?:
                              [0-9]+            |
                              [^a-zA-Z_0-9\[\]] |
                              ^[A-Z]            |
                              [a-zA-Z_][a-zA-Z_0-9]*
                        (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                          (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                    ))
                  }xms;

# regexp of nested parens in qXX
my $q_paren    = qr{(?{local $nest=0}) (?>(?:
                    \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_brace    = qr{(?{local $nest=0}) (?>(?:
                    \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_bracket  = qr{(?{local $nest=0}) (?>(?:
                    \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_angle    = qr{(?{local $nest=0}) (?>(?:
                    \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;

my $tr_variable   = '';   # variable of tr///
my $sub_variable  = '';   # variable of s///
my $bind_operator = '';   # =~ or !~
use vars qw($slash);      # when 'm//', '/' means regexp match 'm//' and '?' means regexp match '??'
                          # when 'div', '/' means division operator and '?' means conditional operator (condition ? then : else)
my @heredoc = ();         # here document
my @heredoc_delimiter = ();
my $here_script = '';     # here script
my $function_ord;         # ord()   to ord()   or INFOMIXV6ALS::ord()
my $function_ord_;        # ord     to ord     or INFOMIXV6ALS::ord_
my $function_reverse;     # reverse to reverse or INFOMIXV6ALS::reverse

my $ignore_modules = join('|', qw(
    utf8
    I18N::Japanese
    I18N::Collate
    I18N::JExt
    File::DosGlob
    Wildcard
    Japanese
));

# in Chapter 8: Standard Modules
# of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition

my $standard_modules = join('|', qw(
    AnyDBM_File
    Attribute::Handlers
    attributes
    attrs
    AutoLoader
    AutoSplit
    autouse
    B
    B::Asmdata
    B::Assembler
    B::Bblock
    B::Bytecode
    B::C
    B::CC
    B::Concise
    B::Debug
    B::Deparse
    B::Disassembler
    B::Lint
    B::Showlex
    B::Stackobj
    B::Terse
    B::Xref
    base
    Benchmark
    bigint
    bignum
    bigrat
    blib
    bytes
    ByteLoader
    Carp
    CGI
    CGI::Apache
    CGI::Carp
    CGI::Cookie
    CGI::Fast
    CGI::Pretty
    CGI::Push
    CGI::Switch
    charnames
    Class::ISA
    Class::Struct
    Config
    constant
    CPAN
    CPAN::FirstTime
    CPAN::Nox
    Cwd
    Data::Dumper
    DB
    DB_File
    Devel::DProf
    Devel::PPPort
    Devel::SelfStubber
    diagnostics
    Digest
    Digest::MD5
    DirHandle
    Dumpvalue
    DynaLoader
    encoding
    English
    Env
    Errno
    Exporter
    ExtUtils::Command
    ExtUtils::Command::MM
    ExtUtils::Constant
    ExtUtils::Embed
    ExtUtils::Install
    ExtUtils::Installed
    ExtUtils::Liblist
    ExtUtils::MakeMaker
    ExtUtils::Manifest
    ExtUtils::Miniperl
    ExtUtils::Mkbootstrap
    ExtUtils::Mksymlists
    ExtUtils::MM
    ExtUtils::MM_Any
    ExtUtils::MM_BeOS
    ExtUtils::MM_DOS
    ExtUtils::MM_NW5
    ExtUtils::MM_OS2
    ExtUtils::MM_Unix
    ExtUtils::MM_UWIN
    ExtUtils::MM_VMS
    ExtUtils::MM_Win32
    ExtUtils::MY
    ExtUtils::Packlist
    ExtUtils::testlib
    Fatal
    Fcntl
    fields
    File::Basename
    File::CheckTree
    File::Compare
    File::Copy
    File::DosGlob
    File::Find
    File::Path
    File::Spec
    File::Spec::Cygwin
    File::Spec::Mac
    File::Spec::OS2
    File::Spec::Unix
    File::Spec::VMS
    File::Spec::Win32
    File::stat
    File::Temp
    FileCache
    FileHandle
    Filter::Simple 
    Filter::Util::Call
    FindBin
    GDBM_File
    Getopt::Long
    Getopt::Std
    Hash::Util
    I18N::Collate
    I18N::Langinfo
    I18N::LangTags
    I18N::LangTags::List
    if
    integer
    IO
    IO::File
    IO::Handle
    IO::Pipe
    IO::Seekable
    IO::Select
    IO::Socket
    IPC::Msg
    IPC::Open2
    IPC::Open3
    IPC::Semaphore
    IPC::SysV
    less
    lib
    List::Util
    locale
    Math::BigFloat
    Math::BigInt
    Math::BigInt::Calc
    Math::BigRat
    Math::Complex
    Math::Trig
    MIME::Base64
    MIME::QuotedPrint
    NDBM_File
    Net::Cmd
    Net::Config
    Net::Domain
    Net::FTP
    Net::hostent
    Net::netent
    Net::Netrc
    Net::NNTP
    Net::Ping
    Net::POP3
    Net::protoent
    Net::servent
    Net::SMTP
    Net::Time
    O
    ODBM_File
    Opcode
    ops
    overload
    PerlIO
    PerlIO::Scalar
    PerlIO::Via
    Pod::Functions
    Pod::Html
    Pod::ParseLink
    Pod::Text
    POSIX
    re
    Safe
    Scalar::Util
    SDBM_File
    Search::Dict
    SelectSaver
    SelfLoader
    Shell
    sigtrap
    Socket
    sort
    Storable
    strict
    subs
    Switch
    Symbol
    Sys::Hostname
    Sys::Syslog
    Term::Cap
    Term::Complete
    Term::ReadLine
    Test
    Test::Builder
    Test::Harness
    Test::More
    Test::Simple
    Text::Abbrev
    Text::Balanced
    Text::ParseWords
    Text::Soundex
    Text::Tabs
    Text::Wrap
    Thread
    Thread::Queue
    Thread::Semaphore
    Thread::Signal
    Thread::Specific
    Tie::Array
    Tie::StdArray
    Tie::File
    Tie::Handle
    Tie::Hash
    Tie::Memoize 
    Tie::RefHash
    Tie::Scalar
    Tie::SubstrHash
    Time::gmtime
    Time::HiRes
    Time::Local
    Time::localtime
    Time::tm
    UNIVERSAL
    User::grent
    User::pwent
    utf8
    vars
    vmsish
    XS::Typemap
));

# when this script is main program
if ($0 eq __FILE__) {

    # show usage
    unless (@ARGV) {
        die <<END;
$0: usage

perl $0 INFOMIX V6 ALS_script.pl > Escaped_script.pl.e
END
    }

    print INFOMIXV6ALS::escape_script($ARGV[0]);
    exit 0;
}

my $__PACKAGE__ = __PACKAGE__;
my $__FILE__    = __FILE__;
my($package,$filename,$line,$subroutine,$hasargs,$wantarray,$evaltext,$is_require,$hints,$bitmask) = caller 0;

# called any package not main
if ($package ne 'main') {
    croak <<END;
$__FILE__: escape by manually command '$^X $__FILE__ "$filename" > "$__PACKAGE__::$filename"'
and rewrite "use $package;" to "use $__PACKAGE__::$package;" of script "$0".
END
}

# delete escaped script always while debug
if (exists $ENV{'SJIS_DEBUG'}) {
#   print STDERR "$__FILE__: delete $filename.e (\$ENV{'SJIS_DEBUG'}=$ENV{'SJIS_DEBUG'})\n";

    Einfomixv6als::unlink "$filename.e";
}

# make escaped script
my $e_script  = '';

my $e_mtime   = (Einfomixv6als::stat("$filename.e"))[9];
my $mtime     = (Einfomixv6als::stat($filename))[9];
my $__mtime__ = (Einfomixv6als::stat($__FILE__))[9];
if ((not Einfomixv6als::e("$filename.e")) or ($e_mtime < $mtime) or ($mtime < $__mtime__)) {
    my $fh = Symbol::gensym();
    sysopen($fh, "$filename.e", O_WRONLY | O_TRUNC | O_CREAT) or croak "$__FILE__: Can't open file: $filename.e";
    print {$fh} INFOMIXV6ALS::escape_script($filename);
    close($fh) or croak "$__FILE__: Can't close file: $filename.e";
}

# P.565 23.1.2. Cleaning Up Your Environment
# in Chapter 23: Security
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# local $ENV{'PATH'} = '.';
local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

exit system map {m/ $your_gap [ ] /oxms ? qq{"$_"} : $_} $^X, "$filename.e", @ARGV;

# escape INFOMIX V6 ALS script
sub INFOMIXV6ALS::escape_script {
    my($script) = @_;
    my $e_script = '';

    # read INFOMIX V6 ALS script
    my $fh = Symbol::gensym();
    sysopen($fh, $script, O_RDONLY) or croak "$__FILE__: Can't open file: $script";
    local $/ = undef; # slurp mode
    $_ = <$fh>;
    close($fh) or croak "$__FILE__: Can't close file: $script";

    if (m/^ use Einfomixv6als(?:\s+[0-9\.]*)?\s*; $/oxms) {
        return $_;
    }
    else {

        # #! shebang line
        if (s/\A(#!.+?\n)//oms) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            $e_script .= $head;
        }

        # P.618 Generating Perl in Other Languages
        # in Chapter 24: Common Practices
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        if (m/(.*^#\s*line\s+\d+(?:\s+"(?:$q_char)+?")?\s*\n)/omsgc) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            $e_script .= $head;
        }

        # P.210 5.10.3.3. Match-time code evaluation
        # in Chapter 5: Pattern Matching
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        $e_script .= sprintf(<<'END', $Einfomixv6als::VERSION); # require run-time routines version
use Einfomixv6als %s;
use re 'eval';
END

        # use INFOMIXV6ALS version qw(ord reverse);
        $function_ord     = 'ord';
        $function_ord_    = 'ord';
        $function_reverse = 'reverse';
        if (s/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $//oxms) {

            # require version
            my $list = $1;
            if ($list =~ s/\A ([0-9]+(?:\.[0-9]*)) \s* //oxms) {
                my $version = $1;
                if ($version > $VERSION) {
                    croak "$__FILE__: version $version required--this is only version $VERSION";
                }
            }

            # demand ord and reverse
            if ($list !~ m/\A \s* \z/oxms) {
                local $@;
                my @list = eval $list;
                for (@list) {
                    $function_ord     = 'INFOMIXV6ALS::ord'     if m/\A ord \z/oxms;
                    $function_ord_    = 'INFOMIXV6ALS::ord_'    if m/\A ord \z/oxms;
                    $function_reverse = 'INFOMIXV6ALS::reverse' if m/\A reverse \z/oxms;
                }
            }
        }
    }

    # use Tk; --> use INFOMIXV6ALS::Tk::Widget;
    my $tkmodule = '';
    for my $widget (qw(
        Button
        Canvas
        Checkbutton
        Entry
        Frame
        Label
        Listbox
        MainWindow
        Message
        Menu
        Menubutton
        Radiobutton
        Scale
        Text
        Toplevel
    )) {
        if (m/ $widget /xms) {
            $tkmodule .= "        eval qq{ use INFOMIXV6ALS::Tk::$widget; };\n";
        }
    }

    my $use_tk = <<"USE_TK";
BEGIN {
    eval qq{ use INFOMIXV6ALS::Encode; };
    if (\$] >= 5.007) {
$tkmodule
    }
    else {
        eval qq{ use INFOMIXV6ALS::Tk::Entry55; };
        eval qq{ use INFOMIXV6ALS::Tk::MainWindow; };
    }
}
USE_TK
    if (s/^ (\s* use \s+ Tk [^:;]* ; \s*? \n) /$1$use_tk/oxmsg) {
        s/ \b (MainWindow \s* -> \s* new) \b /INFOMIXV6ALS::Tk::$1/oxmsg;
        s/^ (\s* use \s+ )(Tk::(?:Ballon|BrowseEntry|ColorEditor|Dialog|DialogBox|DirTree|FileSelect|HList|ROText|Table|TixGrid|TList|Tree) [^:;]* ; \s*? ) \n /BEGIN { eval qq{ $1$2 ${1}INFOMIXV6ALS::${2} }};\n/oxmsg;
        s/^ (\s* use \s+ )(Tk::(?:LabFrame) [^:;]*) ; \s*? \n /BEGIN { eval qq{ $1$2; ${1}INFOMIXV6ALS::${2}55; }};\n/oxmsg;
    }

    $slash = 'm//';

    # Yes, I studied study yesterday.

    # P.359 The Study Function
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    study $_;

    # while all script

    # one member of Tag-team
    #
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    while (not /\G \z/oxgc) { # member
        $e_script .= escape();
    }

    return $e_script;
}

# escape INFOMIX V6 ALS part of script
sub escape {

# \n output here document

    # another member of Tag-team
    #
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    if (/\G ( \n ) /oxgc) { # another member (and so on)
        my $heredoc = '';
        if (scalar(@heredoc_delimiter) >= 1) {
            $slash = 'm//';

            $heredoc = join '', @heredoc;
            @heredoc = ();

            # skip here document
            for my $heredoc_delimiter (@heredoc_delimiter) {
                /\G .*? \n $heredoc_delimiter \n/xmsgc;
            }
            @heredoc_delimiter = ();

            $here_script = '';
        }
        return "\n" . $heredoc;
    }

# ignore space, comment
    elsif (/\G (\s+|\#.*) /oxgc) { return $1; }

# if (, elsif (, unless (, while (, until (, given ( and when (

    # given, when
    #
    # P.225 The given Statement
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    elsif (/\G ( (?: if | elsif | unless | while | until | given | when ) \s* \( ) /oxgc) {
        $slash = 'm//';
        return $1;
    }

# scalar variable ($scalar = ...) =~ tr///;
# scalar variable ($scalar = ...) =~ s///;

    # state
    #
    # P.68 Persistent, Private Variables
    # in Chapter 4: Subroutines
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition
    # (and so on)

    elsif (/\G ( \( \s* (?: local \b | my \b | our \b | state \b )? \s* \$ $qq_scalar ) /oxgc) {
        my $e_string = e_string($1);

        if (/\G ( \s* = $qq_paren \) ) ( \s* (?: =~ | !~ ) \s* ) (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( \s* = $qq_paren \) ) ( \s* (?: =~ | !~ ) \s* ) (?= s \b ) /oxgc) {
            $sub_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $e_string;
        }
    }

# scalar variable $scalar =~ tr///;
# scalar variable $scalar =~ s///;
    elsif (/\G ( \$ $qq_scalar ) /oxgc) {
        my $scalar = e_string($1);

        if (/\G ( \s* (?: =~ | !~ ) \s* ) (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( \s* (?: =~ | !~ ) \s* ) (?= s \b ) /oxgc) {
            $sub_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $scalar;
        }
    }

    # end of statement
    elsif (/\G ( [,;] ) /oxgc) {
        $slash = 'm//';

        # clear tr/// variable
        $tr_variable  = '';

        # clear s/// variable
        $sub_variable  = '';

        $bind_operator = '';

        return $1;
    }

# bareword
    elsif (/\G ( \{ \s* (?: tr|index|rindex|reverse) \s* \} ) /oxmsgc) {
        return $1;
    }

# $0 --> $0
    elsif (/\G ( \$ 0 ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    elsif (/\G ( \$ \{ \s* 0 \s* \} ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $$ --> $$
    elsif (/\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $1, $2, $3 --> $2, $3, $4
    elsif (/\G \$ ([1-9][0-9]*) /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . ')}';
    }
    elsif (/\G \$ \{ \s* ([1-9][0-9]*) \s* \} /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . ')}';
    }

# $$foo[ ... ] --> $ $foo->[ ... ]
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ .+? \] ) /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
    }

# $$foo{ ... } --> $ $foo->{ ... }
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ .+? \} ) /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
    }

# $$foo
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . ')}';
    }

# ${ foo }
    elsif (/\G \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} /oxmsgc) {
        $slash = 'div';
        return '${' . $1 . '}';
    }

# ${ ... }
    elsif (/\G \$ \s* \{ \s* ( $qq_brace ) \s* \} /oxmsgc) {
        $slash = 'div';
        return '${Einfomixv6als::capture(' . $1 . ')}';
    }

# variable or function
    #                  $ @ % & *     $ #
    elsif (/\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr|glob|lstat|opendir|stat|unlink|chdir) ) \b /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    #                $ $ $ $ $ $ $ $ $ $ $ $ $ $ $
    #                $ @ # \ ' " ` / ? ( ) [ ] < >
    elsif (/\G ( \$[\$\@\#\\\'\"\`\/\?\(\)\[\]\<\>] ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# while (<FILEHANDLE>)
    elsif (/\G \b (while \s* \( \s* <[\$]?[A-Za-z_][A-Za-z_0-9]*> \s* \)) \b /oxgc) {
        return $1;
    }

# while (<WILDCARD>) --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G \b while \s* \( \s* < ((?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^>\0\a\e\f\n\r\t])+?) > \s* \) \b /oxgc) {
        return 'while ($_ = Einfomixv6als::glob("' . $1 . '"))';
    }

# while (glob)
    elsif (/\G \b while \s* \( \s* glob \s* \) /oxgc) {
        return 'while ($_ = Einfomixv6als::glob_)';
    }

# while (glob(WILDCARD))
    elsif (/\G \b while \s* \( \s* glob \b /oxgc) {
        return 'while ($_ = Einfomixv6als::glob';
    }

# doit if, doit unless, doit while, doit until, doit for
    elsif (m{\G \b ( if | unless | while | until | for ) \b }oxgc) { $slash = 'm//'; return $1;  }

# functions of package Einfomixv6als
    elsif (m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $slash = 'm//'; return $1;    }
    elsif (m{\G \b chop \b          (?! \s* => )              }oxgc) { $slash = 'm//'; return   'Einfomixv6als::chop';         }
    elsif (m{\G \b INFOMIXV6ALS::index \b   (?! \s* => )              }oxgc) { $slash = 'm//'; return   'INFOMIXV6ALS::index';         }
    elsif (m{\G \b index \b         (?! \s* => )              }oxgc) { $slash = 'm//'; return   'Einfomixv6als::index';        }
    elsif (m{\G \b INFOMIXV6ALS::rindex \b  (?! \s* => )              }oxgc) { $slash = 'm//'; return   'INFOMIXV6ALS::rindex';        }
    elsif (m{\G \b rindex \b        (?! \s* => )              }oxgc) { $slash = 'm//'; return   'Einfomixv6als::rindex';       }
    elsif (m{\G \b lc    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::lc';           }
    elsif (m{\G \b uc    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::uc';           }

    # stacked file test operators
    #
    # P.179 File Test Operators
    # in Chapter 12: File Tests
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition
    # (and so on)

    elsif (m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                                                           \s* (\") ((?:$qq_char)+?)             (\") }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\#) ((?:$qq_char)+?)             (\#) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\() ((?:$qq_paren)+?)            (\)) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\{) ((?:$qq_brace)+?)            (\}) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\[) ((?:$qq_bracket)+?)          (\]) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\<) ((?:$qq_angle)+?)            (\>) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\S) ((?:$qq_char)+?)             (\3) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                                                           \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) }oxgc) { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }

    elsif (m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+) (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) }oxgc)
                                                                                                             { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1),$2)"; }
    elsif (m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+) \( ((?:$qq_paren)*?) \) }oxgc)
                                                                                                             { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1),$2)"; }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) (?= [a-z]+) }oxgc)                                   { $slash = 'm//'; return "Einfomixv6als::filetest qw($1),";    }
    elsif (m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) (\w+) }oxgc)                                         { $slash = 'm//'; return "Einfomixv6als::filetest(qw($1),$2)"; }

    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+    \s* (\") ((?:$qq_char)+?)             (\") }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('',  $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('',  $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) }oxgc)    { $slash = 'm//'; return "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; }

    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) }oxgc)
                                                                                                             { $slash = 'm//'; return "Einfomixv6als::$1($2)"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s* \( ((?:$qq_paren)*?) \) }oxgc)                          { $slash = 'm//'; return "Einfomixv6als::$1($2)"; }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) (?= \s+ [a-z]+) }oxgc)                                      { $slash = 'm//'; return "Einfomixv6als::$1";     }
    elsif (m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ (\w+) }oxgc)                                            { $slash = 'm//'; return "Einfomixv6als::$1($2)"; }
    elsif (m{\G \b lstat (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::lstat';              }
    elsif (m{\G \b stat  (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::stat';               }
    elsif (m{\G \b chr   (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::chr';                }
    elsif (m{\G \b ord   (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'div'; return   $function_ord;               }
    elsif (m{\G \b glob  (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $slash = 'm//'; return   'Einfomixv6als::glob';               }
    elsif (m{\G \b lc \b      (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::lc_';                }
    elsif (m{\G \b uc \b      (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::uc_';                }

    elsif (m{\G    (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                           \b (?! \s* => )                    }oxgc) { $slash = 'm//'; return   "Einfomixv6als::filetest_(qw($1))";  }
    elsif (m{\G    -([rwxoRWXOezsfdlpSbctugkTBMAC])
                           \b (?! \s* => )                    }oxgc) { $slash = 'm//'; return   "Einfomixv6als::${1}_";              }
    elsif (m{\G \b lstat \b   (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::lstat_';             }
    elsif (m{\G \b stat \b    (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::stat_';              }
    elsif (m{\G \b chr \b     (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::chr_';               }
    elsif (m{\G \b ord \b     (?! \s* => )                    }oxgc) { $slash = 'div'; return   $function_ord_;              }
    elsif (m{\G \b glob \b    (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::glob_';              }
    elsif (m{\G \b reverse \b (?! \s* => )                    }oxgc) { $slash = 'm//'; return   $function_reverse;           }
    elsif (m{\G \b opendir (\s* \( \s*) (?=[A-Za-z_])         }oxgc) { $slash = 'm//'; return   "Einfomixv6als::opendir$1*";         }
    elsif (m{\G \b opendir (\s+)        (?=[A-Za-z_])         }oxgc) { $slash = 'm//'; return   "Einfomixv6als::opendir$1*";         }
    elsif (m{\G \b unlink \b  (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::unlink';             }
    elsif (m{\G \b chdir \b   (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Einfomixv6als::chdir';              }

# split
    elsif (m{\G \b (split) \b (?! \s* => ) }oxgc) {
        $slash = 'm//';

        my $e = 'Einfomixv6als::split';

        while (/\G ( \s+ | \( | \#.* ) /oxgc) {
            $e .= $1;
        }

# end of split
        if    (/\G (?= [,;\)\}\]] )          /oxgc) { return $e;                 }

# split scalar value
        elsif (/\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { return $e . e_string($1);  }

# split literal space
        elsif (/\G \b qq       (\#) [ ] (\#) /oxgc) { return $e . qq  {qq$1 $2}; }
        elsif (/\G \b qq (\s*) (\() [ ] (\)) /oxgc) { return $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\{) [ ] (\}) /oxgc) { return $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\[) [ ] (\]) /oxgc) { return $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\<) [ ] (\>) /oxgc) { return $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\S) [ ] (\2) /oxgc) { return $e . qq{$1qq$2 $3}; }
        elsif (/\G \b q        (\#) [ ] (\#) /oxgc) { return $e . qq   {q$1 $2}; }
        elsif (/\G \b q  (\s*) (\() [ ] (\)) /oxgc) { return $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\{) [ ] (\}) /oxgc) { return $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\[) [ ] (\]) /oxgc) { return $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\<) [ ] (\>) /oxgc) { return $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\S) [ ] (\2) /oxgc) { return $e . qq {$1q$2 $3}; }
        elsif (/\G                ' [ ] '    /oxgc) { return $e . qq     {' '};  }
        elsif (/\G                " [ ] "    /oxgc) { return $e . qq     {" "};  }

# split qq//
        elsif (/\G \b (qq) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { return $e . e_split('qr',$1,$3,$2,'');   } # qq# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                             /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_split('qr',$1,$3,$2,'');   } # qq ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_split('qr',$1,$3,$2,'');   } # qq { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_split('qr',$1,$3,$2,'');   } # qq [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_split('qr',$1,$3,$2,'');   } # qq < > --> qr < >
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_split('qr','{','}',$2,''); } # qq | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_split('qr',$1,$3,$2,'');   } # qq * * --> qr * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# split qr//
        elsif (/\G \b (qr) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxp]*) /oxgc)                        { return $e . e_split  ('qr',$1,$3,$2,$4);   } # qr# #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                         /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxp]*) /oxgc) { return $e . e_split_q('qr',$1, $3, $2,$4); } # qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { return $e . e_split  ('qr','{','}',$2,$4); } # qr | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # qr * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# split q//
        elsif (/\G \b (q) \b /oxgc) {
            if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { return $e . e_split_q('qr',$1,$3,$2,'');   } # q# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif (/\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { return $e . e_split_q('qr',$1,$3,$2,'');   } # q ( ) --> qr ( )
                    elsif (/\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { return $e . e_split_q('qr',$1,$3,$2,'');   } # q { } --> qr { }
                    elsif (/\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { return $e . e_split_q('qr',$1,$3,$2,'');   } # q [ ] --> qr [ ]
                    elsif (/\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { return $e . e_split_q('qr',$1,$3,$2,'');   } # q < > --> qr < >
                    elsif (/\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { return $e . e_split_q('qr','{','}',$2,''); } # q | | --> qr { }
                    elsif (/\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { return $e . e_split_q('qr',$1,$3,$2,'');   } # q * * --> qr * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# split m//
        elsif (/\G \b (m) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxp]*) /oxgc)                        { return $e . e_split  ('qr',$1,$3,$2,$4);   } # m# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                           /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # m ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # m { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # m [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # m < > --> qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxp]*) /oxgc) { return $e . e_split_q('qr',$1, $3, $2,$4); } # m ' ' --> qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr','{','}',$2,$4); } # m | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { return $e . e_split  ('qr',$1, $3, $2,$4); } # m * * --> qr * *
                }
                croak "$__FILE__: Search pattern not terminated";
            }
        }

# split ''
        elsif (/\G (\') /oxgc) {
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1; }
                elsif (/\G (\\\')    /oxgc) { $q_string .= $1; }                               # splitqr'' --> split qr''
                elsif (/\G \'        /oxgc)                                                    { return $e . e_split_q(q{ qr},"'","'",$q_string,''); } # ' ' --> qr ' '
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1; }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }

# split ""
        elsif (/\G (\") /oxgc) {
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $qq_string .= $1; }
                elsif (/\G (\\\")    /oxgc) { $qq_string .= $1; }                              # splitqr"" --> split qr""
                elsif (/\G \"        /oxgc)                                                    { return $e . e_split(q{ qr},'"','"',$qq_string,''); } # " " --> qr " "
                elsif (/\G ($q_char) /oxgc) { $qq_string .= $1; }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }

# split //
        elsif (/\G (\/) /oxgc) {
            my $regexp = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)           /oxgc) { $regexp .= $1; }
                elsif (/\G (\\\/)           /oxgc) { $regexp .= $1; }                          # splitqr// --> split qr//
                elsif (/\G \/ ([cgimosxp]*) /oxgc)                                             { return $e . e_split(q{ qr}, '/','/',$regexp,$1); } # / / --> qr / /
                elsif (/\G ($q_char)        /oxgc) { $regexp .= $1; }
            }
            croak "$__FILE__: Search pattern not terminated";
        }
    }

# tr/// or y///

    # about [cdsbB]* (/B modifier)
    #
    # P.559 appendix C
    # of ISBN 4-89052-384-7 Programming perl
    # (Japanese title is: Perl puroguramingu)

    elsif (/\G \b (tr|y) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cdsbB]*) /oxgc) { # tr# # #
            my @tr = ($tr_variable,$2);
            return e_tr(@tr,'',$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) * *
                    }
                    croak "$__FILE__: Transliteration replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } * *
                    }
                    croak "$__FILE__: Transliteration replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] * *
                    }
                    croak "$__FILE__: Transliteration replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > * *
                    }
                    croak "$__FILE__: Transliteration replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cdsbB]*) /oxgc) { # tr * * *
                    my @tr = ($tr_variable,$2);
                    return e_tr(@tr,'',$4,$6);
                }
            }
            croak "$__FILE__: Transliteration pattern not terminated";
        }
    }

# qq//
    elsif (/\G \b (qq) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { return e_qq($ope,$1,$3,$2); } # qq# #
        if (/\G (\#) /oxgc) {                                                     # qq# #
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\\\#)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\#)       /oxgc) { return e_qq($ope,'#','#',$qq_string); }
                elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                     }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq ( )
                elsif (/\G (\() /oxgc) {                                                           # qq ( )
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\))     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\()       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\))       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'(',')',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq { }
                elsif (/\G (\{) /oxgc) {                                                           # qq { }
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\})     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\{)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\})       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'{','}',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq [ ]
                elsif (/\G (\[) /oxgc) {                                                             # qq [ ]
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\])     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\[)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\])       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'[',']',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq < >
                elsif (/\G (\<) /oxgc) {                                                           # qq < >
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\>)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\<)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\>)       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'<','>',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq * *
                elsif (/\G (\S) /oxgc) {                                                          # qq * *
                    my $delimiter = $1;
                    my $qq_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_qq($ope,$delimiter,$delimiter,$qq_string); }
                        elsif (/\G ($qq_char)         /oxgc) { $qq_string .= $1;                                        }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }
    }

# qr//
    elsif (/\G \b (qr) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxp]*) /oxgc) { # qr# # #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                         /oxgc) { $e .= $1; }
                elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr ( )
                elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr { }
                elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr [ ]
                elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr < >
                elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxp]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # qr ' '
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # qr | | --> qr { }
                elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr * *
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }
    }

# qw//
    elsif (/\G \b (qw) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) (.*?) (\#) /oxmsgc) { # qw# #
            return e_qw($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                            /oxgc)   { $e .= $1; }

                elsif (/\G (\()          ([^(]*?)           (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )
                elsif (/\G (\()          ((?:$q_paren)*?)   (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )

                elsif (/\G (\{)          ([^{]*?)           (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }
                elsif (/\G (\{)          ((?:$q_brace)*?)   (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }

                elsif (/\G (\[)          ([^[]*?)           (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]
                elsif (/\G (\[)          ((?:$q_bracket)*?) (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]

                elsif (/\G (\<)          ([^<]*?)           (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >
                elsif (/\G (\<)          ((?:$q_angle)*?)   (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >

                elsif (/\G ([\x21-\x3F]) (.*?)              (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
                elsif (/\G (\S)          ((?:$q_char)*?)    (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }
    }

# qx//
    elsif (/\G \b (qx) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
            return e_qq($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx ( )
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx { }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx [ ]
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx < >
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . e_q ($ope,$1,$3,$2); } # qx ' '
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx * *
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }
    }

# q//
    elsif (/\G \b (q) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { return e_q($ope,$1,$3,$2); } # q# #

        # avoid "Error: Runtime exception" of perl version 5.005_03
        # (and so on)

        if (/\G (\#) /oxgc) {                                                             # q# #
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\\\#)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\#)      /oxgc) { return e_q($ope,'#','#',$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                    }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                           /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:\\\)|\\\\|$q_paren)*?) (\)) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q ( )
                elsif (/\G (\() /oxgc) {                                                                   # q ( )
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\))    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\()    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\()      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\))      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'(',')',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:\\\}|\\\\|$q_brace)*?) (\}) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q { }
                elsif (/\G (\{) /oxgc) {                                                                   # q { }
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\})    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\{)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\{)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\})      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'{','}',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q [ ]
                elsif (/\G (\[) /oxgc) {                                                                     # q [ ]
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\])    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\[)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\[)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\])      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'[',']',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:\\\>|\\\\|$q_angle)*?) (\>) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q < >
                elsif (/\G (\<) /oxgc) {                                                                   # q < >
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\>)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\<)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\<)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\>)      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'<','>',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:\\\1|\\\\|$q_char)*?) (\1) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q * *
                elsif (/\G (\S) /oxgc) {                                                                  # q * *
                    my $delimiter = $1;
                    my $q_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_q($ope,$delimiter,$delimiter,$q_string); }
                        elsif (/\G ($q_char)          /oxgc) { $q_string .= $1;                                       }
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }
            }
            croak "$__FILE__: Can't find string terminator anywhere before EOF";
        }
    }

# m//
    elsif (/\G \b (m) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxp]*) /oxgc) { # m# #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                           /oxgc) { $e .= $1; }
                elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m ( )
                elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m { }
                elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m [ ]
                elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m < >
                elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxp]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # m ' '
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # m | | --> m { }
                elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m * *
            }
            croak "$__FILE__: Search pattern not terminated";
        }
    }

# s///

    # about [cegimosxp]* (/cg modifier)
    #
    # P.67 Pattern-Matching Operators
    # of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition.

    elsif (/\G \b (s) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cegimosxp]*) /oxgc) { # s# # #
            return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                   /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    croak "$__FILE__: Substitution replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                   /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    croak "$__FILE__: Substitution replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                   /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    croak "$__FILE__: Substitution replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                   /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxp]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    croak "$__FILE__: Substitution replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\') ((?:$qq_char)*?) (\') ((?:$qq_char)*?) (\') ([cegimosxp]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1            $2               $3   $4               $5   $6
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxp]*) /oxgc) {
                    return e_sub($sub_variable,'{',$2,'}','{',$4,'}',$6); # s | | | --> s { } { }
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\$) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxp]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxp]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
            }
            croak "$__FILE__: Substitution pattern not terminated";
        }
    }

# do
    elsif (/\G \b do (?= \s* \{ )                    /oxmsgc) { return 'do';        }
    elsif (/\G \b do (?= \s+ (?: q|qq|qx) \b)        /oxmsgc) { return 'Einfomixv6als::do'; }
    elsif (/\G \b do (?= \s+ \w+)                    /oxmsgc) { return 'do';        }
    elsif (/\G \b do (?= \s* \$ \w+ (?: ::\w+)* \( ) /oxmsgc) { return 'do';        }
    elsif (/\G \b do \b                              /oxmsgc) { return 'Einfomixv6als::do'; }

# require ignore module
    elsif (/\G \b require \s+ ($ignore_modules) \b              /oxmsgc) { return "# require $1";    }

# require standard module
    elsif (/\G \b require \s+ ($standard_modules) \b            /oxmsgc) { return "require $1";      }

# require
    elsif (/\G \b require \s+ (v? [0-9]+(?: [._][0-9]+)*) \s* ; /oxmsgc) { return "require $1;";     }
    elsif (/\G \b require \s+ (\w+(?: ::\w+)*)            \s* ; /oxmsgc) { return e_require($1);     }
    elsif (/\G \b require                                 \s* ; /oxmsgc) { return 'Einfomixv6als::require;'; }
    elsif (/\G \b require \b                                    /oxmsgc) { return 'Einfomixv6als::require';  }

# use ignore module
    elsif (/\G \b use \s+ ($ignore_modules) \b                                        /oxmsgc) { return "# use $1";         }

# use standard module
    elsif (/\G \b use \s+ ($standard_modules) \b                                      /oxmsgc) { return "use $1";           }

# use without import
    elsif (/\G \b use \s+ (v? [0-9]+(?: [._][0-9]+)*)                           \s* ; /oxmsgc) { return "use $1;";          }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s*        (\()          \s* \) \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\()          \s* \) \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\{)          \s* \} \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\[)          \s* \] \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\<)          \s* \> \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* ([\x21-\x3F]) \s* \2 \s* ; /oxmsgc) { return e_use_noimport($1); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\S)          \s* \2 \s* ; /oxmsgc) { return e_use_noimport($1); }

# use with import no parameter
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*)                                 \s* ; /oxmsgc) { return e_use_noparam($1);  }

# use with import parameters
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\()          [^)]*         \)) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\')          [^']*         \') \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\")          [^"]*         \") \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\()          [^)]*         \)) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\{)          (?:$q_char)*? \}) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\[)          (?:$q_char)*? \]) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\<)          [^>]*         \>) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* ([\x21-\x3F]) .*?           \3) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\S)          (?:$q_char)*? \3) \s* ; /oxmsgc) { return e_use($1,$2); }

# ''
    elsif (/\G (?<![\w\$\@\%\&\*]) (\') /oxgc) {
        my $q_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $q_string .= $1;                   }
            elsif (/\G (\\\')    /oxgc)            { $q_string .= $1;                   }
            elsif (/\G \'        /oxgc)            { return e_q('', "'","'",$q_string); }
            elsif (/\G ($q_char) /oxgc)            { $q_string .= $1;                   }
        }
        croak "$__FILE__: Can't find string terminator anywhere before EOF";
    }

# ""
    elsif (/\G (\") /oxgc) {
        my $qq_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $qq_string .= $1;                    }
            elsif (/\G (\\\")    /oxgc)            { $qq_string .= $1;                    }
            elsif (/\G \"        /oxgc)            { return e_qq('', '"','"',$qq_string); }
            elsif (/\G ($q_char) /oxgc)            { $qq_string .= $1;                    }
        }
        croak "$__FILE__: Can't find string terminator anywhere before EOF";
    }

# ``
    elsif (/\G (\`) /oxgc) {
        my $qx_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $qx_string .= $1;                    }
            elsif (/\G (\\\`)    /oxgc)            { $qx_string .= $1;                    }
            elsif (/\G \`        /oxgc)            { return e_qq('', '`','`',$qx_string); }
            elsif (/\G ($q_char) /oxgc)            { $qx_string .= $1;                    }
        }
        croak "$__FILE__: Can't find string terminator anywhere before EOF";
    }

# //   --- not divide operator (num / num), not defined-or
    elsif (($slash eq 'm//') and /\G (\/) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)           /oxgc)     { $regexp .= $1;                       }
            elsif (/\G (\\\/)           /oxgc)     { $regexp .= $1;                       }
            elsif (/\G \/ ([cgimosxp]*) /oxgc)     { return e_qr('', '/','/',$regexp,$1); }
            elsif (/\G ($q_char)        /oxgc)     { $regexp .= $1;                       }
        }
        croak "$__FILE__: Search pattern not terminated";
    }

# ??   --- not conditional operator (condition ? then : else)
    elsif (($slash eq 'm//') and /\G (\?) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)           /oxgc)     { $regexp .= $1;                       }
            elsif (/\G (\\\?)           /oxgc)     { $regexp .= $1;                       }
            elsif (/\G \? ([cgimosxp]*) /oxgc)     { return e_qr('', '?','?',$regexp,$1); }
            elsif (/\G ($q_char)        /oxgc)     { $regexp .= $1;                       }
        }
        croak "$__FILE__: Search pattern not terminated";
    }

# << (bit shift)   --- not here document
    elsif (/\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; return $1;           }

# <<'HEREDOC'
    elsif (/\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<\HEREDOC

    # P.66 2.6.6. "Here" Documents
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    elsif (/\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<"HEREDOC"
    elsif (/\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<HEREDOC
    elsif (/\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<`HEREDOC`
    elsif (/\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<= <=> <= < operator
    elsif (/\G (<<=|<=>|<=|<) (?= \s* [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc) {
        return $1;
    }

# <FILEHANDLE>
    elsif (/\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>) /oxgc) {
        return $1;
    }

# <WILDCARD> --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G < ((?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^>\0\a\e\f\n\r\t])+?) > /oxgc) {
        return 'Einfomixv6als::glob("' . $1 . '")';
    }

# __DATA__
    elsif (/\G ^ ( __DATA__ \n .*) \z /oxmsgc) { return $1; }

# __END__
    elsif (/\G ^ ( __END__  \n .*) \z /oxmsgc) { return $1; }

# \cD Control-D

    # P.68 2.6.8. Other Literal Tokens
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    elsif (/\G   ( \cD         .*) \z /oxmsgc) { return $1; }

# \cZ Control-Z
    elsif (/\G   ( \cZ         .*) \z /oxmsgc) { return $1; }

    # any operator before div
    elsif (/\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; return $1; }

    # any operator before m//

    # //, //= (defined-or)
    #
    # P.164 Logical Operators
    # in Chapter 10: More Control Structures
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition
    # (and so on)

    # ~~
    #
    # P.221 The Smart Match Operator
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition
    # (and so on)

    elsif (/\G (

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | - |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; return $1; }

    # other any character
    elsif (/\G ($q_char) /oxgc) { $slash = 'div'; return $1; }

    # system error
    else {
        croak "$__FILE__: oops, this shouldn't happen!";
    }
}

# escape INFOMIX V6 ALS string
sub e_string {
    my($string) = @_;
    my $e_string = '';

    local $slash = 'm//';

    # P.1024 Appendix W.10 Multibyte Processing
    # of ISBN 1-56592-224-7 CJKV Information Processing
    # (and so on)

    my @char = $string =~ m/ \G (\\?(?:$q_char)) /oxmsg;

    # without { ... }
    if (not (grep(m/\A \{ \z/xms, @char) and grep(m/\A \} \z/xms, @char))) {
        if ($string !~ /<</oxms) {
            return $string;
        }
    }

E_STRING_LOOP:
    while ($string !~ /\G \z/oxgc) {

# bareword
        if ($string =~ /\G ( \{ \s* (?: tr|index|rindex|reverse) \s* \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $0 --> $0
        elsif ($string =~ /\G ( \$ 0 ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        elsif ($string =~ /\G ( \$ \{ \s* 0 \s* \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $$ --> $$
        elsif ($string =~ /\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $1, $2, $3 --> $2, $3, $4
        elsif ($string =~ /\G \$ ([1-9][0-9]*) /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . ')}';
            $slash = 'div';
        }
        elsif ($string =~ /\G \$ \{ \s* ([1-9][0-9]*) \s* \} /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . ')}';
            $slash = 'div';
        }

# $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ .+? \] ) /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            $slash = 'div';
        }

# $$foo{ ... } --> $ $foo->{ ... }
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ .+? \} ) /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            $slash = 'div';
        }

# $$foo
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . ')}';
            $slash = 'div';
        }

# ${ foo }
        elsif ($string =~ /\G \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} /oxmsgc) {
            $e_string .= '${' . $1 . '}';
            $slash = 'div';
        }

# ${ ... }
        elsif ($string =~ /\G \$ \s* \{ \s* ( $qq_brace ) \s* \} /oxmsgc) {
            $e_string .= '${Einfomixv6als::capture(' . $1 . ')}';
            $slash = 'div';
        }

# variable or function
        #                             $ @ % & *     $ #
        elsif ($string =~ /\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr|glob|lstat|opendir|stat|unlink|chdir) ) \b /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        #                           $ $ $ $ $ $ $ $ $ $ $ $ $ $ $
        #                           $ @ # \ ' " ` / ? ( ) [ ] < >
        elsif ($string =~ /\G ( \$[\$\@\#\\\'\"\`\/\?\(\)\[\]\<\>] ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# functions of package Einfomixv6als
        elsif ($string =~ m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $e_string .= $1;     $slash = 'm//'; }
        elsif ($string =~ m{\G \b chop \b                                    }oxgc) { $e_string .=   'Einfomixv6als::chop';          $slash = 'm//'; }
        elsif ($string =~ m{\G \b INFOMIXV6ALS::index \b                             }oxgc) { $e_string .=   'INFOMIXV6ALS::index';          $slash = 'm//'; }
        elsif ($string =~ m{\G \b index \b                                   }oxgc) { $e_string .=   'Einfomixv6als::index';         $slash = 'm//'; }
        elsif ($string =~ m{\G \b INFOMIXV6ALS::rindex \b                            }oxgc) { $e_string .=   'INFOMIXV6ALS::rindex';         $slash = 'm//'; }
        elsif ($string =~ m{\G \b rindex \b                                  }oxgc) { $e_string .=   'Einfomixv6als::rindex';        $slash = 'm//'; }
        elsif ($string =~ m{\G \b lc    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::lc';            $slash = 'm//'; }
        elsif ($string =~ m{\G \b uc    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::uc';            $slash = 'm//'; }

        elsif ($string =~ m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                                                                          \s* (\") ((?:$qq_char)+?)             (\") }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\#) ((?:$qq_char)+?)             (\#) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\() ((?:$qq_paren)+?)            (\)) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\{) ((?:$qq_brace)+?)            (\}) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\[) ((?:$qq_bracket)+?)          (\]) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\<) ((?:$qq_angle)+?)            (\>) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) qq \s* (\S) ((?:$qq_char)+?)             (\3) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                                                                          \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) }oxgc) { $e_string .= "Einfomixv6als::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+) (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) }oxgc)
                                                                                                                            { $e_string .= "Einfomixv6als::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ m{\G (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+) \( ((?:$qq_paren)*?) \) }oxgc)
                                                                                                                            { $e_string .= "Einfomixv6als::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) (?= [a-z]+) }oxgc)                                   { $e_string .= "Einfomixv6als::filetest qw($1),";    $slash = 'm//'; }
        elsif ($string =~ m{\G ((?:-[rwxoRWXOezfdlpSbctugkTB]\s+){2,}) (\w+) }oxgc)                                         { $e_string .= "Einfomixv6als::filetest(qw($1),$2)"; $slash = 'm//'; }

        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+    \s* (\") ((?:$qq_char)+?)             (\") }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) }oxgc)    { $e_string .= "Einfomixv6als::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) }oxgc)
                                                                                                                            { $e_string .= "Einfomixv6als::$1($2)"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s* \( ((?:$qq_paren)*?) \) }oxgc)                          { $e_string .= "Einfomixv6als::$1($2)"; $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) (?= \s+ [a-z]+) }oxgc)                                      { $e_string .= "Einfomixv6als::$1";     $slash = 'm//'; }
        elsif ($string =~ m{\G -([rwxoRWXOezsfdlpSbctugkTBMAC]) \s+ (\w+) }oxgc)                                            { $e_string .= "Einfomixv6als::$1($2)"; $slash = 'm//'; }
        elsif ($string =~ m{\G \b lstat (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::lstat';             $slash = 'm//'; }
        elsif ($string =~ m{\G \b stat  (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::stat';              $slash = 'm//'; }
        elsif ($string =~ m{\G \b chr   (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::chr';               $slash = 'm//'; }
        elsif ($string =~ m{\G \b ord   (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   $function_ord;              $slash = 'div'; }
        elsif ($string =~ m{\G \b glob  (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) }oxgc) { $e_string .=   'Einfomixv6als::glob';              $slash = 'm//'; }
        elsif ($string =~ m{\G \b lc \b                                      }oxgc) { $e_string .=   'Einfomixv6als::lc_';               $slash = 'm//'; }
        elsif ($string =~ m{\G \b uc \b                                      }oxgc) { $e_string .=   'Einfomixv6als::uc_';               $slash = 'm//'; }

        elsif ($string =~ m{\G    (-[rwxoRWXOezfdlpSbctugkTB](?:\s+-[rwxoRWXOezfdlpSbctugkTB])+)
                                                                   \b        }oxgc) { $e_string .=   "Einfomixv6als::filetest_(qw($1))"; $slash = 'm//'; }
        elsif ($string =~ m{\G    -([rwxoRWXOezsfdlpSbctugkTBMAC]) \b        }oxgc) { $e_string .=   "Einfomixv6als::${1}_";             $slash = 'm//'; }
        elsif ($string =~ m{\G \b lstat \b                                   }oxgc) { $e_string .=   'Einfomixv6als::lstat_';            $slash = 'm//'; }
        elsif ($string =~ m{\G \b stat \b                                    }oxgc) { $e_string .=   'Einfomixv6als::stat_';             $slash = 'm//'; }
        elsif ($string =~ m{\G \b chr \b                                     }oxgc) { $e_string .=   'Einfomixv6als::chr_';              $slash = 'm//'; }
        elsif ($string =~ m{\G \b ord \b                                     }oxgc) { $e_string .=   $function_ord_;             $slash = 'div'; }
        elsif ($string =~ m{\G \b glob \b                                    }oxgc) { $e_string .=   'Einfomixv6als::glob_';             $slash = 'm//'; }
        elsif ($string =~ m{\G \b reverse \b                                 }oxgc) { $e_string .=   $function_reverse;          $slash = 'm//'; }
        elsif ($string =~ m{\G \b opendir (\s* \( \s*) (?=[A-Za-z_])         }oxgc) { $e_string .=   "Einfomixv6als::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ m{\G \b opendir (\s+)        (?=[A-Za-z_])         }oxgc) { $e_string .=   "Einfomixv6als::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ m{\G \b unlink \b                                  }oxgc) { $e_string .=   'Einfomixv6als::unlink';            $slash = 'm//'; }
        elsif ($string =~ m{\G \b chdir \b                                   }oxgc) { $e_string .=   'Einfomixv6als::chdir';             $slash = 'm//'; }

# split
        elsif ($string =~ m{\G \b (split) \b (?! \s* => ) }oxgc) {
            $slash = 'm//';

            my $e_string = 'Einfomixv6als::split';

            while ($string =~ /\G ( \s+ | \( | \#.* ) /oxgc) {
                $e_string .= $1;
            }

# end of split
            if    ($string =~ /\G (?= [,;\)\}\]] )          /oxgc) { return $e_string;                               }

# split scalar value
            elsif ($string =~ /\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { $e_string .= e_string($1);  next E_STRING_LOOP; }

# split literal space
            elsif ($string =~ /\G \b qq       (\#) [ ] (\#) /oxgc) { $e_string .= qq  {qq$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\() [ ] (\)) /oxgc) { $e_string .= qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\{) [ ] (\}) /oxgc) { $e_string .= qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\[) [ ] (\]) /oxgc) { $e_string .= qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\<) [ ] (\>) /oxgc) { $e_string .= qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\S) [ ] (\2) /oxgc) { $e_string .= qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q        (\#) [ ] (\#) /oxgc) { $e_string .= qq   {q$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\() [ ] (\)) /oxgc) { $e_string .= qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\{) [ ] (\}) /oxgc) { $e_string .= qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\[) [ ] (\]) /oxgc) { $e_string .= qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\<) [ ] (\>) /oxgc) { $e_string .= qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\S) [ ] (\2) /oxgc) { $e_string .= qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G                ' [ ] '    /oxgc) { $e_string .= qq     {' '};  next E_STRING_LOOP; }
            elsif ($string =~ /\G                " [ ] "    /oxgc) { $e_string .= qq     {" "};  next E_STRING_LOOP; }

# split qq//
            elsif ($string =~ /\G \b (qq) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                             /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split('qr','{','}',$2,''); next E_STRING_LOOP; } # qq | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq * * --> qr * *
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }
            }

# split qr//
            elsif ($string =~ /\G \b (qr) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([imosxp]*) /oxgc)                        { $e_string .= e_split  ('qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # qr# #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                         /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([imosxp]*) /oxgc) { $e_string .= e_split_q('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr','{','}',$2,$4); next E_STRING_LOOP; } # qr | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr * *
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }
            }

# split q//
            elsif ($string =~ /\G \b (q) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q ( ) --> qr ( )
                        elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q { } --> qr { }
                        elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q('qr','{','}',$2,''); next E_STRING_LOOP; } # q | | --> qr { }
                        elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q('qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q * * --> qr * *
                    }
                    croak "$__FILE__: Can't find string terminator anywhere before EOF";
                }
            }

# split m//
            elsif ($string =~ /\G \b (m) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxp]*) /oxgc)                        { $e_string .= e_split  ('qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # m# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                           /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m < > --> qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxp]*) /oxgc) { $e_string .= e_split_q('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ' ' --> qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr','{','}',$2,$4); next E_STRING_LOOP; } # m | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxp]*) /oxgc) { $e_string .= e_split  ('qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m * * --> qr * *
                    }
                    croak "$__FILE__: Search pattern not terminated";
                }
            }

# split ''
            elsif ($string =~ /\G (\') /oxgc) {
                my $q_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G (\\\')    /oxgc) { $q_string .= $1; } # splitqr'' --> split qr''
                    elsif ($string =~ /\G \'        /oxgc)                      { $e_string .= e_split_q(q{ qr},"'","'",$q_string,''); next E_STRING_LOOP; } # ' ' --> qr ' '
                    elsif ($string =~ /\G ($q_char) /oxgc) { $q_string .= $1; }
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }

# split ""
            elsif ($string =~ /\G (\") /oxgc) {
                my $qq_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G (\\\")    /oxgc) { $qq_string .= $1; } # splitqr"" --> split qr""
                    elsif ($string =~ /\G \"        /oxgc)                       { $e_string .= e_split(q{ qr},'"','"',$qq_string,''); next E_STRING_LOOP; } # " " --> qr " "
                    elsif ($string =~ /\G ($q_char) /oxgc) { $qq_string .= $1; }
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }

# split //
            elsif ($string =~ /\G (\/) /oxgc) {
                my $regexp = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)           /oxgc) { $regexp .= $1; }
                    elsif ($string =~ /\G (\\\/)           /oxgc) { $regexp .= $1; } # splitqr// --> split qr//
                    elsif ($string =~ /\G \/ ([cgimosxp]*) /oxgc)                    { $e_string .= e_split(q{ qr}, '/','/',$regexp,$1); next E_STRING_LOOP; } # / / --> qr / /
                    elsif ($string =~ /\G ($q_char)        /oxgc) { $regexp .= $1; }
                }
                croak "$__FILE__: Search pattern not terminated";
            }
        }

# qq//
        elsif ($string =~ /\G \b (qq) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qq# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq < >
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# qx//
        elsif ($string =~ /\G \b (qx) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx < >
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . e_q ($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ' '
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# q//
        elsif ($string =~ /\G \b (q) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { # q# #
                $e_string .= e_q($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q ( )
                    elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q { }
                    elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q [ ]
                    elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q < >
                    elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q * *
                }
                croak "$__FILE__: Can't find string terminator anywhere before EOF";
            }
        }

# ''
        elsif ($string =~ /\G (?<![\w\$\@\%\&\*]) (\') ((?:\\\'|\\\\|$q_char)*?) (\') /oxgc) { $e_string .= e_q('',$1,$3,$2);  }

# ""
        elsif ($string =~ /\G (\") ((?:$qq_char)*?) (\") /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# ``
        elsif ($string =~ /\G (\`) ((?:$qq_char)*?) (\`) /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# <<= <=> <= < operator
        elsif ($string =~ /\G (<<=|<=>|<=|<) (?= \s* [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc)   { $e_string .= $1;                }

# <FILEHANDLE>
        elsif ($string =~ /\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>) /oxgc)                         { $e_string .= $1;                }

# <WILDCARD>   --- glob
        elsif ($string =~ /\G < ((?:$q_char)+?) > /oxgc) {
            $e_string .= 'Einfomixv6als::glob("' . $1 . '")';
        }

# << (bit shift)   --- not here document
        elsif ($string =~ /\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; $e_string .= $1; }

# <<'HEREDOC'
        elsif ($string =~ /\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<\HEREDOC
        elsif ($string =~ /\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<"HEREDOC"
        elsif ($string =~ /\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<HEREDOC
        elsif ($string =~ /\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<`HEREDOC`
        elsif ($string =~ /\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                croak "$__FILE__: Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

        # any operator before div
        elsif ($string =~ /\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; $e_string .= $1; }

        # any operator before m//
        elsif ($string =~ /\G (

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | - |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; $e_string .= $1; }

        # other any character
        elsif ($string =~ /\G ($q_char) /oxgc) { $e_string .= $1; }

        # system error
        else {
            croak "$__FILE__: oops, this shouldn't happen!";
        }
    }

    return $e_string;
}

#
# classic character class ( . \D \S \W \d \s \w \H \V \h \v )
#
sub classic_character_class {
    my($char,$modifier) = @_;

    return {
        '.'  => ($modifier =~ /s/) ?
                '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])' :
                '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x0A])',
        '\D' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9])',
        '\S' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])',
        '\W' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9A-Z_a-z])',
        '\d' => '[0-9]',
                 # \t  \n  \f  \r space
        '\s' => '[\x09\x0A\x0C\x0D\x20]',
        '\w' => '[0-9A-Z_a-z]',

        # \h \v \H \V
        #
        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        '\H' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x20])',
        '\V' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x0C\x0A\x0D])',
        '\h' => '[\x09\x20]',
        '\v' => '[\x0C\x0A\x0D]',

    }->{$char};
}

#
# escape transliteration (tr/// or y///)
#
sub e_tr {
    my($variable,$charclass,$e,$charclass2,$modifier) = @_;
    my $e_tr = '';
    $modifier ||= '';

    $slash = 'div';

    # quote character class 1
    $charclass  = q_tr($charclass);

    # quote character class 2
    $charclass2 = q_tr($charclass2);

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        if ($variable eq '') {
            $e_tr = qq{tr$charclass$e$charclass2$modifier};
        }
        else {
            $e_tr = qq{$variable${bind_operator}tr$charclass$e$charclass2$modifier};
        }
    }
    else {
        if ($variable eq '') {
            $e_tr = qq{Einfomixv6als::tr(\$_,      ' =~ ',          $charclass,$e$charclass2,'$modifier')};
        }
        else {
            $e_tr = qq{Einfomixv6als::tr($variable,'$bind_operator',$charclass,$e$charclass2,'$modifier')};
        }
    }

    # clear tr/// variable
    $tr_variable = '';
    $bind_operator = '';

    return $e_tr;
}

#
# quote for escape transliteration (tr/// or y///)
#
sub q_tr {
    my($charclass) = @_;

    # quote character class
    if ($charclass !~ m/'/oxms) {
        return e_q('',  "'", "'", $charclass); # --> q' '
    }
    elsif ($charclass !~ m{/}oxms) {
        return e_q('q',  '/', '/', $charclass); # --> q/ /
    }
    elsif ($charclass !~ m/\#/oxms) {
        return e_q('q',  '#', '#', $charclass); # --> q# #
    }
    elsif ($charclass !~ m/[\<\>]/oxms) {
        return e_q('q', '<', '>', $charclass); # --> q< >
    }
    elsif ($charclass !~ m/[\(\)]/oxms) {
        return e_q('q', '(', ')', $charclass); # --> q( )
    }
    elsif ($charclass !~ m/[\{\}]/oxms) {
        return e_q('q', '{', '}', $charclass); # --> q{ }
    }
    else {
        for my $char (qw( ! " $ % & * + . : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if ($charclass !~ m/\Q$char\E/xms) {
                return e_q('q', $char, $char, $charclass);
            }
        }
    }

    return e_q('q', '{', '}', $charclass);
}

#
# escape q string (q//, '')
#
sub e_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ m/ \G ($q_char) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape last octet of multiple octet
        if ($char[$i] =~ m/\A ([\x80-\xFF].*) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (($char[$i] =~ m/\A ([\x80-\xFF].*) (\\) \z/xms) and defined($char[$i+1]) and ($char[$i+1] eq '\\')) {
            $char[$i] = $1 . '\\' . $2;
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ m/\A ([\x80-\xFF].*) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char,   $end_delimiter;
    return join '', $ope, $delimiter, $string, $end_delimiter;
}

#
# escape qq string (qq//, "", qx//, ``)
#
sub e_qq {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $metachar = qr/[\@\\\|]/oxms; # '|' is for qx//, ``, open() and system()

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m{ \G (
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \\?(?:$q_char)
    )}oxmsg;

    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {

            # "STRING @{[ LIST EXPR ]} MORE STRING"
            #
            # 1.15. Interpolating Functions and Expressions Within Strings
            # in Chapter 1. Strings
            # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
            # (and so on)

            $char[$i] = '@{[Einfomixv6als::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Einfomixv6als::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ m/\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* 0 \s* \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ m/\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4
        elsif ($char[$i] =~ m/\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
        }

        # $$foo
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* \} \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    return     join '', $ope, $delimiter, @char,                               $end_delimiter;
}

#
# escape qw string (qw//)
#
sub e_qw {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    # choice again delimiter
    my %octet = map {$_ => 1} ($string =~ m/\G ([\x00-\xFF]) /oxmsg);
    if (not $octet{$end_delimiter}) {
        return join '', $ope, $delimiter, $string, $end_delimiter;
    }
    elsif (not $octet{')'}) {
        return join '', $ope, '(',        $string, ')';
    }
    elsif (not $octet{'}'}) {
        return join '', $ope, '{',        $string, '}';
    }
    elsif (not $octet{']'}) {
        return join '', $ope, '[',        $string, ']';
    }
    elsif (not $octet{'>'}) {
        return join '', $ope, '<',        $string, '>';
    }
    else {
        for my $char (qw( ! " $ % & * + - . / : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if (not $octet{$char}) {
                return join '', $ope,      $char, $string, $char;
            }
        }
    }

    # qw/AAA BBB C'CC/ --> ('AAA', 'BBB', 'C\'CC')
    my @string = CORE::split(/\s+/, $string);
    for my $string (@string) {
        my @octet = $string =~ m/\G ([\x00-\xFF]) /oxmsg;
        for my $octet (@octet) {
            if ($octet =~ m/\A (['\\]) \z/oxms) {
                $octet = '\\' . $1;
            }
        }
        $string = join '', @octet;
    }
    return join '', '(', (join ', ', map { "'$_'" } @string), ')';
}

#
# escape here document (<<"HEREDOC", <<HEREDOC, <<`HEREDOC`)
#
sub e_heredoc {
    my($string) = @_;

    $slash = 'm//';

    my $metachar = qr/[\@\\|]/oxms; # '|' is for <<`HEREDOC`

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m{ \G (
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \\?(?:$q_char)
    )}oxmsg;

    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape character
        elsif ($char[$i] =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Einfomixv6als::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Einfomixv6als::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ m/\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* 0 \s* \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ m/\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4
        elsif ($char[$i] =~ m/\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
        }

        # $$foo
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* \} \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', @char, '>]}' x ($left_e - $right_e);
    }
    return     join '', @char;
}

#
# escape regexp (m//, qr//)
#
sub e_qr {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}             |
        \\x [0-9A-Fa-f]{1,2}       |
        \\c [\x40-\x5F]            |
        \\  (?:$q_char)            |
        [\$\@] $qq_variable        |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \[\:\^ [a-z]+ \:\]         |
        \[\:   [a-z]+ \:\]         |
        \[\^                       |
        \(\?                       |
            (?:$q_char)
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple octet
        elsif ($char[$i] =~ m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Einfomixv6als::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Einfomixv6als::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ m/\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ m/\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4
        elsif ($char[$i] =~ m/\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ m/\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $1 . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, "$your_gap(?:", @char, '>]}' x ($left_e - $right_e), ')(?{Einfomixv6als::m_matched})', $end_delimiter, $modifier;
    }
    return     join '', $ope, $delimiter, "$your_gap(?:", @char,                               ')(?{Einfomixv6als::m_matched})', $end_delimiter, $modifier;
}

#
# escape regexp (m'', qr'')
#
sub e_qr_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        \\?    (?:$q_char)
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, "$your_gap(?:", @char, ')(?{Einfomixv6als::m_matched})', $end_delimiter, $modifier;
}

#
# escape regexp (s/here//)
#
sub e_s1 {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\g \s* \{ \s* - \s* [1-9][0-9]* \s* \} |
        \\g \s* \{ \s*       [1-9][0-9]* \s* \} |
        \\g \s*              [1-9][0-9]*        |
        \\                   [1-9][0-9]*        |
        \\  [0-7]{2,3}                          |
        \\x [0-9A-Fa-f]{1,2}                    |
        \\c [\x40-\x5F]                         |
        \\  (?:$q_char)                         |
        [\$\@] $qq_variable                     |
        \$ \s* \d+                              |
        \$ \s* \{ \s* \d+ \s* \}                |
        \$ \$ (?![\w\{])                        |
        \$ \s* \$ \s* $qq_variable              |
        \[\:\^ [a-z]+ \:\]                      |
        \[\:   [a-z]+ \:\]                      |
        \[\^                                    |
        \(\?                                    |
            (?:$q_char)
    )}oxmsg;

    # count '('
    my $parens = grep { $_ eq '(' } @char;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple octet
        elsif ($char[$i] =~ m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Einfomixv6als::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Einfomixv6als::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # \0 --> \0
        elsif ($char[$i] =~ m/\A \\ \s* 0 \z/oxms) {
        }

        # \g{N}, \g{-N}
        #
        # P.108 Using Simple Patterns
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # \g{-1}, \g{-2}, \g{-3} --> \g{-1}, \g{-2}, \g{-3}
        elsif ($char[$i] =~ m/\A \\g \s* \{ \s* - \s* ([1-9][0-9]*) \s* \} \z/oxms) {
        }

        # \g{1}, \g{2}, \g{3} --> \g{2}, \g{3}, \g{4}
        elsif ($char[$i] =~ m/\A \\g \s* \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g{' . ($1 + 1) . '}';
            }
        }

        # \g1, \g2, \g3 --> \g2, \g3, \g4
        elsif ($char[$i] =~ m/\A \\g \s* ([1-9][0-9]*) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g' . ($1 + 1);
            }
        }

        # \1, \2, \3 --> \2, \3, \4
        elsif ($char[$i] =~ m/\A \\ \s* ([1-9][0-9]*) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\' . ($1 + 1);
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ m/\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ m/\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4
        elsif ($char[$i] =~ m/\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ m/\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $1 . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, "($your_gap)(?:", @char, '>]}' x ($left_e - $right_e), ')(?{Einfomixv6als::s_matched})', $end_delimiter, $modifier;
    }
    return     join '', $ope, $delimiter, "($your_gap)(?:", @char,                               ')(?{Einfomixv6als::s_matched})', $end_delimiter, $modifier;
}

#
# escape regexp (s'here'')
#
sub e_s1_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        \\?    (?:$q_char)
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, "($your_gap)(?:", @char, ')(?{Einfomixv6als::s_matched})', $end_delimiter, $modifier;
}

#
# escape regexp (s/here/and here/modifier)
#
sub e_sub {
    my($variable,$delimiter1,$pattern,$end_delimiter1,$delimiter2,$replacement,$end_delimiter2,$modifier) = @_;
    $modifier ||= '';

    if ($variable eq '') {
        $variable      = '$_';
        $bind_operator = ' =~ ';
    }

    $slash = 'div';

    # P.128 Start of match (or end of previous match): \G
    # in Chapter 3: Overview of Regular Expression Features and Flavors
    # P.312 Iterative Matching: Scalar Context, with /g
    # in Chapter 7: Perl
    # of ISBN 0-596-00272-6 Mastering Regular Expressions, Second edition 

    my $e_modifier = $modifier =~ tr/e//d;

    my $my = '';
    if ($variable =~ s/\A \( \s* ( (?: local \b | my \b | our \b | state \b )? .+ ) \) \z/$1/oxms) {
        $my = $variable;
        $variable =~ s/ (?: local \b | my \b | our \b | state \b ) \s* //oxms;
        $variable =~ s/ = .+ \z//oxms;
    }

    (my $variable_basename = $variable) =~ s/ [\[\{].* \z//oxms;
    $variable_basename =~ s/ \s+ \z//oxms;

    # quote replacement string
    my $q_replacement = '';
    if ($delimiter2 eq "'") {
        $q_replacement = e_q ('',   "'",         "'",             $replacement);
    }
    else {
        $q_replacement = e_qq('qq', $delimiter2, $end_delimiter2, $replacement);
    }

    # escape replacement string
    my $e_replacement = '';
    if ($q_replacement !~ m/'/oxms) {
        $e_replacement = e_q('',  "'", "'", $q_replacement); # --> q' '
    }
    elsif ($q_replacement !~ m{/}oxms) {
        $e_replacement = e_q('q',  '/', '/', $q_replacement); # --> q/ /
    }
    elsif ($q_replacement !~ m/\#/oxms) {
        $e_replacement = e_q('q',  '#', '#', $q_replacement); # --> q# #
    }
    elsif ($q_replacement !~ m/[\<\>]/oxms) {
        $e_replacement = e_q('q', '<', '>', $q_replacement); # --> q< >
    }
    elsif ($q_replacement !~ m/[\(\)]/oxms) {
        $e_replacement = e_q('q', '(', ')', $q_replacement); # --> q( )
    }
    elsif ($q_replacement !~ m/[\{\}]/oxms) {
        $e_replacement = e_q('q', '{', '}', $q_replacement); # --> q{ }
    }
    else {
        for my $char (qw( ! " $ % & * + . : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if ($q_replacement !~ m/\Q$char\E/xms) {
                $e_replacement = e_q('q', $char, $char, $q_replacement);
                last;
            }
        }
    }

    # s///g
    my $sub;
    if ($modifier =~ m/g/oxms) {
        $sub = sprintf(
            #         1          2              3 4 5      6         7   8 9   10      11           12          13      14     15          16       17    18      19
            q<eval{my %s_n=0; my %s_a=''; while(%s%s%s){my %s_r=eval %s; %s%s="%s_a${1}%s_r$'"; pos(%s)=length "%s_a${1}%s_r"; %s_a=substr(%s,0,pos(%s)); %s_n++} %s_n}>,

                $variable_basename,                                                       #  1
                $variable_basename,                                                       #  2
            $variable,                                                                    #  3
            $bind_operator,                                                               #  4
            ($delimiter1 eq "'") ?                                                        #  5
            e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
            e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $variable_basename,                                                       #  6
            $e_replacement,                                                               #  7
            sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, #  8
            $variable,                                                                    #  9
                $variable_basename,                                                       # 10
                $variable_basename,                                                       # 11
            $variable,                                                                    # 12
                $variable_basename,                                                       # 13
                $variable_basename,                                                       # 14
                $variable_basename,                                                       # 15
            $variable,                                                                    # 16
            $variable,                                                                    # 17
                $variable_basename,                                                       # 18
                $variable_basename,                                                       # 19
        );
    }

    # s///
    else {
        $sub = sprintf(
            #  1 2 3             4         5   6 7       8
            q<(%s%s%s) ? eval{my %s_r=eval %s; %s%s="${1}%s_r$'"; 1 } : ''>,

            $variable,                                                                    # 1
            $bind_operator,                                                               # 2
            ($delimiter1 eq "'") ?                                                        # 3
            e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              # :
            e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               # :
                $variable_basename,                                                       # 4
            $e_replacement,                                                               # 5
            sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, # 6
            $variable,                                                                    # 7
                $variable_basename,                                                       # 8
        );
    }

    # (my $foo = $bar) =~ s///   -->   (my $foo = $bar, eval { ... })[1]
    if ($my ne '') {
        $sub = "($my, $sub)[1]";
    }

    # clear s/// variable
    $sub_variable = '';
    $bind_operator = '';

    return $sub;
}

#
# escape regexp of split qr//
#
sub e_split {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}             |
        \\x [0-9A-Fa-f]{1,2}       |
        \\c [\x40-\x5F]            |
        \\  (?:$q_char)            |
        [\$\@] $qq_variable        |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \[\:\^ [a-z]+ \:\]         |
        \[\:   [a-z]+ \:\]         |
        \[\^                       |
        \(\?                       |
            (?:$q_char)
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple octet
        elsif ($char[$i] =~ m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(m/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ m/\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # P.794 29.2.161. split
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.
        # said "The //m modifier is assumed when you split on the pattern /^/",
        # but perl5.008 is not so. Therefore, this software adds //m.
        # (and so on)

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ m/m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Einfomixv6als::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Einfomixv6als::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ m/\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ m/\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4
        elsif ($char[$i] =~ m/\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ m/\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . '->' . $2 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ m/\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ m/\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $1 . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ m/\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = '${Einfomixv6als::capture(' . $1 . ')}';
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Einfomixv6als::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
    }
    return     join '', $ope, $delimiter, @char,                               $end_delimiter, $modifier;
}

#
# escape regexp of split qr''
#
sub e_split_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        \\?    (?:$q_char)
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple octet
        elsif ($char[$i] =~ m/\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    croak "$__FILE__: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Einfomixv6als::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = classic_character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ m/m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '[' . CORE::uc($1) . CORE::lc($1) . ']';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, @char, $end_delimiter, $modifier;
}

#
# escape require
#
sub e_require {
    my($module) = @_;

    my $expr = $module;
    $expr =~ s#::#/#g;
    $expr .= '.pm' if $expr !~ m/ \.pm \z/oxmsi;

    return qq<Einfomixv6als::require '$expr';>;
}

#
# escape use without import
#
sub e_use_noimport {
    my($module) = @_;

    my $expr = $module;
    $expr =~ s#::#/#g;
    $expr .= '.pm' if $expr !~ m/ \.pm \z/oxmsi;

    my $fh = Symbol::gensym();
    for my $prefix (@INC) {
        my $realfilename = "$prefix/$expr";

        if (sysopen($fh, $realfilename, O_RDONLY)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or croak "Can't close file: $realfilename";

            if ($script =~ m/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $/oxms) {
                return qq<BEGIN { Einfomixv6als::require '$expr'; }>;
            }
            last;
        }
    }

    return qq<use $module ();>;
}

#
# escape use with import no parameter
#
sub e_use_noparam {
    my($module) = @_;

    my $expr = $module;
    $expr =~ s#::#/#g;
    $expr .= '.pm' if $expr !~ m/ \.pm \z/oxmsi;

    my $fh = Symbol::gensym();
    for my $prefix (@INC) {
        my $realfilename = "$prefix/$expr";

        if (sysopen($fh, $realfilename, O_RDONLY)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or croak "Can't close file: $realfilename";

            if ($script =~ m/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $/oxms) {

                # P.326 UNIVERSAL: The Ultimate Ancestor Class
                # in Chapter 12: Objects
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.
                # (and so on)

                return qq[BEGIN { Einfomixv6als::require '$expr'; $module->import() if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module;>;
}

#
# escape use with import parameters
#
sub e_use {
    my($module,$list) = @_;

    my $expr = $module;
    $expr =~ s#::#/#g;
    $expr .= '.pm' if $expr !~ m/ \.pm \z/oxmsi;

    my $fh = Symbol::gensym();
    for my $prefix (@INC) {
        my $realfilename = "$prefix/$expr";

        if (sysopen($fh, $realfilename, O_RDONLY)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or croak "Can't close file: $realfilename";

            if ($script =~ m/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $/oxms) {
                return qq[BEGIN { Einfomixv6als::require '$expr'; $module->import($list) if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module $list;>;
}

1;

__END__

=pod

=head1 NAME

INFOMIXV6ALS - "Yet Another JPerl" Source code filter to escape INFOMIX V6 ALS

=head1 SYNOPSIS

  use INFOMIXV6ALS;
  use INFOMIXV6ALS version;         --- require version
  use INFOMIXV6ALS qw(ord reverse); --- demand enhanced feature of ord and reverse
  use INFOMIXV6ALS version qw(ord reverse);

  functions:
    INFOMIXV6ALS::ord(...);
    INFOMIXV6ALS::reverse(...);
    INFOMIXV6ALS::length(...);
    INFOMIXV6ALS::substr(...);
    INFOMIXV6ALS::index(...);
    INFOMIXV6ALS::rindex(...);

  # "no INFOMIXV6ALS;" not supported

  or

  C:\>perl INFOMIXV6ALS.pm INFOMIX V6 ALS_script.pl > Escaped_script.pl.e

  INFOMIX V6 ALS_script.pl  --- script written in INFOMIX V6 ALS
  Escaped_script.pl.e --- escaped script

=head1 ABSTRACT

Let's start with a bit of history: jperl 4.019+1.3 introduced INFOMIX V6 ALS support.
You could apply chop() and regexps even to complex CJK characters.

Since Perl5.8, Encode module is supported for multilingual processing, and it is
said that jperl became unnecessary. But is it really so?

In this country, INFOMIX V6 ALS is widely used on mainframe I/O, the personal computer,
and the cellular phone. This software treats INFOMIX V6 ALS directly. Therefor there is
not UTF8 flag.

Shall we escape from the encode problem?

=head1 Yet Another Future Of

JPerl is very useful software. -- Oops, note, this "JPerl" means Japanized or
Japanese Perl, so is unrelated to Java and JVM. Therefore, I named this software
better, fitter INFOMIXV6ALS.

Now, the last version of JPerl is 5.005_04 and is not maintained now.

Japanization modifier Hirofumi Watanabe said,

  "Because Watanabe am tired I give over maintaing JPerl."

at Slide #15: "The future of JPerl" of

L<ftp://ftp.oreilly.co.jp/pcjp98/watanabe/jperlconf.ppt>

in The Perl Confernce Japan 1998.

When I heard it, I thought that someone excluding me would maintain JPerl.
And I slept every night hanging a sock. Night and day, I kept having hope.
After 10 years, I noticed that white beard exists in the sock :-)

This software is a source code filter to escape Perl script encoded by INFOMIX V6 ALS
given from STDIN or command line parameter. The character code is never converted
by escaping the script. Neither the value of the character nor the length of the
character string change even if it escapes.

What's this software good for ...

=over 2

=item * Possible to handle raw INFOMIX V6 ALS values

=item * Possible to re-use past data, past code and how to

=item * No UTF8 flag

=item * But Perl5 compatible

=item * No C programming (for maintain JPerl)

=back

Let's make yet another future by JPerl's future.

=head1 BASIC IDEA

I discovered this mail again recently.

[Tokyo.pm] jus Benkyoukai

http://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html

save as: SJIS.pm

  package SJIS;
  use Filter::Util::Call;
  sub multibyte_filter {
      my $status;
      if (($status = filter_read()) > 0 ) {
          s/([\x81-\x9f\xe0-\xef])([\x40-\x7e\x80-\xfc])/
              sprintf("\\x%02x\\x%02x",ord($1),ord($2))
          /eg;
      }
      $status;
  }
  sub import {
      filter_add(\&multibyte_filter);
  }
  1;

I am glad that I could confirm my idea is not so wrong.

=head1 SOFTWARE COMPOSITION

   INFOMIXV6ALS.pm          --- source code filter to escape INFOMIX V6 ALS
   Einfomixv6als.pm         --- run-time routines for INFOMIXV6ALS.pm
   perl58.bat       --- find and run perl5.8  without %PATH% settings
   perl510.bat      --- find and run perl5.10 without %PATH% settings
   perl512.bat      --- find and run perl5.12 without %PATH% settings

=head1 CHARACTER CLASSES

The character classes are redefined as follows to backward compatibility.

  ---------------------------------------------------------------------------
  escape        class
  ---------------------------------------------------------------------------
  \d            [0-9]
  \s            [\x09\x0A\x0C\x0D\x20]
  \w            [0-9A-Z_a-z]
  \D            (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9])
  \S            (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])
  \W            (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9A-Z_a-z])
  \h            [\x09\x20]
  \v            [\x0C\x0A\x0D]
  \H            (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x20])
  \V            (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x0C\x0A\x0D])
  ---------------------------------------------------------------------------

=head1 JPerl COMPATIBLE FUNCTIONS

The following functions function as much as JPerl.
A part of function in the script is written and changes by this software.

=over 2

=item * handle multiple octet string in single quote

=item * handle multiple octet string in double quote

=item * handle multiple octet regexp in single quote

=item * handle multiple octet regexp in double quote

=item * chop --> Einfomixv6als::chop

=item * split --> Einfomixv6als::split

=item * length

=item * substr

=item * index --> Einfomixv6als::index

=item * rindex --> Einfomixv6als::rindex

=item * pos

=item * lc --> Einfomixv6als::lc or Einfomixv6als::lc_

=item * uc --> Einfomixv6als::uc or Einfomixv6als::uc_

=item * ord (when no import)

=item * reverse (when no import)

=item * tr/// or y/// --> Einfomixv6als::tr

/b and /B modifier can also be used.

=item * chdir --> Einfomixv6als::chdir

support chr(0x5C) ended path on only perl5.005 if MSWin32.

=item * do --> Einfomixv6als::do

=item * require --> Einfomixv6als::require

=item * use Perl::Module @list; --> BEGIN { Einfomixv6als::require 'Perl/Module.pm'; Perl::Module->import(@list) if Perl::Module->can('import'); }

=item * use Perl::Module (); --> BEGIN { Einfomixv6als::require 'Perl/Module.pm'; }

=back

=head1 JPerl UPPER COMPATIBLE FUNCTIONS

The following functions are enhanced more than JPerl.

=over 2

=item * chr --> Einfomixv6als::chr or Einfomixv6als::chr_

multiple octet code can also be handled.

=item * -X --> Einfomixv6als::X or Einfomixv6als::X_

support chr(0x5C) ended path on MSWin32.

=item * glob --> Einfomixv6als::glob or Einfomixv6als::glob_

  @glob = Einfomixv6als::glob($string);
  @glob = Einfomixv6als::glob_;

Einfomixv6als::glob provides a portable enhanced DOS-like globbing for the INFOMIXV6ALS software.
Einfomixv6als::glob lets you use wildcards in directory paths, is case-insensitive, and
accepts both backslashes and forward slashes (although you may have to double the
backslashes).

From a Perl script:

use INFOMIXV6ALS;
@perlfiles = glob  "..\pe?l/*.p?";
print <..\pe?l/*.p?>;

a tilde ("~") expands to the current user's home directory.
support chr(0x5C) ended path on MSWin32.

=item * lstat --> Einfomixv6als::lstat or Einfomixv6als::lstat_

support chr(0x5C) ended path on MSWin32.

=item * opendir --> Einfomixv6als::opendir

support chr(0x5C) ended path on MSWin32.

=item * stat --> Einfomixv6als::stat or Einfomixv6als::stat_

support chr(0x5C) ended path on MSWin32.

=item * unlink --> Einfomixv6als::unlink

support chr(0x5C) ended path on MSWin32.

=item * ord --> INFOMIXV6ALS::ord or INFOMIXV6ALS::ord_

multiple octet code can also be handled when "use INFOMIXV6ALS qw(ord);".
It means not compatible with JPerl.

=item * reverse --> INFOMIXV6ALS::reverse

multiple octet code can also be handled in scalar context when "use INFOMIXV6ALS qw(reverse);".
It means not compatible with JPerl.

=back

=head1 CHARACTER ORIENTED FUNCTIONS

=item Order of Character

  $ord = INFOMIXV6ALS::ord($string);

  This function returns the numeric value (ASCII or INFOMIX V6 ALS) of the first character
  of $string. The return value is always unsigned.

=item Reverse list or string

  @reverse = INFOMIXV6ALS::reverse(@list);
  $reverse = INFOMIXV6ALS::reverse(@list);

  In list context, this function returns a list value consisting of the elements of
  @list in the opposite order. The function can be used to create descending
  sequences:

  for (INFOMIXV6ALS::reverse(1 .. 10)) { ... }

  Because of the way hashes flatten into lists when passed as a @list, reverse can
  also be used to invert a hash, presuming the values are unique:

  %barfoo = INFOMIXV6ALS::reverse(%foobar);

  In scalar context, the function concatenates all the elements of LIST and then
  returns the reverse of that resulting string, character by character.

=item length by INFOMIX V6 ALS character

  $length = INFOMIXV6ALS::length($string);
  $length = INFOMIXV6ALS::length();

  This function returns the length in characters of the scalar value $string. If
  $string is omitted, it returns the INFOMIXV6ALS::length of $_.

  Do not try to use length to find the size of an array or hash. Use scalar @array
  for the size of an array, and scalar keys %hash for the number of key/value pairs
  in a hash. (The scalar is typically omitted when redundant.)

  To find the length of a string in bytes rather than characters, say:

  $blen = length $string;

  or

  $blen = CORE::length $string;

=item substr by INFOMIX V6 ALS character

  $substr = INFOMIXV6ALS::substr($string,$offset,$length,$replacement);
  $substr = INFOMIXV6ALS::substr($string,$offset,$length);
  $substr = INFOMIXV6ALS::substr($string,$offset);

  This function extracts a substring out of the string given by $string and returns
  it. The substring is extracted starting at $offset characters from the front of
  the string.
  If $offset is negative, the substring starts that far from the end of the string
  instead. If $length is omitted, everything to the end of the string is returned.
  If $length is negative, the length is calculated to leave that many characters off
  the end of the string. Otherwise, $length indicates the length of the substring to
  extract, which is sort of what you'd expect.

  An alternative to using INFOMIXV6ALS::substr as an lvalue is to specify the $replacement
  string as the fourth argument. This allows you to replace parts of the $string and
  return what was there before in one operation, just as you can with splice. The next
  example also replaces the last character of $var with "Curly" and puts that replaced
  character into $oldstr: 

  $oldstr = INFOMIXV6ALS::substr($var, -1, 1, "Curly");

  If you assign something shorter than the length of your substring, the string will
  shrink, and if you assign something longer than the length, the string will grow to
  accommodate it. To keep the string the same length, you may need to pad or chop your
  value using sprintf or the x operator. If you attempt to assign to an unallocated
  area past the end of the string, INFOMIXV6ALS::substr raises an exception.

  To prepend the string "Larry" to the current value of $_, use:

  INFOMIXV6ALS::substr($var, 0, 0, "Larry");

  To instead replace the first character of $_ with "Moe", use:

  INFOMIXV6ALS::substr($var, 0, 1, "Moe");

  And finally, to replace the last character of $var with "Curly", use:

  INFOMIXV6ALS::substr($var, -1, 1, "Curly");

=item index by INFOMIX V6 ALS character

  $index = INFOMIXV6ALS::index($string,$substring,$offset);
  $index = INFOMIXV6ALS::index($string,$substring);

  This function searches for one string within another. It returns the position of
  the first occurrence of $substring in $string. The $offset, if specified, says how
  many characters from the start to skip before beginning to look. Positions are
  based at 0. If the substring is not found, the function returns one less than the
  base, ordinarily -1. To work your way through a string, you might say:

  $pos = -1;
  while (($pos = INFOMIXV6ALS::index($string, $lookfor, $pos)) > -1) {
      print "Found at $pos\n";
      $pos++;
  }

=item rindex by INFOMIX V6 ALS character

  $rindex = INFOMIXV6ALS::rindex($string,$substring,$position);
  $rindex = INFOMIXV6ALS::rindex($string,$substring);

  This function works just like INFOMIXV6ALS::index except that it returns the position of
  the last occurrence of $substring in $string (a reverse index). The function
  returns -1 if not $substring is found. $position, if specified, is the rightmost
  position that may be returned. To work your way through a string backward, say:

  $pos = INFOMIXV6ALS::length($string);
  while (($pos = INFOMIXV6ALS::rindex($string, $lookfor, $pos)) >= 0) {
      print "Found at $pos\n";
      $pos--;
  }

=back

=head1 BUGS AND LIMITATIONS

Please patches and report problems to author are welcome.

=over 2

=item * format

Function "format" can't handle multiple octet code same as original Perl.

=item * chdir

Function "chdir" can't change directory chr(0x5C) ended path on perl5.006, perl5.008
and perl5.010 if MSWin32.

see also,
Bug #81839
chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839

=item * /o modifier of m/$re/o, s/$re/foo/o and qr/$re/o

/o modifier doesn't do operation the same as the expectation on perl5.6.1.
The latest value of variable $re is used as a regular expression.

=item * Escape character \b and \B

Escape character \b and \B in regular expression doesn't function like our hope.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 MY GOAL

P.401 See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of Unicode support in perl, The eq operator
just compared the byte-strings represented by two scalars. Beginning
with perl 5.8, eq compares two byte-strings with simultaneous
consideration of the UTF8 flag.

This change consequentially made a big gap between a past script and
new script. Both scripts cannot re-use the code mutually any longer.
Because a new method puts a strain in the programmer, it will still take
time to replace all the in existence scripts.

The biggest problem of new method is that the UTF8 flag can't synchronize
to real encode of string. Thus you must debug about UTF8 flag, before
your script. How to solve it by returning to a past method, I will quote
page 402 of Programming Perl, 3rd ed. again.

Ideally, I'd like to achieve these five Goals:

=over 2

=item Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

It has already been achieved by INFOMIX V6 ALS designed for combining with
old byte-oriented ASCII.

=item Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

Still now, 1 octet is counted with 1 by embedded functions length,
substr, index, rindex and pos that handle length and position of string.
In this part, there is no change. The length of 1 character of 2 octet
code is 2.

On the other hand, the regular expression in the script is added the
multibyte anchoring processing with this software, instead of you.

figure of Goal #1 and Goal #2.

                               GOAL#1  GOAL#2
                        (a)     (b)     (c)     (d)     (e)
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

There is a combination from (a) to (e) in data, script and interpreter
of old and new. Let's add the Encode module and this software did not
exist at time of be written this document and JPerl did exist.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl           Encode,INFOMIXV6ALS
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

The reason why JPerl is very excellent is that it is at the position of
(c). That is, it is not necessary to do a special description to the
script to process new character-oriented string.

Contrasting is Encode module and describing "use INFOMIXV6ALS;" on this software,
in this case, a new description is necessary.

=item Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of escape script for old byte-oriented perl.

(2) Time of processing regular expression by escaped script while
    multibyte anchoring.

=item Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

A character-oriented Perl is not necessary to make it specially,
because a byte-oriented Perl can already treat the binary data.
This software is only an application program of Perl, a filter program.
If perl can be executed, this software will be able to be executed.

=item Goal #5:

JPerl users will be able to maintain JPerl by Perl.

--- maybe.

=back

Back when Programming Perl, 3rd ed. was written, UTF8 flag was not born
and Perl is designed to make the easy jobs easy. This software provide
programming environment like at that time.

=head1 SEE ALSO

 Programming Perl, Second Edition
 By Larry Wall, Tom Christiansen, Randal L. Schwartz
 January 1900 (really so?)
 Pages: 670
 ISBN 10: 1-56592-149-6 | ISBN 13: 9781565921498
 http://oreilly.com/catalog/9781565921498/

 Programming Perl, Third Edition
 By Larry Wall, Tom Christiansen, Jon Orwant
 Third Edition  July 2000
 Pages: 1104
 ISBN 10: 0-596-00027-8 | ISBN 13:9780596000271
 http://www.oreilly.com/catalog/pperl3/index.html

 Perl Cookbook, Second Edition
 By Tom Christiansen, Nathan Torkington
 Second Edition  August 2003
 Pages: 964
 ISBN 10: 0-596-00313-7 | ISBN 13: 9780596003135
 http://oreilly.com/catalog/9780596003135/index.html

 Perl in a Nutshell, Second Edition
 By Stephen Spainhour, Ellen Siever, Nathan Patwardhan
 Second Edition  June 2002
 Pages: 760
 Series: In a Nutshell
 ISBN 10: 0-596-00241-6 | ISBN 13: 9780596002411
 http://oreilly.com/catalog/9780596002411/index.html

 Learning Perl on Win32 Systems
 By Randal L. Schwartz, Erik Olson, Tom Christiansen
 August 1997
 Pages: 306
 ISBN 10: 1-56592-324-3 | ISBN 13: 9781565923249
 http://oreilly.com/catalog/9781565923249/

 Learning Perl, Fifth Edition
 By Randal L. Schwartz, Tom Phoenix, brian d foy
 June 2008
 Pages: 352
 Print ISBN:978-0-596-52010-6 | ISBN 10: 0-596-52010-7
 Ebook ISBN:978-0-596-10316-3 | ISBN 10: 0-596-10316-6
 http://oreilly.com/catalog/9780596520113/

 Perl RESOURCE KIT UNIX EDITION
 Futato, Irving, Jepson, Patwardhan, Siever
 ISBN 10: 1-56592-370-7

 Understanding Japanese Information Processing
 By Ken Lunde
 January 1900
 Pages: 470
 ISBN 10: 1-56592-043-0 | ISBN 13: 9781565920439
 http://oreilly.com/catalog/9781565920439/

 CJKV Information Processing
 Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 First Edition  January 1999
 Pages: 1128
 ISBN 10: 1-56592-224-7 | ISBN 13:9781565922242
 http://www.oreilly.com/catalog/cjkvinfo/index.html
 ISBN 4-87311-108-0
 http://www.oreilly.co.jp/books/4873111080/

 Mastering Regular Expressions, Second Edition
 By Jeffrey E. F. Friedl
 Second Edition  July 2002
 Pages: 484
 ISBN 10: 0-596-00289-0 | ISBN 13: 9780596002893
 http://oreilly.com/catalog/9780596002893/index.html

 Mastering Regular Expressions, Third Edition
 By Jeffrey E. F. Friedl
 Third Edition  August 2006
 Pages: 542
 ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
 http://www.oreilly.com/catalog/regex3/index.html
 ISBN 978-4-87311-359-3
 http://www.oreilly.co.jp/books/9784873113593/

 PERL PUROGURAMINGU
 Larry Wall, Randal L.Schwartz, Yoshiyuki Kondo
 December 1997
 ISBN 4-89052-384-7
 http://www.context.co.jp/~cond/books/old-books.html

 JIS KANJI JITEN
 Kouji Shibano
 Pages: 1456
 ISBN 4-542-20129-5
 http://www.webstore.jsa.or.jp/lib/lib.asp?fn=/manual/mnl01_12.htm

 UNIX MAGAZINE
 1993 Aug
 Pages: 172
 T1008901080816 ZASSHI 08901-8
 http://ascii.asciimw.jp/books/magazines/unix.shtml

=head1 ACKNOWLEDGEMENTS

This software was made referring to software and the document that the
following hackers or persons had made. 
I am thankful to all persons.

 Rick Yamashita, Shift_JIS
 ttp://furukawablog.spaces.live.com/Blog/cns!1pmWgsL289nm7Shn7cS0jHzA!2225.entry
 (add 'h' at head)

 Larry Wall, Perl
 http://www.perl.org/

 Kazumasa Utashiro, jcode.pl
 ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

 Jeffrey E. F. Friedl, Mastering Regular Expressions
 http://www.oreilly.com/catalog/regex/index.html

 SADAHIRO Tomoyuki, The right way of using Shift_JIS
 http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm

 Yukihiro "Matz" Matsumoto, YAPC::Asia2006 Ruby on Perl(s)
 http://www.rubyist.net/~matz/slides/yapc2006/

 jscripter, For jperl users
 http://homepage1.nifty.com/kazuf/jperl.html

 Hiroaki Izumi, Perl5.8/Perl5.10 is not useful on the Windows.
 http://www.aritia.org/hizumi/perl/perlwin.html

 TSUKAMOTO Makio, Perl memo/file path of Windows
 http://digit.que.ne.jp/work/wiki.cgi?Perl%E3%83%A1%E3%83%A2%2FWindows%E3%81%A7%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%83%91%E3%82%B9

 chaichanPaPa, Matching Shift_JIS file name
 http://d.hatena.ne.jp/chaichanPaPa/20080802/1217660826

 SUZUKI Norio, Jperl
 http://homepage2.nifty.com/kipp/perl/jperl/

 Hirofumi Watanabe, Jperl
 http://search.cpan.org/~watanabe/
 http://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html

 Dan Kogai, Encode module
 http://search.cpan.org/dist/Encode/

 Tokyo-pm archive
 http://mail.pm.org/pipermail/tokyo-pm/

=cut

