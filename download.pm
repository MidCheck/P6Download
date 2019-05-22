#! /usr/local/share/rakudo-2019.03/bin/perl6
use v6.d;

# Temporary storage directory after downloading from githubs
my $outdir = '/opt/'; 

# the url of modules from github
my @URLS = 
	"https://github.com/retupmoca/P6-Digest-HMAC",
	"https://github.com/perl6-community-modules/URI-Encode",
	"https://github.com/Leont/yamlish",
	"https://github.com/zostay/perl6-IO-Glob",
	"https://github.com/leont/path-iterator",
	"https://github.com/zostay/HTTP-Supply",
	"https://github.com/jnthn/p6-http-hpack",
	"https://github.com/jsimonet/log-any",
	"https://github.com/ufobat/HTTP-Server-Ogre",
	"https://github.com/tokuhirom/p6-HTTP-MultiPartParser",
	"https://github.com/Bailador/Bailador"
;

my $reg = /https\:\/\/github\.com\/([\w|\-]+\/)+([\w|\-]+)/; 

install $_ for @URLS; 


sub get_url($module_name){
	
}

sub delete ($url) {
	
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
			return 0;
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
		say "[-] Url illegal !";
		return -1;
	}
	return 0;
}
