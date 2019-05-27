#! /usr/local/share/rakudo-2019.03/bin/perl6
use v6.d;
use File::Directory::Tree;

# Temporary storage directory after downloading from githubs
my $outdir = '/opt/'; 

# the url of modules from github
my Str @URLS;
my Bool $DELETE = False;
for @*ARGS {
	if ($_.path.f) {
		# if it is a file
		@URLS.append: (slurp $_).lines;
	} else {
		# this is may be a url str
		@URLS.push($_.Str);
	}
}

my $reg = /https\:\/\/github\.com\/([\w|\-]+\/)+([\w|\-]+)/; 

install $_ for @URLS; 

(delete $_ for @URLS ) if $DELETE ;

sub delete ($url) {
	if ($url ~~ $reg) {
		if (rmtree $outdir ~ $1) {
			say "[+] delete " ~ $outdir ~ $1 ~ "success.";
			return False;
		} else {
			say "[-] delete " ~ $outdir ~ $1 ~ "failed!";
		}
	}
	True;
}

sub install ($url) {
	if ($url ~~ $reg) {
		my @files.push($_.Str) for dir($outdir);
		my $execpath = $outdir ~ $1;
		
		if ($execpath  ∈  @files) {
			say "[*] zef reinstall $1";
			if (shell("zef install " ~ $execpath)) {
			    say "[+] zef reinstall $1 success!";
			}else {
			    say "[-] zef reinstall $1 failed!";
			    exit -1;
			}
			return True;
		}

		my $command = 'git clone ' ~ "$url" ~ " $execpath";
		if (shell($command)) { # download form github
			# zef install 
			$command = "zef install " ~ $execpath ;
			if (shell($command)) {
				say "[+] zef install $1 success!";
			} else {
				say "[-] zef install $1 failed!" ;
				exit -1;
			}
		} else {
			say "[-] Download $url failed!";
			exit -1;
		}
	} else {
		if ( $url ~~ /'-''d'/ ) {
			$DELETE = True;
			return True;
		} else {
			say "[-] Url illegal !";
			return False;
		}
	}
	True;
}
