#! perl6
use v6.d;
use HTTP::UserAgent;
use HTTP::Response:auth<github:sergot>;
use WWW;
use PDF::API6;
use PDF::Page;
use PDF::XObject::Image;
use PDF::Destination :Fit;
use Term::ProgressBar;
use File::Directory::Tree;

my %form =
	'aid'=> '11667321',
	'page_number'=> '1',
	'view_token'=>'222j6LDkh4uYHuZfTASJAp9YjT29JwGB';
my %headers = 'UserAgent' => 'Rakudo';
my Str $URL = 'https://max.book118.com/index.php?g=Home&m=Ajax&a=getPreviewData';
my %resp = jpost $URL, |%form;
my $bar = Term::ProgressBar.new(:style<\>>, count => %resp<page>.Int, :name<Downloading...>, width => 50, :p);

my Str $postfix = '';
say "[*] 下载页面...";
my Int $page_num = 0;
$bar.update($page_num++);
#loop (;$page_num < %resp<page>;) {
while True {
	spurt "run.log", %resp, :append;
	for %resp<data>.keys.sort: { $^b <= $^a} -> $key {
		%resp<data>{$key} ~~ /[.*\/]+.*\.(\w**3..4)/;
		my $img = get 'https:' ~ %resp<data>{$key};
		
		if ((Buf.new(0xff,0xd8) eq $img.subbuf(0,2)) && (Buf.new(0xff,0xd9) eq $img.subbuf(2))) {
			$postfix = "jpeg";
		} elsif ($img.subbuf(0,6) eq Buf.new(0x47,0x49,0x46,0x38,0x39,0x61)| Buf.new(0x47,0x49,0x46,0x38,0x37,0x61)) {
			$postfix = 'gif';
		} elsif ($img.subbuf(0,8) eq Buf.new(0x89,0x50,0x4E,0x47,0xD,0xA,0x1A,0x0A)) {
			$postfix = 'png';
		} else {
			$postfix = '';
		}

		if ($postfix) {
			spurt "book/{$key}.{$postfix}", get 'https:' ~ %resp<data>{$key};
			#	say "[+] book/{$key}.{$postfix}";
			#say "\n",$key,".",$postfix, " => https:" ~ %resp<data>{$key};
		} else {
			#say "[-] book/{$key}";
			spurt "error.log", "download https:" ~ %resp<data>{$key} ~ " failed!", :append;
		}
		$bar.update($page_num++);
	}
	last if $page_num >= %resp<page>.Int;
	%form<page_number> = $page_num.perl;
	%resp = jpost $URL, |%form;
}
say "[+] 下载完成";
#================================================================#
say "[*] 合成PDF";
$bar = Term::ProgressBar.new(:style<\>>, count => %resp<page>.Int, :name<Converting...>, width => 50, :p);
my PDF::API6 $pdf .= new();
$pdf.media-box = [0, 0, 792, 1120];
my PDF::Page $page;

loop (my $i = 0; $i < %resp<page>;) {
	$bar.update($i++);
	$pdf.add-page().graphics: {
		if ("book/$i.gif".IO ~~ :f) {
			.do((.load-image: "book/$i.gif"));
		} elsif ("book/$i.png".IO ~~ :f) {
			.do((.load-image: "book/$i.png"));
		} elsif ("book/$i.jpeg",IO ~~ :f) {
			.do((.load-image: "book/$i.jpeg"));
		} else {
			spurt "error.log", "Loadimage[$i] failed!", :append;
		}
	}
}
say "[+] 合成完成";
say "[*] 创建bookmarks...";
sub dest(|c) { :destination($pdf.destination(|c)) }
$pdf.outlines.kids = [
	%(:Title('一.初识gtest => 3'), dest(:page(3))),
	%(:Title('二.断言 => 9'), dest(:page(9))),
	%(:Title('三.事件机制 => 18'), dest(:page(18))),
	%(:Title('四.参数化 => 22'), dest(:page(22))),
	%(:Title('五.死亡测试 => 29'), dest(:page(29))),
	%(:Tilte('六.运行参数 => 35'), dest(:page(35))),
	%(:Title('七.深入解析gtest => 41'), dest(:page(41))),
	%(:Title('八.打造自己的单元测试框架 => 57'), dest(:page(57))),
];
say "[+] 创建完成";
say "[*] 保存中...";
$pdf.save-as: "GoogelTest.pdf";
say "[+] 已保存";
say "[*] 清除下载缓存";
say "[+] 已清除" if empty-directory "./book";
say "[===>] " ~ "/home/zero/文档/玩转Google开源C++单元测试框架GoogelTest.pdf";
