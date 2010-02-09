package Einfomixv6als;
######################################################################
#
# Einfomixv6als - Run-time routines for INFOMIXV6ALS.pm
#
#                  http://search.cpan.org/dist/INFOMIXV6ALS/
#
# Copyright (c) 2008, 2009, 2010 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use strict;
use 5.00503;
use vars qw($VERSION $_warning);

$VERSION = sprintf '%d.%02d', q$Revision: 0.49 $ =~ m/(\d+)/xmsg;

use Fcntl;
use Symbol;
use FindBin;

use Carp qw(carp croak confess cluck verbose);
local $SIG{__DIE__}  = sub { confess @_ } if exists $ENV{'SJIS_DEBUG'};
local $SIG{__WARN__} = sub { cluck   @_ } if exists $ENV{'SJIS_DEBUG'};
$_warning = $^W; # push warning, warning on
local $^W = 1;

BEGIN {
    if ($^X =~ m/ jperl /oxmsi) {
        croak "$0 need perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
}

my $your_char = q{\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF]};

# regexp of character
my $q_char = qr/$your_char/oxms;

#
# INFOMIX V6 ALS character range per length
#
my %range_tr = ();
my $is_shiftjis_family = 0;
my $is_eucjp_family    = 0;

if (0) {
}

# Big5Plus
elsif (__PACKAGE__ eq 'Ebig5plus') {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
    );
}

# GB18030
elsif (__PACKAGE__ eq 'Egb18030') {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
        4 => [ [0x81..0xFE],[0x30..0x39],[0x81..0xFE],[0x30..0x39],
             ],
    );
}

# GBK
elsif (__PACKAGE__ eq 'Egbk') {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
    );
}

# HP-15
elsif (__PACKAGE__ eq 'Ehp15') {
    %range_tr = (
        1 => [ [0x00..0x7F,0xA1..0xDF,0xFF],
             ],
        2 => [ [0x80..0xA0,0xE0..0xFE],[0x21..0x7E,0x80..0xFF],
             ],
    );
    $is_shiftjis_family = 1;
}

# INFOMIX V6 ALS
elsif (__PACKAGE__ eq 'Einfomixv6als') {
    %range_tr = (
        1 => [ [0x00..0x80,0xA0..0xDF,0xFE..0xFF],
             ],
        2 => [ [0x81..0x9F,0xE0..0xFC],[0x40..0x7E,0x80..0xFC],
             ],
        3 => [ [0xFD..0xFD],[0xA1..0xFE],[0xA1..0xFE],
             ],
    );
    $is_shiftjis_family = 1;
}

# Shift_JIS
elsif (__PACKAGE__ eq 'E'.'sjis') {
    %range_tr = (
        1 => [ [0x00..0x80,0xA0..0xDF,0xFD..0xFF],
             ],
        2 => [ [0x81..0x9F,0xE0..0xFC],[0x40..0x7E,0x80..0xFC],
             ],
    );
    $is_shiftjis_family = 1;
}

# UHC
elsif (__PACKAGE__ eq 'Euhc') {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x41..0x5A,0x61..0x7A,0x81..0xFE],
             ],
    );
}

# EUC-JP
elsif (__PACKAGE__ eq 'Eeucjp') {
    %range_tr = (
        1 => [ [0x00..0x8D,0x90..0xA0,0xFF],
             ],
        2 => [ [0x8E..0x8E],[0xA1..0xDF],
               [0xA1..0xFE],[0xA1..0xFE],
             ],
        3 => [ [0x8F..0x8F],[0xA1..0xFE],[0xA1..0xFE],
             ],
    );
    $is_eucjp_family = 1;
}

# UTF-2
elsif (__PACKAGE__ eq 'Eutf2') {
    %range_tr = (
        1 => [ [0x00..0x7F],
             ],
        2 => [ [0xC2..0xDF],[0x80..0xBF],
             ],
        3 => [ [0xE0..0xE0],[0xA0..0xBF],[0x80..0xBF],
               [0xE1..0xEC],[0x80..0xBF],[0x80..0xBF],
               [0xED..0xED],[0x80..0x9F],[0x80..0xBF],
               [0xEE..0xEF],[0x80..0xBF],[0x80..0xBF],
             ],
        4 => [ [0xF0..0xF0],[0x90..0xBF],[0x80..0xBF],[0x80..0xBF],
               [0xF1..0xF3],[0x80..0xBF],[0x80..0xBF],[0x80..0xBF],
               [0xF4..0xF4],[0x80..0x8F],[0x80..0xBF],[0x80..0xBF],
             ],
    );
}

else {
    croak "$0 don't know my package name '" . __PACKAGE__ . "'";
}

#
# Prototypes of subroutines
#
sub import() {}
sub unimport() {}
sub Einfomixv6als::split(;$$$);
sub Einfomixv6als::tr($$$$;$);
sub Einfomixv6als::chop(@);
sub Einfomixv6als::index($$;$);
sub Einfomixv6als::rindex($$;$);
sub Einfomixv6als::lc(@);
sub Einfomixv6als::lc_();
sub Einfomixv6als::uc(@);
sub Einfomixv6als::uc_();
sub Einfomixv6als::capture($);
sub Einfomixv6als::ignorecase(@);
sub Einfomixv6als::chr(;$);
sub Einfomixv6als::chr_();
sub Einfomixv6als::filetest(@);
sub Einfomixv6als::r(;*@);
sub Einfomixv6als::w(;*@);
sub Einfomixv6als::x(;*@);
sub Einfomixv6als::o(;*@);
sub Einfomixv6als::R(;*@);
sub Einfomixv6als::W(;*@);
sub Einfomixv6als::X(;*@);
sub Einfomixv6als::O(;*@);
sub Einfomixv6als::e(;*@);
sub Einfomixv6als::z(;*@);
sub Einfomixv6als::s(;*@);
sub Einfomixv6als::f(;*@);
sub Einfomixv6als::d(;*@);
sub Einfomixv6als::l(;*@);
sub Einfomixv6als::p(;*@);
sub Einfomixv6als::S(;*@);
sub Einfomixv6als::b(;*@);
sub Einfomixv6als::c(;*@);
sub Einfomixv6als::t(;*@);
sub Einfomixv6als::u(;*@);
sub Einfomixv6als::g(;*@);
sub Einfomixv6als::k(;*@);
sub Einfomixv6als::T(;*@);
sub Einfomixv6als::B(;*@);
sub Einfomixv6als::M(;*@);
sub Einfomixv6als::A(;*@);
sub Einfomixv6als::C(;*@);
sub Einfomixv6als::filetest_(@);
sub Einfomixv6als::r_();
sub Einfomixv6als::w_();
sub Einfomixv6als::x_();
sub Einfomixv6als::o_();
sub Einfomixv6als::R_();
sub Einfomixv6als::W_();
sub Einfomixv6als::X_();
sub Einfomixv6als::O_();
sub Einfomixv6als::e_();
sub Einfomixv6als::z_();
sub Einfomixv6als::s_();
sub Einfomixv6als::f_();
sub Einfomixv6als::d_();
sub Einfomixv6als::l_();
sub Einfomixv6als::p_();
sub Einfomixv6als::S_();
sub Einfomixv6als::b_();
sub Einfomixv6als::c_();
sub Einfomixv6als::t_();
sub Einfomixv6als::u_();
sub Einfomixv6als::g_();
sub Einfomixv6als::k_();
sub Einfomixv6als::T_();
sub Einfomixv6als::B_();
sub Einfomixv6als::M_();
sub Einfomixv6als::A_();
sub Einfomixv6als::C_();
sub Einfomixv6als::glob($);
sub Einfomixv6als::glob_();
sub Einfomixv6als::lstat(*);
sub Einfomixv6als::lstat_();
sub Einfomixv6als::opendir(*$);
sub Einfomixv6als::stat(*);
sub Einfomixv6als::stat_();
sub Einfomixv6als::unlink(@);
sub Einfomixv6als::chdir(;$);
sub Einfomixv6als::do($);
sub Einfomixv6als::require(;$);
sub Einfomixv6als::telldir(*);

sub INFOMIXV6ALS::ord(;$);
sub INFOMIXV6ALS::ord_();
sub INFOMIXV6ALS::reverse(@);
sub INFOMIXV6ALS::length(;$);
sub INFOMIXV6ALS::substr($$;$$);
sub INFOMIXV6ALS::index($$;$);
sub INFOMIXV6ALS::rindex($$;$);

#
# @ARGV wildcard globbing
#
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    if ($ENV{'ComSpec'} =~ / (?: COMMAND\.COM | CMD\.EXE ) \z /oxmsi) {
        my @argv = ();
        for (@ARGV) {
            if (m/\A ' ((?:$q_char)*) ' \z/oxms) {
                push @argv, $1;
            }
            elsif (my @glob = Einfomixv6als::glob($_)) {
                push @argv, @glob;
            }
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }
}

#
# prepare INFOMIX V6 ALS characters per length
#
my @chars1 = ();
my @chars2 = ();
my @chars3 = ();
my @chars4 = ();
if (exists $range_tr{1}) {
    my @ranges = @{ $range_tr{1} };
    while (my @range = splice(@ranges,0,1)) {
        for my $oct0 (@{$range[0]}) {
            push @chars1, pack 'C', $oct0;
        }
    }
}
if (exists $range_tr{2}) {
    my @ranges = @{ $range_tr{2} };
    while (my @range = splice(@ranges,0,2)) {
        for my $oct0 (@{$range[0]}) {
            for my $oct1 (@{$range[1]}) {
                push @chars2, pack 'CC', $oct0,$oct1;
            }
        }
    }
}
if (exists $range_tr{3}) {
    my @ranges = @{ $range_tr{3} };
    while (my @range = splice(@ranges,0,3)) {
        for my $oct0 (@{$range[0]}) {
            for my $oct1 (@{$range[1]}) {
                for my $oct2 (@{$range[2]}) {
                    push @chars3, pack 'CCC', $oct0,$oct1,$oct2;
                }
            }
        }
    }
}
if (exists $range_tr{4}) {
    my @ranges = @{ $range_tr{4} };
    while (my @range = splice(@ranges,0,4)) {
        for my $oct0 (@{$range[0]}) {
            for my $oct1 (@{$range[1]}) {
                for my $oct2 (@{$range[2]}) {
                    for my $oct3 (@{$range[3]}) {
                        push @chars4, pack 'CCCC', $oct0,$oct1,$oct2,$oct3;
                    }
                }
            }
        }
    }
}
my @minchar = (undef, $chars1[ 0], $chars2[ 0], $chars3[ 0], $chars4[ 0]);
my @maxchar = (undef, $chars1[-1], $chars2[-1], $chars3[-1], $chars4[-1]);

#
# INFOMIX V6 ALS split
#
sub Einfomixv6als::split(;$$$) {

    # P.794 29.2.161. split
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    my $pattern = $_[0];
    my $string  = $_[1];
    my $limit   = $_[2];

    # if $string is omitted, the function splits the $_ string
    $string = $_ if not defined $string;

    my @split = ();

    # when string is empty
    if ($string eq '') {

        # resulting list value in list context
        if (wantarray) {
            return @split;
        }

        # count of substrings in scalar context
        else {
            cluck "$0: Use of implicit split to \@_ is deprecated" if $^W;
            @_ = @split;
            return scalar @_;
        }
    }

    # if $limit is negative, it is treated as if an arbitrarily large $limit has been specified
    if ((not defined $limit) or ($limit <= 0)) {

        # if $pattern is also omitted or is the literal space, " ", the function splits
        # on whitespace, /\s+/, after skipping any leading whitespace
        # (and so on)

        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;

            # the //m modifier is assumed when you split on the pattern /^/
            # (and so on)

            while ($string =~ s/\A((?:$q_char)*?)\s+//m) {

                # if the $pattern contains parentheses, then the substring matched by each pair of parentheses
                # is included in the resulting list, interspersed with the fields that are ordinarily returned
                # (and so on)

                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }

        # a pattern capable of matching either the null string or something longer than the
        # null string will split the value of $string into separate characters wherever it
        # matches the null string between characters
        # (and so on)

        elsif ('' =~ m/ \A $pattern \z /xms) {
            while ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }

        else {
            while ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }
    }

    else {
        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)\s+//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
        elsif ('' =~ m/ \A $pattern \z /xms) {
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
        else {
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
    }

    push @split, $string;

    # if $limit is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $limit) or ($limit == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # resulting list value in list context
    if (wantarray) {
        return @split;
    }

    # count of substrings in scalar context
    else {
        cluck "$0: Use of implicit split to \@_ is deprecated" if $^W;
        @_ = @split;
        return scalar @_;
    }
}

#
# INFOMIX V6 ALS transliteration (tr///)
#
sub Einfomixv6als::tr($$$$;$) {

    my $bind_operator   = $_[1];
    my $searchlist      = $_[2];
    my $replacementlist = $_[3];
    my $modifier        = $_[4] || '';

    my @char            = $_[0] =~ m/\G ($q_char) /oxmsg;
    my @searchlist      = _charlist_tr($searchlist);
    my @replacementlist = _charlist_tr($replacementlist);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($modifier =~ m/d/oxms) {
                $tr{$searchlist[$i]} = '';
            }
            elsif (defined $replacementlist[-1] and ($replacementlist[-1] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[-1];
            }
            else {
                $tr{$searchlist[$i]} = $searchlist[$i];
            }
        }
    }

    my $tr = 0;
    $_[0] = '';
    if ($modifier =~ m/c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $_[0] .= $replacementlist[0];
                }
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (not exists $tr{$char[0]})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $_[0] .= $char;
            }
        }
    }
    else {
        while (defined(my $char = shift @char)) {
            if (exists $tr{$char}) {
                $_[0] .= $tr{$char};
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (exists $tr{$char[0]}) and ($tr{$char[0]} eq $tr{$char})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $_[0] .= $char;
            }
        }
    }

    if ($bind_operator =~ m/ !~ /oxms) {
        return not $tr;
    }
    else {
        return $tr;
    }
}

#
# INFOMIX V6 ALS chop
#
sub Einfomixv6als::chop(@) {

    my $chop;
    if (@_ == 0) {
        my @char = m/\G ($q_char) /oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for (@_) {
            my @char = m/\G ($q_char) /oxmsg;
            $chop = pop @char;
            $_ = join '', @char;
        }
    }
    return $chop;
}

#
# INFOMIX V6 ALS index by octet
#
sub Einfomixv6als::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#
# INFOMIX V6 ALS reverse index
#
sub Einfomixv6als::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# INFOMIX V6 ALS lower case
#
{
    # P.132 4.8.2. Lexically Scoped Variables: my
    # in Chapter 4: Statements and Declarations
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    # (and so on)

    my %lc = ();
    @lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
        qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

    # lower case with parameter
    sub Einfomixv6als::lc(@) {

        local $_ = shift if @_;

        return join('', map {defined($lc{$_}) ? $lc{$_} : $_} m/\G ($q_char) /oxmsg), @_;
    }

    # lower case without parameter
    sub Einfomixv6als::lc_() {

        return join('', map {defined($lc{$_}) ? $lc{$_} : $_} m/\G ($q_char) /oxmsg);
    }
}

#
# INFOMIX V6 ALS upper case
#
{
    my %uc = ();
    @uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
        qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    # upper case with parameter
    sub Einfomixv6als::uc(@) {

        local $_ = shift if @_;

        return join('', map {defined($uc{$_}) ? $uc{$_} : $_} m/\G ($q_char) /oxmsg), @_;
    }

    # upper case without parameter
    sub Einfomixv6als::uc_() {

        return join('', map {defined($uc{$_}) ? $uc{$_} : $_} m/\G ($q_char) /oxmsg);
    }
}

#
# INFOMIX V6 ALS regexp capture
#
{
    my $last_s_matched = 0;

    sub Einfomixv6als::capture($) {
        if ($last_s_matched and ($_[0] =~ m/\A [1-9][0-9]* \z/oxms)) {
            return $_[0] + 1;
        }
        else {
            return $_[0];
        }
    }

    # INFOMIX V6 ALS regexp mark last m// or qr// matched
    sub Einfomixv6als::m_matched() {
        $last_s_matched = 0;
    }

    # INFOMIX V6 ALS regexp mark last s/// or qr matched
    sub Einfomixv6als::s_matched() {
        $last_s_matched = 1;
    }
}

#
# INFOMIX V6 ALS regexp ignore case option
#
sub Einfomixv6als::ignorecase(@) {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ m{\G(
            \[\^ |
                \\? (?:$q_char)
        )}oxmsg;

        # unescape character
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # open character class [...]
            if ($char[$i] eq '[') {
                my $left = $i;
                while (1) {
                    if (++$i > $#char) {
                        croak "$0: unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = $1 . '\\' . $char;
                            }
                        }

                        # [...]
                        splice @char, $left, $right-$left+1, '(?:' . join('|', @charlist) . ')';

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
                        croak "$0: unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [^...]
                        splice @char, $left, $right-$left+1, '(?!' . join('|', @charlist) . ")(?:$your_char)";

                        $i = $left;
                        last;
                    }
                }
            }

            # rewrite character class or escape character
            elsif (my $char = {
                '\D' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9])',
                '\S' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])',
                '\W' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9A-Z_a-z])',
                '\d' => '[0-9]',
                '\s' => '[\x09\x0A\x0C\x0D\x20]',
                '\w' => '[0-9A-Z_a-z]',

                '\H' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x20])',
                '\V' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x0C\x0A\x0D])',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0C\x0A\x0D]',

                }->{$char[$i]}
            ) {
                $char[$i] = $char;
            }

            # /i option
            elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
                my $c = $1;
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # escape last octet of multiple octet
            if ($char[$i] =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                $char[$i] = $1 . '\\' . $2;
            }

            # quote character before ? + * {
            elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
                if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                    $char[$i-1] = '(?:' . $char[$i-1] . ')';
                }
            }
        }

        $string = join '', @char;
    }

    # make regexp string
    return @string;
}

#
# INFOMIX V6 ALS open character list for tr
#
sub _charlist_tr {

    local $_ = shift @_;

    # unescape character
    my @char = ();
    while (not m/\G \z/oxmsgc) {
        if (m/\G (\\0?55|\\x2[Dd]|\\-) /oxmsgc) {
            push @char, '\-';
        }
        elsif (m/\G \\ ([0-7]{2,3}) /oxmsgc) {
            push @char, CORE::chr(oct $1);
        }
        elsif (m/\G \\x ([0-9A-Fa-f]{1,2}) /oxmsgc) {
            push @char, CORE::chr(hex $1);
        }
        elsif (m/\G \\c ([\x40-\x5F]) /oxmsgc) {
            push @char, CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif (m/\G (\\ [0nrtfbae]) /oxmsgc) {
            push @char, {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
            }->{$1};
        }
        elsif (m/\G \\ ($q_char) /oxmsgc) {
            push @char, $1;
        }
        elsif (m/\G ($q_char) /oxmsgc) {
            push @char, $1;
        }
    }

    # join separated multiple octet
    @char = join('',@char) =~ m/\G (\\-|$q_char) /oxmsg;

    # unescape '-'
    my @i = ();
    for my $i (0 .. $#char) {
        if ($char[$i] eq '\-') {
            $char[$i] = '-';
        }
        elsif ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                push @i, $i;
            }
        }
    }

    # open character list (reverse for splice)
    for my $i (CORE::reverse @i) {
        my @range = ();

        # range error
        if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
            croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
        }

        # range of multiple octet code
        if (length($char[$i-1]) == 1) {
            if (length($char[$i+1]) == 1) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} @chars1;
            }
            elsif (length($char[$i+1]) == 2) {
                push @range, grep {$char[$i-1] le $_}                           @chars1;
                push @range, grep {$_ le $char[$i+1]}                           @chars2;
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           @chars1;
                push @range,                                                    @chars2;
                push @range, grep {$_ le $char[$i+1]}                           @chars3;
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           @chars1;
                push @range,                                                    @chars2;
                push @range,                                                    @chars3;
                push @range, grep {$_ le $char[$i+1]}                           @chars4;
            }
        }
        elsif (length($char[$i-1]) == 2) {
            if (length($char[$i+1]) == 2) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} @chars2;
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           @chars2;
                push @range, grep {$_ le $char[$i+1]}                           @chars3;
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           @chars2;
                push @range,                                                    @chars3;
                push @range, grep {$_ le $char[$i+1]}                           @chars4;
            }
        }
        elsif (length($char[$i-1]) == 3) {
            if (length($char[$i+1]) == 3) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} @chars3;
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           @chars3;
                push @range, grep {$_ le $char[$i+1]}                           @chars4;
            }
        }
        elsif (length($char[$i-1]) == 4) {
            if (length($char[$i+1]) == 4) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} @chars4;
            }
        }

        splice @char, $i-1, 3, @range;
    }

    return @char;
}

#
# INFOMIX V6 ALS octet range
#
sub _octets {

    my $modifier = pop @_;
    my $length = shift;

    my($a) = unpack 'C', $_[0];
    my($z) = unpack 'C', $_[1];

    # single octet code
    if ($length == 1) {

        # single octet and ignore case
        if (((caller(1))[3] ne 'Einfomixv6als::_octets') and ($modifier =~ m/i/oxms)) {
            if ($a == $z) {
                return sprintf('(?i:\x%02X)',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('(?i:[\x%02X\x%02X])',  $a, $z);
            }
            else {
                return sprintf('(?i:[\x%02X-\x%02X])', $a, $z);
            }
        }

        # not ignore case or one of multiple octet
        else {
            if ($a == $z) {
                return sprintf('\x%02X',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('[\x%02X\x%02X]',  $a, $z);
            }
            else {
                return sprintf('[\x%02X-\x%02X]', $a, $z);
            }
        }
    }

    # double octet code of Shift_JIS family
    elsif (($length == 2) and $is_shiftjis_family and ($a <= 0x9F) and (0xE0 <= $z)) {
        my(undef,$a2) = unpack 'CC', $_[0];
        my(undef,$z2) = unpack 'CC', $_[1];
        my $octets1;
        my $octets2;

        if ($a == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]',                            0x9F,$a2);
        }
        elsif (($a+1) == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|\x%02X[\x00-\xFF]',          $a,  $a2,$a+1);
        }
        elsif (($a+2) == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|[\x%02X\x%02X][\x00-\xFF]',  $a,  $a2,$a+1,$a+2);
        }
        else {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|[\x%02X-\x%02X][\x00-\xFF]', $a,  $a2,$a+1,$a+2);
        }

        if ($z == 0xE0) {
            $octets2 = sprintf('\x%02X[\x00-\x%02X]',                                      $z,$z2);
        }
        elsif (($z-1) == 0xE0) {
            $octets2 = sprintf('\x%02X[\x00-\xFF]|\x%02X[\x00-\x%02X]',               $z-1,$z,$z2);
        }
        elsif (($z-2) == 0xE0) {
            $octets2 = sprintf('[\x%02X\x%02X][\x00-\xFF]|\x%02X[\x00X-\x%02X]', $z-2,$z-1,$z,$z2);
        }
        else {
            $octets2 = sprintf('[\x%02X-\x%02X][\x00-\xFF]|\x%02X[\x00-\x%02X]', 0xE0,$z-1,$z,$z2);
        }

        return "(?:$octets1|$octets2)";
    }

    # double octet code of EUC-JP family
    elsif (($length == 2) and $is_eucjp_family and ($a == 0x8E) and (0xA1 <= $z)) {
        my(undef,$a2) = unpack 'CC', $_[0];
        my(undef,$z2) = unpack 'CC', $_[1];
        my $octets1;
        my $octets2;

        $octets1 = sprintf('\x%02X[\x%02X-\xFF]',                                0x8E,$a2);

        if ($z == 0xA1) {
            $octets2 = sprintf('\x%02X[\x00-\x%02X]',                                      $z,$z2);
        }
        elsif (($z-1) == 0xA1) {
            $octets2 = sprintf('\x%02X[\x00-\xFF]|\x%02X[\x00-\x%02X]',               $z-1,$z,$z2);
        }
        elsif (($z-2) == 0xA1) {
            $octets2 = sprintf('[\x%02X\x%02X][\x00-\xFF]|\x%02X[\x00X-\x%02X]', $z-2,$z-1,$z,$z2);
        }
        else {
            $octets2 = sprintf('[\x%02X-\x%02X][\x00-\xFF]|\x%02X[\x00-\x%02X]', 0xA1,$z-1,$z,$z2);
        }

        return "(?:$octets1|$octets2)";
    }

    # multiple octet code
    else {
        my(undef,$aa) = unpack 'Ca*', $_[0];
        my(undef,$zz) = unpack 'Ca*', $_[1];

        if ($a == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                $zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+1) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                $maxchar[$length-1],$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,$minchar[$length-1],$zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+2) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                $maxchar[$length-1],$modifier)),
                sprintf('\x%02X%s',         $a+1,       _octets($length-1,$minchar[$length-1],$maxchar[$length-1],$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,$minchar[$length-1],$zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+3) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                $maxchar[$length-1],$modifier)),
                sprintf('[\x%02X\x%02X]%s', $a+1,$z-1,  _octets($length-1,$minchar[$length-1],$maxchar[$length-1],$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,$minchar[$length-1],$zz,                $modifier)),
            ) . ')';
        }
        else {
            return '(?:' . join('|',
                sprintf('\x%02X%s',          $a,        _octets($length-1,$aa,                $maxchar[$length-1],$modifier)),
                sprintf('[\x%02X-\x%02X]%s', $a+1,$z-1, _octets($length-1,$minchar[$length-1],$maxchar[$length-1],$modifier)),
                sprintf('\x%02X%s',               $z,   _octets($length-1,$minchar[$length-1],$zz,                $modifier)),
            ) . ')';
        }
    }
}

#
# INFOMIX V6 ALS open character list for qr and not qr
#
sub _charlist {

    my $modifier = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr oct $1;
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{1,2}) \z/oxms) {
            $char[$i] = CORE::chr hex $1;
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDhHsSvVwW]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '[0-9]',
                '\s' => '[\x09\x0A\x0C\x0D\x20]',
                '\w' => '[0-9A-Z_a-z]',
                '\D' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9])',
                '\S' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])',
                '\W' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^0-9A-Z_a-z])',

                '\H' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x09\x20])',
                '\V' => '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x0C\x0A\x0D])',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0C\x0A\x0D]',

            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ($q_char) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    for (my $i=0; $i <= $#char; ) {

        # escaped -
        if (defined($char[$i+1]) and ($char[$i+1] eq '...')) {
            $i += 1;
            next;
        }
        elsif ($char[$i] eq '...') {

            # range error
            if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
                croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            # range of single octet code and not ignore case
            if ((length($char[$i-1]) == 1) and (length($char[$i+1]) == 1) and ($modifier !~ m/i/oxms)) {
                my $a = unpack 'C', $char[$i-1];
                my $z = unpack 'C', $char[$i+1];

                if ($a == $z) {
                    push @singleoctet, sprintf('\x%02X',        $a);
                }
                elsif (($a+1) == $z) {
                    push @singleoctet, sprintf('\x%02X\x%02X',  $a, $z);
                }
                else {
                    push @singleoctet, sprintf('\x%02X-\x%02X', $a, $z);
                }
            }

            # range of multiple octet code
            elsif (length($char[$i-1]) == length($char[$i+1])) {
                push @charlist, _octets(length($char[$i-1]), $char[$i-1], $char[$i+1], $modifier);
            }
            elsif (length($char[$i-1]) == 1) {
                if (length($char[$i+1]) == 2) {
                    push @charlist,
                        _octets(1, $char[$i-1], $maxchar[1], $modifier),
                        _octets(2, $minchar[2], $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(1, $char[$i-1], $maxchar[1], $modifier),
                        _octets(2, $minchar[2], $maxchar[2], $modifier),
                        _octets(3, $minchar[3], $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(1, $char[$i-1], $maxchar[1], $modifier),
                        _octets(2, $minchar[2], $maxchar[2], $modifier),
                        _octets(3, $minchar[3], $maxchar[3], $modifier),
                        _octets(4, $minchar[4], $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 2) {
                if (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(2, $char[$i-1], $maxchar[2], $modifier),
                        _octets(3, $minchar[3], $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(2, $char[$i-1], $maxchar[2], $modifier),
                        _octets(3, $minchar[3], $maxchar[3], $modifier),
                        _octets(4, $minchar[4], $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 3) {
                if (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(3, $char[$i-1], $maxchar[3], $modifier),
                        _octets(4, $minchar[4], $char[$i+1], $modifier);
                }
            }
            else {
                croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            $i += 2;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A [A-Za-z] \z/oxms) {
            if ($modifier =~ m/i/oxms) {
                push @singleoctet, CORE::uc $char[$i], CORE::lc $char[$i];
            }
            else {
                push @singleoctet, $char[$i];
            }
            $i += 1;
        }

        # single character of single octet code

        # \h \v
        #
        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        elsif ($char[$i] =~ m/\A (?: \\h ) \z/oxms) {
            push @singleoctet, "\t", "\x20";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: \\v ) \z/oxms) {
            push @singleoctet, "\f","\n","\r";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\s | \\w ) \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }

        # single character of multiple octet code
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (m/\A ([\x00-\x20\x7F-\xFF]) \z/oxms) {
            $_ = sprintf('\x%02X', CORE::ord $1);
        }
        elsif (m/\A [\x00-\xFF] \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@charlist) {
        if (m/\A (\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    return \@singleoctet, \@charlist;
}

#
# INFOMIX V6 ALS open character list for qr
#
sub charlist_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@singleoctet) == 0) {
    }
    elsif (scalar(@singleoctet) >= 2) {
        push @charlist, '[' . join('',@singleoctet) . ']';
    }
    elsif ($singleoctet[0] =~ m/ . - . /oxms) {
        push @charlist, '[' . $singleoctet[0] . ']';
    }
    else {
        push @charlist, $singleoctet[0];
    }
    if (scalar(@charlist) >= 2) {
        return '(?:' . join('|', @charlist) . ')';
    }
    else {
        return $charlist[0];
    }
}

#
# INFOMIX V6 ALS open character list for not qr
#
sub charlist_not_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@charlist) >= 1) {
        if (scalar(@singleoctet) >= 1) {

            # any character other than multiple octet and single octet character class
            return '(?!' . join('|', @charlist) . ')(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character other than multiple octet character class
            return '(?!' . join('|', @charlist) . ")(?:$your_char)";
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {

            # any character other than single octet character class
            return                                 '(?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character
            return                                 "(?:$your_char)";
        }
    }
}

#
# INFOMIX V6 ALS order to character (with parameter)
#
sub Einfomixv6als::chr(;$) {

    my $c = @_ ? $_[0] : $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# INFOMIX V6 ALS order to character (without parameter)
#
sub Einfomixv6als::chr_() {

    my $c = $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# INFOMIX V6 ALS stacked file test expr
#
sub Einfomixv6als::filetest (@) {

    my $file     = pop @_;
    my $filetest = substr(pop @_, 1);

    unless (eval qq{Einfomixv6als::$filetest(\$file)}) {
        return '';
    }
    for my $filetest (reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# INFOMIX V6 ALS file test -r expr
#
sub Einfomixv6als::r(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -r (Einfomixv6als::r)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-r _,@_) : -r _;
    }

    # P.908 32.39. Symbol
    # in Chapter 32: Standard Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    # (and so on)

    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-r $fh,@_) : -r $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-r _,@_) : -r _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-r _,@_) : -r _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $r = -r $fh;
                close $fh;
                return wantarray ? ($r,@_) : $r;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -w expr
#
sub Einfomixv6als::w(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -w (Einfomixv6als::w)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-w $fh,@_) : -w $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-w _,@_) : -w _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_WRONLY|O_APPEND) {
                my $w = -w $fh;
                close $fh;
                return wantarray ? ($w,@_) : $w;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -x expr
#
sub Einfomixv6als::x(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -x (Einfomixv6als::x)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-x $fh,@_) : -x $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-x _,@_) : -x _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -o expr
#
sub Einfomixv6als::o(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -o (Einfomixv6als::o)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-o $fh,@_) : -o $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-o _,@_) : -o _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $o = -o $fh;
                close $fh;
                return wantarray ? ($o,@_) : $o;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -R expr
#
sub Einfomixv6als::R(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -R (Einfomixv6als::R)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-R $fh,@_) : -R $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-R _,@_) : -R _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $R = -R $fh;
                close $fh;
                return wantarray ? ($R,@_) : $R;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -W expr
#
sub Einfomixv6als::W(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -W (Einfomixv6als::W)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-W $fh,@_) : -W $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-W _,@_) : -W _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_WRONLY|O_APPEND) {
                my $W = -W $fh;
                close $fh;
                return wantarray ? ($W,@_) : $W;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -X expr
#
sub Einfomixv6als::X(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -X (Einfomixv6als::X)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-X $fh,@_) : -X $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-X _,@_) : -X _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -O expr
#
sub Einfomixv6als::O(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -O (Einfomixv6als::O)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-O $fh,@_) : -O $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-O _,@_) : -O _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $O = -O $fh;
                close $fh;
                return wantarray ? ($O,@_) : $O;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -e expr
#
sub Einfomixv6als::e(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -e (Einfomixv6als::e)' if @_ and not wantarray;

    my $fh = Symbol::qualify_to_ref $_;
    if ($_ eq '_') {
        return wantarray ? (-e _,@_) : -e _;
    }

    # return false if directory handle
    elsif (defined Einfomixv6als::telldir($fh)) {
        return wantarray ? ('',@_) : '';
    }

    # return true if file handle
    elsif (fileno $fh) {
        return wantarray ? (1,@_) : 1;
    }

    elsif (-e $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (1,@_) : 1;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $e = -e $fh;
                close $fh;
                return wantarray ? ($e,@_) : $e;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -z expr
#
sub Einfomixv6als::z(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -z (Einfomixv6als::z)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-z $fh,@_) : -z $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-z _,@_) : -z _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $z = -z $fh;
                close $fh;
                return wantarray ? ($z,@_) : $z;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -s expr
#
sub Einfomixv6als::s(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -s (Einfomixv6als::s)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-s $fh,@_) : -s $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-s _,@_) : -s _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $s = -s $fh;
                close $fh;
                return wantarray ? ($s,@_) : $s;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -f expr
#
sub Einfomixv6als::f(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -f (Einfomixv6als::f)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-f $fh,@_) : -f $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? ('',@_) : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $f = -f $fh;
                close $fh;
                return wantarray ? ($f,@_) : $f;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -d expr
#
sub Einfomixv6als::d(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -d (Einfomixv6als::d)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-d _,@_) : -d _;
    }

    # return false if file handle or directory handle
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif (-e $_) {
        return wantarray ? (-d _,@_) : -d _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return wantarray ? (-d "$_/.",@_) : -d "$_/.";
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -l expr
#
sub Einfomixv6als::l(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -l (Einfomixv6als::l)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-l $fh,@_) : -l $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-l _,@_) : -l _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $l = -l $fh;
                close $fh;
                return wantarray ? ($l,@_) : $l;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -p expr
#
sub Einfomixv6als::p(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -p (Einfomixv6als::p)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-p $fh,@_) : -p $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-p _,@_) : -p _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $p = -p $fh;
                close $fh;
                return wantarray ? ($p,@_) : $p;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -S expr
#
sub Einfomixv6als::S(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -S (Einfomixv6als::S)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-S $fh,@_) : -S $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-S _,@_) : -S _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $S = -S $fh;
                close $fh;
                return wantarray ? ($S,@_) : $S;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -b expr
#
sub Einfomixv6als::b(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -b (Einfomixv6als::b)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-b $fh,@_) : -b $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-b _,@_) : -b _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $b = -b $fh;
                close $fh;
                return wantarray ? ($b,@_) : $b;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -c expr
#
sub Einfomixv6als::c(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -c (Einfomixv6als::c)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-c $fh,@_) : -c $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-c _,@_) : -c _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $c = -c $fh;
                close $fh;
                return wantarray ? ($c,@_) : $c;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -t expr
#
sub Einfomixv6als::t(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -t (Einfomixv6als::t)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-t _,@_) : -t _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-t $fh,@_) : -t $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-t _,@_) : -t _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? ('',@_) : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                close $fh;
                my $t = -t $fh;
                return wantarray ? ($t,@_) : $t;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -u expr
#
sub Einfomixv6als::u(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -u (Einfomixv6als::u)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-u $fh,@_) : -u $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-u _,@_) : -u _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $u = -u $fh;
                close $fh;
                return wantarray ? ($u,@_) : $u;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -g expr
#
sub Einfomixv6als::g(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -g (Einfomixv6als::g)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-g $fh,@_) : -g $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-g _,@_) : -g _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $g = -g $fh;
                close $fh;
                return wantarray ? ($g,@_) : $g;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -k expr
#
sub Einfomixv6als::k(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -k (Einfomixv6als::k)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-k _,@_) : -k _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-k $fh,@_) : -k $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-k _,@_) : -k _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-k _,@_) : -k _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $k = -k $fh;
                close $fh;
                return wantarray ? ($k,@_) : $k;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -T expr
#
sub Einfomixv6als::T(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -T (Einfomixv6als::T)' if @_ and not wantarray;
    my $T = 1;

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {

        if (defined Einfomixv6als::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        # P.813 29.2.176. tell
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.
        # (and so on)

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {

            # P.163 Binary file check in Little Perl Parlor 16
            # of Book No. T1008901080816 ZASSHI 08901-8 UNIX MAGAZINE 1993 Aug VOL8#8
            # (and so on)

            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }

        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = Symbol::gensym();
        unless (sysopen $fh, $_, O_RDONLY) {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }
        close $fh;
    }

    my $dummy_for_underline_cache = -T $fh;
    return wantarray ? ($T,@_) : $T;
}

#
# INFOMIX V6 ALS file test -B expr
#
sub Einfomixv6als::B(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -B (Einfomixv6als::B)' if @_ and not wantarray;
    my $B = '';

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {

        if (defined Einfomixv6als::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }

        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = Symbol::gensym();
        unless (sysopen $fh, $_, O_RDONLY) {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }
        close $fh;
    }

    my $dummy_for_underline_cache = -B $fh;
    return wantarray ? ($B,@_) : $B;
}

#
# INFOMIX V6 ALS file test -M expr
#
sub Einfomixv6als::M(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -M (Einfomixv6als::M)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-M $fh,@_) : -M $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-M _,@_) : -M _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return wantarray ? ($M,@_) : $M;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -A expr
#
sub Einfomixv6als::A(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -A (Einfomixv6als::A)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-A $fh,@_) : -A $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-A _,@_) : -A _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return wantarray ? ($A,@_) : $A;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS file test -C expr
#
sub Einfomixv6als::C(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -C (Einfomixv6als::C)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-C $fh,@_) : -C $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-C _,@_) : -C _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return wantarray ? ($C,@_) : $C;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# INFOMIX V6 ALS stacked file test $_
#
sub Einfomixv6als::filetest_ (@) {

    my $filetest = substr(pop @_, 1);

    unless (eval qq{Einfomixv6als::${filetest}_}) {
        return '';
    }
    for my $filetest (reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# INFOMIX V6 ALS file test -r $_
#
sub Einfomixv6als::r_() {

    if (-e $_) {
        return -r _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -r _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $r = -r $fh;
                close $fh;
                return $r ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -w $_
#
sub Einfomixv6als::w_() {

    if (-e $_) {
        return -w _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -w _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_WRONLY|O_APPEND) {
                my $w = -w $fh;
                close $fh;
                return $w ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -x $_
#
sub Einfomixv6als::x_() {

    if (-e $_) {
        return -x _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -x _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -o $_
#
sub Einfomixv6als::o_() {

    if (-e $_) {
        return -o _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -o _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $o = -o $fh;
                close $fh;
                return $o ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -R $_
#
sub Einfomixv6als::R_() {

    if (-e $_) {
        return -R _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -R _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $R = -R $fh;
                close $fh;
                return $R ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -W $_
#
sub Einfomixv6als::W_() {

    if (-e $_) {
        return -W _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -W _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_WRONLY|O_APPEND) {
                my $W = -W $fh;
                close $fh;
                return $W ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -X $_
#
sub Einfomixv6als::X_() {

    if (-e $_) {
        return -X _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -X _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -O $_
#
sub Einfomixv6als::O_() {

    if (-e $_) {
        return -O _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -O _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $O = -O $fh;
                close $fh;
                return $O ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -e $_
#
sub Einfomixv6als::e_() {

    if (-e $_) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return 1;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $e = -e $fh;
                close $fh;
                return $e ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -z $_
#
sub Einfomixv6als::z_() {

    if (-e $_) {
        return -z _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -z _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $z = -z $fh;
                close $fh;
                return $z ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -s $_
#
sub Einfomixv6als::s_() {

    if (-e $_) {
        return -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -s _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $s = -s $fh;
                close $fh;
                return $s;
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -f $_
#
sub Einfomixv6als::f_() {

    if (-e $_) {
        return -f _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $f = -f $fh;
                close $fh;
                return $f ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -d $_
#
sub Einfomixv6als::d_() {

    if (-e $_) {
        return -d _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return -d "$_/." ? 1 : '';
    }
    return;
}

#
# INFOMIX V6 ALS file test -l $_
#
sub Einfomixv6als::l_() {

    if (-e $_) {
        return -l _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -l _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $l = -l $fh;
                close $fh;
                return $l ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -p $_
#
sub Einfomixv6als::p_() {

    if (-e $_) {
        return -p _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -p _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $p = -p $fh;
                close $fh;
                return $p ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -S $_
#
sub Einfomixv6als::S_() {

    if (-e $_) {
        return -S _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -S _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $S = -S $fh;
                close $fh;
                return $S ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -b $_
#
sub Einfomixv6als::b_() {

    if (-e $_) {
        return -b _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -b _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $b = -b $fh;
                close $fh;
                return $b ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -c $_
#
sub Einfomixv6als::c_() {

    if (-e $_) {
        return -c _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -c _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $c = -c $fh;
                close $fh;
                return $c ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -t $_
#
sub Einfomixv6als::t_() {

    return -t STDIN ? 1 : '';
}

#
# INFOMIX V6 ALS file test -u $_
#
sub Einfomixv6als::u_() {

    if (-e $_) {
        return -u _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -u _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $u = -u $fh;
                close $fh;
                return $u ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -g $_
#
sub Einfomixv6als::g_() {

    if (-e $_) {
        return -g _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -g _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $g = -g $fh;
                close $fh;
                return $g ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -k $_
#
sub Einfomixv6als::k_() {

    if (-e $_) {
        return -k _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -k _ ? 1 : '';
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my $k = -k $fh;
                close $fh;
                return $k ? 1 : '';
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -T $_
#
sub Einfomixv6als::T_() {

    my $T = 1;

    if (-d $_ or -d "$_/.") {
        return;
    }
    my $fh = Symbol::gensym();
    unless (sysopen $fh, $_, O_RDONLY) {
        return;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $T = '';
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $T = '';
        }
    }

    # 0 byte or eof
    else {
        $T = 1;
    }
    close $fh;

    my $dummy_for_underline_cache = -T $fh;
    return $T;
}

#
# INFOMIX V6 ALS file test -B $_
#
sub Einfomixv6als::B_() {

    my $B = '';

    if (-d $_ or -d "$_/.") {
        return;
    }
    my $fh = Symbol::gensym();
    unless (sysopen $fh, $_, O_RDONLY) {
        return;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $B = 1;
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $B = 1;
        }
    }

    # 0 byte or eof
    else {
        $B = 1;
    }
    close $fh;

    my $dummy_for_underline_cache = -B $fh;
    return $B;
}

#
# INFOMIX V6 ALS file test -M $_
#
sub Einfomixv6als::M_() {

    if (-e $_) {
        return -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -M _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return $M;
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -A $_
#
sub Einfomixv6als::A_() {

    if (-e $_) {
        return -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -A _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return $A;
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS file test -C $_
#
sub Einfomixv6als::C_() {

    if (-e $_) {
        return -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -C _;
        }
        else {
            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return $C;
            }
        }
    }
    return;
}

#
# INFOMIX V6 ALS path globbing (with parameter)
#
sub Einfomixv6als::glob($) {

    return _dosglob(@_);
}

#
# INFOMIX V6 ALS path globbing (without parameter)
#
sub Einfomixv6als::glob_() {

    return _dosglob();
}

#
# INFOMIX V6 ALS path globbing from File::DosGlob module
#
my %iter;
my %entries;
sub _dosglob {

    # context (keyed by second cxix argument provided by core)
    my($expr,$cxix) = @_;

    # glob without args defaults to $_
    $expr = $_ if not defined $expr;

    # represents the current user's home directory
    #
    # 7.3. Expanding Tildes in Filenames
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
    #
    # and File::HomeDir::Windows module

    # DOS like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $expr =~ s{ \A ~ (?= [^/\\] ) }
                  { $ENV{'HOME'} || $ENV{'USERPROFILE'} || "$ENV{'HOMEDRIVE'}$ENV{'HOMEPATH'}" }oxmse;
    }

    # UNIX like system
    else {
        $expr =~ s{ \A ~ ( (?:\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^/])* ) }
                  { $1 ? (getpwnam($1))[7] : ($ENV{'HOME'} || $ENV{'LOGDIR'} || (getpwuid($<))[7]) }oxmse;
    }

    # assume global context if not provided one
    $cxix = '_G_' if not defined $cxix;
    $iter{$cxix} = 0 if not exists $iter{$cxix};

    # if we're just beginning, do it all first
    if ($iter{$cxix} == 0) {
        $entries{$cxix} = [ _do_glob(1, _parse_line($expr)) ];
    }

    # chuck it all out, quick or slow
    if (wantarray) {
        delete $iter{$cxix};
        return @{delete $entries{$cxix}};
    }
    else {
        if ($iter{$cxix} = scalar @{$entries{$cxix}}) {
            return shift @{$entries{$cxix}};
        }
        else {
            # return undef for EOL
            delete $iter{$cxix};
            delete $entries{$cxix};
            return undef;
        }
    }
}

#
# INFOMIX V6 ALS path globbing subroutine
#
sub _do_glob {

    my($cond,@expr) = @_;
    my @glob = ();

OUTER:
    for my $expr (@expr) {
        next OUTER if not defined $expr;
        next OUTER if $expr eq '';

        my @matched = ();
        my @globdir = ();
        my $head    = '.';
        my $pathsep = '/';
        my $tail;

        # if argument is within quotes strip em and do no globbing
        if ($expr =~ m/\A " ((?:$q_char)*) " \z/oxms) {
            $expr = $1;
            if ($cond eq 'd') {
                if (Einfomixv6als::d $expr) {
                    push @glob, $expr;
                }
            }
            else {
                if (Einfomixv6als::e $expr) {
                    push @glob, $expr;
                }
            }
            next OUTER;
        }

        # wildcards with a drive prefix such as h:*.pm must be changed
        # to h:./*.pm to expand correctly
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            $expr =~ s# \A ((?:[A-Za-z]:)?) (\xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^/\\]) #$1./$2#oxms;
        }

        if (($head, $tail) = _parse_path($expr,$pathsep)) {
            if ($tail eq '') {
                push @glob, $expr;
                next OUTER;
            }
            if ($head =~ m/ \A (?:$q_char)*? [*?] /oxms) {
                if (@globdir = _do_glob('d', $head)) {
                    push @glob, _do_glob($cond, map {"$_$pathsep$tail"} @globdir);
                    next OUTER;
                }
            }
            if ($head eq '' or $head =~ m/\A [A-Za-z]: \z/oxms) {
                $head .= $pathsep;
            }
            $expr = $tail;
        }

        # If file component has no wildcards, we can avoid opendir
        if ($expr !~ m/ \A (?:$q_char)*? [*?] /oxms) {
            if ($head eq '.') {
                $head = '';
            }
            if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
                $head .= $pathsep;
            }
            $head .= $expr;
            if ($cond eq 'd') {
                if (Einfomixv6als::d $head) {
                    push @glob, $head;
                }
            }
            else {
                if (Einfomixv6als::e $head) {
                    push @glob, $head;
                }
            }
            next OUTER;
        }
        Einfomixv6als::opendir(*DIR, $head) or next OUTER;
        my @leaf = readdir DIR;
        closedir DIR;

        if ($head eq '.') {
            $head = '';
        }
        if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
            $head .= $pathsep;
        }

        my $pattern = '';
        while ($expr =~ m/ \G ($q_char) /oxgc) {
            $pattern .= {
                '*' => "(?:$your_char)*",
                '?' => "(?:$your_char)?",  # DOS style
            #   '?' => "(?:$your_char)",   # UNIX style
                'a' => 'A',
                'b' => 'B',
                'c' => 'C',
                'd' => 'D',
                'e' => 'E',
                'f' => 'F',
                'g' => 'G',
                'h' => 'H',
                'i' => 'I',
                'j' => 'J',
                'k' => 'K',
                'l' => 'L',
                'm' => 'M',
                'n' => 'N',
                'o' => 'O',
                'p' => 'P',
                'q' => 'Q',
                'r' => 'R',
                's' => 'S',
                't' => 'T',
                'u' => 'U',
                'v' => 'V',
                'w' => 'W',
                'x' => 'X',
                'y' => 'Y',
                'z' => 'Z',
            }->{$1} || quotemeta $1;
        }
        my $matchsub = sub { Einfomixv6als::uc($_[0]) =~ m{\A $pattern \z}xms };

#       if ($@) {
#           print STDERR "$0: $@\n";
#           next OUTER;
#       }

INNER:
        for my $leaf (@leaf) {
            if ($leaf eq '.' or $leaf eq '..') {
                next INNER;
            }
            if ($cond eq 'd' and not Einfomixv6als::d "$head$leaf") {
                next INNER;
            }

            if (&$matchsub($leaf)) {
                push @matched, "$head$leaf";
                next INNER;
            }

            # [DOS compatibility special case]
            # Failed, add a trailing dot and try again, but only...

            if (Einfomixv6als::index($leaf,'.') == -1 and   # if name does not have a dot in it *and*
                CORE::length($leaf) <= 8 and        # name is shorter than or equal to 8 chars *and*
                Einfomixv6als::index($pattern,'\\.') != -1  # pattern has a dot.
            ) {
                if (&$matchsub("$leaf.")) {
                    push @matched, "$head$leaf";
                    next INNER;
                }
            }
        }
        if (@matched) {
            push @glob, @matched;
        }
    }
    return @glob;
}

#
# INFOMIX V6 ALS parse line
#
sub _parse_line {

    my($line) = @_;

    $line .= ' ';
    my @piece = ();
    while ($line =~ m{
        " ( (?: \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^"]   )*  ) " \s+ |
          ( (?: \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^"\s] )*  )   \s+
        }oxmsg
    ) {
        push @piece, defined($1) ? $1 : $2;
    }
    return @piece;
}

#
# INFOMIX V6 ALS parse path
#
sub _parse_path {

    my($path,$pathsep) = @_;

    $path .= '/';
    my @subpath = ();
    while ($path =~ m{
        ((?: \xFD[\xA1-\xFE][\xA1-\xFE]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^/\\] )+?) [/\\] }oxmsg
    ) {
        push @subpath, $1;
    }

    my $tail = pop @subpath;
    my $head = join $pathsep, @subpath;
    return $head, $tail;
}

#
# INFOMIX V6 ALS file lstat (with parameter)
#
sub Einfomixv6als::lstat(*) {

    local $_ = shift if @_;

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::lstat $fh;
    }
    elsif (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = Symbol::gensym();
        if (sysopen $fh, $_, O_RDONLY) {
            my @lstat = CORE::lstat $fh;
            close $fh;
            return @lstat;
        }
    }
    return;
}

#
# INFOMIX V6 ALS file lstat (without parameter)
#
sub Einfomixv6als::lstat_() {

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::lstat $fh;
    }
    elsif (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = Symbol::gensym();
        if (sysopen $fh, $_, O_RDONLY) {
            my @lstat = CORE::lstat $fh;
            close $fh;
            return @lstat;
        }
    }
    return;
}

#
# INFOMIX V6 ALS path opendir
#
sub Einfomixv6als::opendir(*$) {

    # 7.6. Writing a Subroutine That Takes Filehandles as Built-ins Do
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.

    my $dh = Symbol::qualify_to_ref $_[0];
    if (CORE::opendir $dh, $_[1]) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_[1])) {
        if (CORE::opendir $dh, "$_[1]/.") {
            return 1;
        }
    }
    return;
}

#
# INFOMIX V6 ALS file stat (with parameter)
#
sub Einfomixv6als::stat(*) {

    local $_ = shift if @_;

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = Symbol::gensym();
        if (sysopen $fh, $_, O_RDONLY) {
            my @stat = CORE::stat $fh;
            close $fh;
            return @stat;
        }
    }
    return;
}

#
# INFOMIX V6 ALS file stat (without parameter)
#
sub Einfomixv6als::stat_() {

    my $fh = Symbol::qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = Symbol::gensym();
        if (sysopen $fh, $_, O_RDONLY) {
            my @stat = CORE::stat $fh;
            close $fh;
            return @stat;
        }
    }
    return;
}

#
# INFOMIX V6 ALS path unlink
#
sub Einfomixv6als::unlink(@) {

    local @_ = ($_) unless @_;

    my $unlink = 0;
    for (@_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (_MSWin32_5Cended_path($_)) {
            my @char = m/\G ($q_char) /oxmsg;
            my $file = join '', map {{'/' => '\\'}->{$_} || $_} @char;
            if ($file =~ m/ \A (?:$q_char)*? [ ] /oxms) {
                $file = qq{"$file"};
            }

            # P.565 23.1.2. Cleaning Up Your Environment
            # in Chapter 23: Security
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.
            # (and so on)

            # local $ENV{'PATH'} = '.';
            local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

            system qq{del $file >NUL 2>NUL};

            my $fh = Symbol::gensym();
            if (sysopen $fh, $_, O_RDONLY) {
                close $fh;
            }
            else {
                $unlink++;
            }
        }
    }
    return $unlink;
}

#
# INFOMIX V6 ALS chdir
#
sub Einfomixv6als::chdir(;$) {

    my($dir) = @_;

    if (not defined $dir) {
        $dir = ($ENV{'HOME'} || $ENV{'USERPROFILE'} || "$ENV{'HOMEDRIVE'}$ENV{'HOMEPATH'}");
    }

    if (_MSWin32_5Cended_path($dir)) {
        if (not Einfomixv6als::d $dir) {
            return 0;
        }

        if ($] =~ /^5\.005/) {
            return CORE::chdir $dir;
        }
        elsif ($] =~ /^5\.006/) {
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path)";
        }
        elsif ($] =~ /^5\.008/) {
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path)";
        }
        elsif ($] =~ /^5\.010/) {
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path)";
        }
        else {
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path)";
        }
    }
    else {
        return CORE::chdir $dir;
    }
}

#
# INFOMIX V6 ALS chr(0x5C) ended path on MSWin32
#
sub _MSWin32_5Cended_path {

    if ((@_ >= 1) and ($_[0] ne '')) {
        if ($^O =~ m/\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            my @char = $_[0] =~ /\G ($q_char) /oxmsg;
            if ($char[-1] =~ m/ \x5C \z/oxms) {
                return 1;
            }
        }
    }
    return;
}

#
# do INFOMIX V6 ALS file
#
sub Einfomixv6als::do($) {

    my($filename) = @_;

    my $realfilename;
    my $result;
ITER_DO:
    {
        for my $prefix (@INC) {
            $realfilename = "$prefix/$filename";
            if (Einfomixv6als::f($realfilename)) {

                my $script = '';

                my $e_mtime      = (Einfomixv6als::stat("$realfilename.e"))[9];
                my $mtime        = (Einfomixv6als::stat($realfilename))[9];
                my $module_mtime = (Einfomixv6als::stat("$FindBin::Bin/INFOMIXV6ALS.pm"))[9];
                if (Einfomixv6als::e("$realfilename.e") and ($mtime < $e_mtime) and ($module_mtime < $e_mtime)) {
                    my $fh = Symbol::gensym();
                    sysopen $fh, "$realfilename.e", O_RDONLY;
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close $fh;
                }
                else {
                    my $fh = Symbol::gensym();
                    sysopen $fh, $realfilename, O_RDONLY;
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close $fh;

                    if ($script =~ m/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $/oxms) {
                        CORE::require INFOMIXV6ALS;
                        $script = INFOMIXV6ALS::escape_script($script);
                        my $fh = Symbol::gensym();
                        sysopen $fh, "$realfilename.e", O_WRONLY | O_TRUNC | O_CREAT;
                        print {$fh} $script;
                        close $fh;
                    }
                }

                no strict;
                local $^W = $_warning;
                local $@;
                $result = eval $script;

                last ITER_DO;
            }
        }
    }
    $INC{$filename} = $realfilename;
    return $result;
}

#
# require INFOMIX V6 ALS file
#

# require
# in Chapter 3: Functions
# of ISBN 1-56592-149-6 Programming Perl, Second Edition.

sub Einfomixv6als::require(;$) {

    local $_ = shift if @_;
    return 1 if $INC{$_};

    # jcode.pl
    # ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

    # jacode.pl
    # http://search.cpan.org/dist/jacode/

    if (m{ \b (?: jcode\.pl | jacode\.pl) \z }oxms) {
        return CORE::require($_);
    }

    my $realfilename;
    my $result;
ITER_REQUIRE:
    {
        for my $prefix (@INC) {
            $realfilename = "$prefix/$_";
            if (Einfomixv6als::f($realfilename)) {

                my $script = '';

                my $e_mtime      = (Einfomixv6als::stat("$realfilename.e"))[9];
                my $mtime        = (Einfomixv6als::stat($realfilename))[9];
                my $module_mtime = (Einfomixv6als::stat("$FindBin::Bin/INFOMIXV6ALS.pm"))[9];
                if (Einfomixv6als::e("$realfilename.e") and ($mtime < $e_mtime) and ($module_mtime < $e_mtime)) {
                    my $fh = Symbol::gensym();
                    sysopen($fh, "$realfilename.e", O_RDONLY) or croak "Can't open file: $realfilename.e";
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close($fh) or croak "Can't close file: $realfilename";
                }
                else {
                    my $fh = Symbol::gensym();
                    sysopen($fh, $realfilename, O_RDONLY) or croak "Can't open file: $realfilename";
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close($fh) or croak "Can't close file: $realfilename";

                    if ($script =~ m/^ \s* use \s+ INFOMIXV6ALS \s* ([^;]*) ; \s* \n? $/oxms) {
                        CORE::require INFOMIXV6ALS;
                        $script = INFOMIXV6ALS::escape_script($script);
                        my $fh = Symbol::gensym();
                        sysopen($fh, "$realfilename.e", O_WRONLY | O_TRUNC | O_CREAT) or croak "Can't open file: $realfilename.e";
                        print {$fh} $script;
                        close($fh) or croak "Can't close file: $realfilename";
                    }
                }

                no strict;
                local $^W = $_warning;
                $result = eval $script;

                last ITER_REQUIRE;
            }
        }
        croak "Can't find $_ in \@INC";
    }
    croak $@ if $@;
    croak "$_ did not return true value" unless $result;
    $INC{$_} = $realfilename;
    return $result;
}

#
# INFOMIX V6 ALS telldir avoid warning
#
sub Einfomixv6als::telldir(*) {

    local $^W = 0;

    return CORE::telldir $_[0];
}

#
# INFOMIX V6 ALS character to order (with parameter)
#
sub INFOMIXV6ALS::ord(;$) {

    local $_ = shift if @_;

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# INFOMIX V6 ALS character to order (without parameter)
#
sub INFOMIXV6ALS::ord_() {

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# INFOMIX V6 ALS reverse
#
sub INFOMIXV6ALS::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse(join('',@_) =~ m/\G ($q_char) /oxmsg);
    }
}

#
# INFOMIX V6 ALS length by character
#
sub INFOMIXV6ALS::length(;$) {

    local $_ = shift if @_;

    local @_ = m/\G ($q_char) /oxmsg;
    return scalar @_;
}

#
# INFOMIX V6 ALS substr by character
#
sub INFOMIXV6ALS::substr($$;$$) {

    my @char = $_[0] =~ m/\G ($q_char) /oxmsg;

    # substr($string,$offset,$length,$replacement)
    if (@_ == 4) {
        my(undef,$offset,$length,$replacement) = @_;
        my $substr = join '', splice(@char, $offset, $length, $replacement);
        $_[0] = join '', @char;
        return $substr;
    }

    # substr($string,$offset,$length)
    elsif (@_ == 3) {
        my(undef,$offset,$length) = @_;
        if ($length == 0) {
            return '';
        }
        if ($offset >= 0) {
            return join '', (@char[$offset            .. $#char])[0 .. $length-1];
        }
        else {
            return join '', (@char[($#char+$offset+1) .. $#char])[0 .. $length-1];
        }
    }

    # substr($string,$offset)
    else {
        my(undef,$offset) = @_;
        if ($offset >= 0) {
            return join '', @char[$offset            .. $#char];
        }
        else {
            return join '', @char[($#char+$offset+1) .. $#char];
        }
    }
}

#
# INFOMIX V6 ALS index by character
#
sub INFOMIXV6ALS::index($$;$) {

    my $index;
    if (@_ == 3) {
        $index = Einfomixv6als::index($_[0], $_[1], CORE::length(INFOMIXV6ALS::substr($_[0], 0, $_[2])));
    }
    else {
        $index = Einfomixv6als::index($_[0], $_[1]);
    }

    if ($index == -1) {
        return -1;
    }
    else {
        return INFOMIXV6ALS::length(CORE::substr $_[0], 0, $index);
    }
}

#
# INFOMIX V6 ALS rindex by character
#
sub INFOMIXV6ALS::rindex($$;$) {

    my $rindex;
    if (@_ == 3) {
        $rindex = Einfomixv6als::rindex($_[0], $_[1], CORE::length(INFOMIXV6ALS::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = Einfomixv6als::rindex($_[0], $_[1]);
    }

    if ($rindex == -1) {
        return -1;
    }
    else {
        return INFOMIXV6ALS::length(CORE::substr $_[0], 0, $rindex);
    }
}

# pop warning
$^W = $_warning;

1;

__END__

=pod

=head1 NAME

Einfomixv6als - Run-time routines for INFOMIXV6ALS.pm

=head1 SYNOPSIS

  use Einfomixv6als;

    Einfomixv6als::split(...);
    Einfomixv6als::tr(...);
    Einfomixv6als::chop(...);
    Einfomixv6als::index(...);
    Einfomixv6als::rindex(...);
    Einfomixv6als::lc(...);
    Einfomixv6als::lc_;
    Einfomixv6als::uc(...);
    Einfomixv6als::uc_;
    Einfomixv6als::capture(...);
    Einfomixv6als::ignorecase(...);
    Einfomixv6als::chr(...);
    Einfomixv6als::chr_;
    Einfomixv6als::X ...;
    Einfomixv6als::X_;
    Einfomixv6als::glob(...);
    Einfomixv6als::glob_;
    Einfomixv6als::lstat(...);
    Einfomixv6als::lstat_;
    Einfomixv6als::opendir(...);
    Einfomixv6als::stat(...);
    Einfomixv6als::stat_;
    Einfomixv6als::unlink(...);
    Einfomixv6als::chdir(...);
    Einfomixv6als::do(...);
    Einfomixv6als::require(...);
    Einfomixv6als::telldir(...);

  # "no Einfomixv6als;" not supported

=head1 ABSTRACT

This module is a run-time routines of the INFOMIXV6ALS module.
Because the INFOMIXV6ALS module automatically uses this module, you need not use directly.

=head1 BUGS AND LIMITATIONS

Please patches and report problems to author are welcome.

=head1 HISTORY

This Einfomixv6als module first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 EXAMPLES

=over 4

=item Split string

  @split = Einfomixv6als::split(/pattern/,$string,$limit);
  @split = Einfomixv6als::split(/pattern/,$string);
  @split = Einfomixv6als::split(/pattern/);
  @split = Einfomixv6als::split('',$string,$limit);
  @split = Einfomixv6als::split('',$string);
  @split = Einfomixv6als::split('');
  @split = Einfomixv6als::split();
  @split = Einfomixv6als::split;

  Scans a INFOMIX V6 ALS $string for delimiters that match pattern and splits the INFOMIX V6 ALS
  $string into a list of substrings, returning the resulting list value in list
  context, or the count of substrings in scalar context. The delimiters are
  determined by repeated pattern matching, using the regular expression given in
  pattern, so the delimiters may be of any size and need not be the same INFOMIX V6 ALS
  $string on every match. If the pattern doesn't match at all, Einfomixv6als::split returns
  the original INFOMIX V6 ALS $string as a single substring. If it matches once, you get
  two substrings, and so on.
  If $limit is specified and is not negative, the function splits into no more than
  that many fields. If $limit is negative, it is treated as if an arbitrarily large
  $limit has been specified. If $limit is omitted, trailing null fields are stripped
  from the result (which potential users of pop would do well to remember).
  If INFOMIX V6 ALS $string is omitted, the function splits the $_ INFOMIX V6 ALS string.
  If $patten is also omitted, the function splits on whitespace, /\s+/, after
  skipping any leading whitespace.
  If the pattern contains parentheses, then the substring matched by each pair of
  parentheses is included in the resulting list, interspersed with the fields that
  are ordinarily returned.

=item Transliteration

  $tr = Einfomixv6als::tr($variable,$bind_operator,$searchlist,$replacementlist,$modifier);
  $tr = Einfomixv6als::tr($variable,$bind_operator,$searchlist,$replacementlist);

  This function scans a INFOMIX V6 ALS string character by character and replaces all
  occurrences of the characters found in $searchlist with the corresponding character
  in $replacementlist. It returns the number of characters replaced or deleted.
  If no INFOMIX V6 ALS string is specified via =~ operator, the $_ variable is translated.
  $modifier are:

  Modifier   Meaning
  ------------------------------------------------------
  c          Complement $searchlist
  d          Delete found but unreplaced characters
  s          Squash duplicate replaced characters
  ------------------------------------------------------

=item Chop string

  $chop = Einfomixv6als::chop(@list);
  $chop = Einfomixv6als::chop();
  $chop = Einfomixv6als::chop;

  Chops off the last character of a INFOMIX V6 ALS string contained in the variable (or
  INFOMIX V6 ALS strings in each element of a @list) and returns the character chopped.
  The Einfomixv6als::chop operator is used primarily to remove the newline from the end of
  an input record but is more efficient than s/\n$//. If no argument is given, the
  function chops the $_ variable.

=item Index string

  $pos = Einfomixv6als::index($string,$substr,$position);
  $pos = Einfomixv6als::index($string,$substr);

  Returns the position of the first occurrence of $substr in INFOMIX V6 ALS $string.
  The start, if specified, specifies the $position to start looking in the INFOMIX V6 ALS
  $string. Positions are integer numbers based at 0. If the substring is not found,
  the Einfomixv6als::index function returns -1.

=item Reverse index string

  $pos = Einfomixv6als::rindex($string,$substr,$position);
  $pos = Einfomixv6als::rindex($string,$substr);

  Works just like Einfomixv6als::index except that it returns the position of the last
  occurence of $substr in INFOMIX V6 ALS $string (a reverse index). The function returns
  -1 if not found. $position, if specified, is the rightmost position that may be
  returned, i.e., how far in the INFOMIX V6 ALS string the function can search.

=item Lower case string

  $lc = Einfomixv6als::lc($string);
  $lc = Einfomixv6als::lc_;

  Returns a lowercase version of INFOMIX V6 ALS string (or $_, if omitted). This is the
  internal function implementing the \L escape in double-quoted strings.

=item Upper case string

  $uc = Einfomixv6als::uc($string);
  $uc = Einfomixv6als::uc_;

  Returns an uppercased version of INFOMIX V6 ALS string (or $_, if string is omitted).
  This is the internal function implementing the \U escape in double-quoted
  strings.

=item Make capture number

  $capturenumber = Einfomixv6als::capture($string);

  This function is internal use to m/ /i, s/ / /i, split and qr/ /i.

=item Make ignore case string

  @ignorecase = Einfomixv6als::ignorecase(@string);

  This function is internal use to m/ /i, s/ / /i, split and qr/ /i.

=item Make character

  $chr = Einfomixv6als::chr($code);
  $chr = Einfomixv6als::chr_;

  This function returns the character represented by that $code in the character
  set. For example, Einfomixv6als::chr(65) is "A" in either ASCII or INFOMIX V6 ALS, and
  Einfomixv6als::chr(0x82a0) is a INFOMIX V6 ALS HIRAGANA LETTER A. For the reverse of Einfomixv6als::chr,
  use INFOMIXV6ALS::ord.

=item File test operator -X

  A file test operator is an unary operator that tests a pathname or a filehandle.
  If $string is omitted, it uses $_ by function Einfomixv6als::r_.
  The following functions function when the pathname ends with chr(0x5C) on MSWin32.

  $test = Einfomixv6als::r $string;
  $test = Einfomixv6als::r_;

  Returns 1 when true case or '' when false case.
  Returns undef unless successful.

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Einfomixv6als::r(*), Einfomixv6als::r_()   File is readable by effective uid/gid
  Einfomixv6als::w(*), Einfomixv6als::w_()   File is writable by effective uid/gid
  Einfomixv6als::x(*), Einfomixv6als::x_()   File is executable by effective uid/gid
  Einfomixv6als::o(*), Einfomixv6als::o_()   File is owned by effective uid
  Einfomixv6als::R(*), Einfomixv6als::R_()   File is readable by real uid/gid
  Einfomixv6als::W(*), Einfomixv6als::W_()   File is writable by real uid/gid
  Einfomixv6als::X(*), Einfomixv6als::X_()   File is executable by real uid/gid
  Einfomixv6als::O(*), Einfomixv6als::O_()   File is owned by real uid
  Einfomixv6als::e(*), Einfomixv6als::e_()   File exists
  Einfomixv6als::z(*), Einfomixv6als::z_()   File has zero size
  Einfomixv6als::f(*), Einfomixv6als::f_()   File is a plain file
  Einfomixv6als::d(*), Einfomixv6als::d_()   File is a directory
  Einfomixv6als::l(*), Einfomixv6als::l_()   File is a symbolic link
  Einfomixv6als::p(*), Einfomixv6als::p_()   File is a named pipe (FIFO)
  Einfomixv6als::S(*), Einfomixv6als::S_()   File is a socket
  Einfomixv6als::b(*), Einfomixv6als::b_()   File is a block special file
  Einfomixv6als::c(*), Einfomixv6als::c_()   File is a character special file
  Einfomixv6als::t(*), Einfomixv6als::t_()   Filehandle is opened to a tty
  Einfomixv6als::u(*), Einfomixv6als::u_()   File has setuid bit set
  Einfomixv6als::g(*), Einfomixv6als::g_()   File has setgid bit set
  Einfomixv6als::k(*), Einfomixv6als::k_()   File has sticky bit set
  ------------------------------------------------------------------------------

  Returns 1 when true case or '' when false case.
  Returns undef unless successful.

  The Einfomixv6als::T, Einfomixv6als::T_, Einfomixv6als::B and Einfomixv6als::B_ work as follows. The first block
  or so of the file is examined for strange chatracters such as
  [\000-\007\013\016-\032\034-\037\377] (that don't look like INFOMIX V6 ALS). If more
  than 10% of the bytes appear to be strange, it's a *maybe* binary file;
  otherwise, it's a *maybe* text file. Also, any file containing ASCII NUL(\0) or
  \377 in the first block is considered a binary file. If Einfomixv6als::T or Einfomixv6als::B is
  used on a filehandle, the current input (standard I/O or "stdio") buffer is
  examined rather than the first block of the file. Both Einfomixv6als::T and Einfomixv6als::B
  return 1 as true on an empty file, or on a file at EOF (end-of-file) when testing
  a filehandle. Both Einfomixv6als::T and Einfomixv6als::B deosn't work when given the special
  filehandle consisting of a solitary underline.

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Einfomixv6als::T(*), Einfomixv6als::T_()   File is a text file
  Einfomixv6als::B(*), Einfomixv6als::B_()   File is a binary file (opposite of -T)
  ------------------------------------------------------------------------------

  Returns useful value if successful, or undef unless successful.

  $value = Einfomixv6als::s $string;
  $value = Einfomixv6als::s_;

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Einfomixv6als::s(*), Einfomixv6als::s_()   File has nonzero size (returns size)
  Einfomixv6als::M(*), Einfomixv6als::M_()   Age of file (at startup) in days since modification
  Einfomixv6als::A(*), Einfomixv6als::A_()   Age of file (at startup) in days since last access
  Einfomixv6als::C(*), Einfomixv6als::C_()   Age of file (at startup) in days since inode change
  ------------------------------------------------------------------------------

=item Filename expansion (globbing)

  @glob = Einfomixv6als::glob($string);
  @glob = Einfomixv6als::glob_;

  Performs filename expansion (DOS-like globbing) on $string, returning the next
  successive name on each call. If $string is omitted, $_ is globbed instead.
  This function function when the pathname ends with chr(0x5C) on MSWin32.

  For example, C<<..\\l*b\\file/*glob.p?>> will work as expected (in that it will
  find something like '..\lib\File/DosGlob.pm' alright). Note that all path
  components are case-insensitive, and that backslashes and forward slashes are
  both accepted, and preserved. You may have to double the backslashes if you are
  putting them in literally, due to double-quotish parsing of the pattern by perl.
  A tilde ("~") expands to the current user's home directory.

  Spaces in the argument delimit distinct patterns, so C<glob('*.exe *.dll')> globs
  all filenames that end in C<.exe> or C<.dll>. If you want to put in literal spaces
  in the glob pattern, you can escape them with either double quotes.
  e.g. C<glob('c:/"Program Files"/*/*.dll')>.

=item Statistics about link

  @lstat = Einfomixv6als::lstat($file);
  @lstat = Einfomixv6als::lstat_;

  Like Einfomixv6als::stat, returns information on file, except that if file is a symbolic
  link, Einfomixv6als::lstat returns information about the link; Einfomixv6als::stat returns
  information about the file pointed to by the link. (If symbolic links are
  unimplemented on your system, a normal Einfomixv6als::stat is done instead.) If file is
  omitted, returns information on file given in $_.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Open directory handle

  $rc = Einfomixv6als::opendir(DIR,$dir);

  Opens a directory for processing by readdir, telldir, seekdir, rewinddir and
  closedir. The function returns true if successful.
  This function function when the directory name ends with chr(0x5C) on MSWin32.

=item Statistics about file

  @stat = Einfomixv6als::stat($file);
  @stat = Einfomixv6als::stat_;

  Returns a 13-element list giving the statistics for a file, indicated by either
  a filehandle or an expression that gives its name. It's typically used as
  follows:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = Einfomixv6als::stat($file);

  Not all fields are supported on all filesystem types. Here are the meanings of
  the fields:

  Field     Meaning
  -----------------------------------------------------------------
  dev       Device number of filesystem
  ino       Inode number
  mode      File mode (type and permissions)
  nlink     Nunmer of (hard) links to the file
  uid       Numeric user ID of file's owner
  gid       Numeric group ID of file's owner
  rdev      The device identifier (special files only)
  size      Total size of file, in bytes
  atime     Last access time since the epoch
  mtime     Last modification time since the epoch
  ctime     Inode change time (not creation time!) since the epoch
  blksize   Preferred blocksize for file system I/O
  blocks    Actual number of blocks allocated
  -----------------------------------------------------------------

  $dev and $ino, token together, uniquely identify a file. The $blksize and
  $blocks are likely defined only on BSD-derived filesystem. The $blocks field
  (if defined) is reported in 512-byte blocks.
  If stat is passed the special filehandle consisting of an underline, no
  actual stat is done, but the current contents of the stat structure from the
  last stat or stat-based file test (the -x operators) is returned.
  If file is omitted, returns information on file given in $_.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Deletes a list of files.

  $unlink = Einfomixv6als::unlink(@list);
  $unlink = Einfomixv6als::unlink($file);
  $unlink = Einfomixv6als::unlink;

  Delete a list of files. (Under Unix, it will remove a link to a file, but the
  file may still exist if another link references it.) If list is omitted, it
  unlinks the file given in $_. The function returns the number of files
  successfully deleted.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Changes the working directory.

  $chdir = Einfomixv6als::chdir($dirname);
  $chdir = Einfomixv6als::chdir;

  Changes the working directory to $dirname, if possible. If $dirname is omitted,
  it changes to the home directory. The function returns 1 upon success, 0
  otherwise (and puts the error code into $!).

  This function can't function when the $dirname ends with chr(0x5C) on perl5.006,
  perl5.008, perl5.010 on MSWin32.

=item do file

  $return = Einfomixv6als::do($file);

  The do FILE form uses the value of FILE as a filename and executes the contents
  of the file as a Perl script. Its primary use is (or rather was) to include
  subroutines from a Perl subroutine library, so that:

  Einfomixv6als::do('stat.pl');

  is rather like: 

  scalar eval `cat stat.pl`;   # `type stat.pl` on Windows

  except that Einfomixv6als::do is more efficient, more concise, keeps track of the current
  filename for error messages, searches all the directories listed in the @INC
  array, and updates %INC if the file is found.
  It also differs in that code evaluated with Einfomixv6als::do FILE can not see lexicals in
  the enclosing scope, whereas code in eval FILE does. It's the same, however, in
  that it reparses the file every time you call it -- so you might not want to do
  this inside a loop unless the filename itself changes at each loop iteration.

  If Einfomixv6als::do can't read the file, it returns undef and sets $! to the error. If 
  Einfomixv6als::do can read the file but can't compile it, it returns undef and sets an
  error message in $@. If the file is successfully compiled, do returns the value of
  the last expression evaluated.

  Inclusion of library modules (which have a mandatory .pm suffix) is better done
  with the use and require operators, which also Einfomixv6als::do error checking and raise
  an exception if there's a problem. They also offer other benefits: they avoid
  duplicate loading, help with object-oriented programming, and provide hints to the
  compiler on function prototypes.

  But Einfomixv6als::do FILE is still useful for such things as reading program configuration
  files. Manual error checking can be done this way:

  # read in config files: system first, then user
  for $file ("/usr/share/proggie/defaults.rc", "$ENV{HOME}/.someprogrc") {
      unless ($return = Einfomixv6als::do($file)) {
          warn "couldn't parse $file: $@" if $@;
          warn "couldn't Einfomixv6als::do($file): $!" unless defined $return;
          warn "couldn't run $file"            unless $return;
      }
  }

  A long-running daemon could periodically examine the timestamp on its configuration
  file, and if the file has changed since it was last read in, the daemon could use
  Einfomixv6als::do to reload that file. This is more tidily accomplished with Einfomixv6als::do than
  with Einfomixv6als::require.

=item require file

  Einfomixv6als::require($file);
  Einfomixv6als::require();

  This function asserts a dependency of some kind on its argument. If an argument is not
  supplied, $_ is used.

  If the argument is a string, Einfomixv6als::require loads and executes the Perl code found in
  the separate file whose name is given by the string. This is similar to performing a
  Einfomixv6als::do on a file, except that Einfomixv6als::require checks to see whether the library
  file has been loaded already and raises an exception if any difficulties are
  encountered. (It can thus be used to express file dependencies without worrying about
  duplicate compilation.) Like its cousins Einfomixv6als::do and use, Einfomixv6als::require knows how
  to search the include path stored in the @INC array and to update %INC upon success.

  The file must return true as the last value to indicate successful execution of any
  initialization code, so it's customary to end such a file with 1; unless you're sure
  it'll return true otherwise.

  See also do file.

=item current position of the readdir

  Einfomixv6als::telldir(DIRHANDLE);

  This function returns the current position of the readdir routines on DIRHANDLE.
  This value may be given to seekdir to access a particular location in a directory.
  The function has the same caveats about possible directory compaction as the
  corresponding system library routine. This function might not be implemented
  everywhere that readdir is. Even if it is, no calculation may be done with the
  return value. It's just an opaque value, meaningful only to seekdir.

=back

=cut

