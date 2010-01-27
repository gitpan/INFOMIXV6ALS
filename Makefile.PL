use strict;
use Fcntl;
use Symbol;

# make make.bat
my $fh_makebat = Symbol::gensym();
sysopen($fh_makebat, 'make.bat', O_WRONLY | O_TRUNC | O_CREAT) || die "Can't open file: make.bat\n";
print {$fh_makebat} <DATA>;
close $fh_makebat;

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor make

undef @rem;
use strict;
use Fcntl;
use Symbol;
use File::Path;
use File::Copy;
use File::Basename;
use Test::Harness;
use Archive::Tar;
use Compress::Zlib;

unless (@ARGV) {
    die <<END;

usage: make
usage: make test
usage: make install
usage: make dist
usage: make tar.bat

END
}

# get file list
my $fh_manifest = Symbol::gensym();
sysopen($fh_manifest, 'MANIFEST', O_RDONLY) || die "Can't open file: MANIFEST\n";
chomp(my @file = <$fh_manifest>);
close $fh_manifest;

for my $target (@ARGV) {
    if ($target eq 'test') {
        my @test = grep m{ \A (?: test\.pl | t/.+\.t ) \z }xmsi, @file;
        runtests(@test);
    }
    elsif ($target eq 'install') {

        # install *.pm files to /Perl/site/lib
        my($perl_site_lib) = grep(m{/site/}xmsi, @INC);
        for (grep m/ \. pm \z /xmsi, @file) {
            if (m#^(.+)/#) {
                print STDERR "copy $_ $perl_site_lib/$1\n";
                mkpath("$perl_site_lib/$1", 0, 0777) unless -d "$perl_site_lib/$1";
                copy($_, "$perl_site_lib/$1");
            }
            else {
                print STDERR "copy $_ $perl_site_lib\n";
                copy($_, $perl_site_lib);
            }
        }

        # install *.pl, *.bat, *.exe and *.com files to /Perl/bin
        my($perl_bin) = $^X =~ /^(.*)\\[^\\]*$/;
        for (grep m/ \. (?: pl | bat | exe | com ) \z /xmsi, @file) {
            next if m/(?: Makefile | test ) \.pl  $/xmsi;
            next if m/(?: make | tar )      \.bat $/xmsi;
            if (m#^(.+)/#) {
                print STDERR "copy $_ $perl_bin/$1\n";
                mkpath("$perl_site_lib/$1", 0, 0777) unless -d "$perl_site_lib/$1";
                copy($_, "$perl_bin/$1");
            }
            else {
                print STDERR "copy $_ $perl_bin\n";
                copy($_, $perl_bin);
            }
        }
    }
    elsif ($target eq 'dist') {

        # make work directory
        my($changes) = grep(/^Changes$/i,@file);
        my $fh_changes = Symbol::gensym();
        sysopen($fh_changes, $changes, O_RDONLY) || die "Can't open file: $changes\n";
        my $version = 0;
        while (<$fh_changes>) {
            if (/^(\d+\.\d+(\.\d+\.\d+)*)/) {
                if ($1 > $version) {
                    $version = $1;
                }
            }
        }
        close $fh_changes;
        my $dirname  = dirname($file[0]);
        my $basename = basename($file[0], '.pm','.pl','.bat');
        my $tardir;
        if ($dirname ne '.') {
            $dirname =~ tr#/#-#;
            $tardir = "$dirname-$basename-$version";
        }
        else {
            $tardir = "$basename-$version";
        }
        rmtree($tardir,0,0);

        # rewrite META.yml file
        if(my($metayml) = grep(/^META\.yml$/i,@file)) {
            my $fh_metayml = Symbol::gensym();
            if (sysopen($fh_metayml, $metayml, O_RDONLY)) {
                $_ = join('',<$fh_metayml>);
                close $fh_metayml;
                my $fh_metayml = Symbol::gensym();
                if (sysopen($fh_metayml, $metayml, O_WRONLY | O_TRUNC | O_CREAT)) {
                    s/^(version:\s*)\d+\.\d+(\.\d+\.\d+)*/$1$version/m;
                    binmode $fh_metayml;
                    print {$fh_metayml} $_;
                    close $fh_metayml;
                }
            }
        }

        # make *.tar file
        my $tar = Archive::Tar->new;
        for my $file (@file) {
            if (-e $file) {
                mkpath(dirname("$tardir/$file"), 0, 0777);
                print STDERR "copy $file $tardir/$file\n";
                copy($file, "$tardir/$file");

#-----------------------------------------------------------------------------
# Sunday December 21, 2008 07:38 PM 
# Fixing world writable files in tarball before upload to CPAN [ #38127 ]
# http://use.perl.org/~bart/journal/38127
#-----------------------------------------------------------------------------
#               $tar->add_files("$tardir/$file");
#-----------------------------------------------------------------------------
                my $fh = Symbol::gensym();
                sysopen($fh, $file, O_RDONLY) || die "Can't open file: $file\n";
                binmode $fh;
                local $/ = undef; # slurp mode
                my $data = <$fh>;
                close $fh;
                if ($file =~ m/\. (com|exe|bat|pl) \z/oxmsi) {
                    $tar->add_data("$tardir/$file", $data, {'mode' => 0775});
                }
                else {
                    $tar->add_data("$tardir/$file", $data, {'mode' => 0664});
                }
#-----------------------------------------------------------------------------
            }
            else {
                die "file: $file is not exists.\n";
            }
        }

        my $tarfile = "$tardir.tar";
        $tar->write($tarfile);
        rmtree($tardir,0,0);

        # make *.tar.gz file
        my $gz = gzopen("$tarfile.gz", 'wb');
        my $fh_tar = Symbol::gensym();
        sysopen($fh_tar, $tarfile, O_RDONLY) || die "Can't open file: $tarfile\n";
        binmode $fh_tar;
        $gz->gzwrite(join('',<$fh_tar>));
        close $fh_tar;
        $gz->gzclose;
        unlink $tarfile;

        # P.565 Cleaning Up Your Environment
        # in Chapter 23: Security
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # local $ENV{'PATH'} = '.';
        local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

        # untar test
        system("make.bat tar.bat");
        system("tar.bat xzvf $tarfile.gz");
    }
    elsif ($target eq 'tar.bat') {

        # make tar.bat
        my $fh_tarbat = Symbol::gensym();
        sysopen($fh_tarbat, 'tar.bat', O_WRONLY | O_TRUNC | O_CREAT) || die "Can't open file: tar.bat\n";
        print {$fh_tarbat} <DATA>;
        close $fh_tarbat;
    }
    else {
        warn "unknown target: $target.\n";
    }
}

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor tar

undef @rem;
use strict;
use Fcntl;
use Symbol;
use Compress::Zlib;
use Archive::Tar;

if ($ARGV[0] ne 'xzvf') {
    die <<END;

usage: tar xzvf file1.tar.gz file2.tar.gz ...

** This tar supports xzvf option only. **
END
}

for my $gzfile (grep m/\.tar\.gz$/xmsi, @ARGV) {

    my $gz = gzopen($gzfile, 'rb');
    (my $tarfile = $gzfile) =~ s/\.gz$//xmsi;
    my $fh_tar = Symbol::gensym();
    sysopen($fh_tar, $tarfile, O_WRONLY | O_TRUNC | O_CREAT) || die "Can't open file: $tarfile\n";
    binmode $fh_tar;
    while ($gz->gzreadline(my $line)) {
        print {$fh_tar} $line;
    }
    $gz->gzclose;
    close $fh_tar;

    my $tar = Archive::Tar->new($tarfile,1);
    for my $file ($tar->list_files){
        if (-e $file) {
            print STDERR "skip $file is already exists.\n";
        }
        else {
            print STDERR "x $file\n";
            $tar->extract($file);
        }
    }
    unlink $tarfile;
}

__END__
:endofperl
