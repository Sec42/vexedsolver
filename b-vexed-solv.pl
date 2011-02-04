#!/usr/local/bin/perl
#
# vim:set ts=4 sw=4:

use strict;
use warnings;
use Data::Dumper;
use constant DEBUG => 0;
use constant LLOPT => 1;
$|=1;

my $file=shift;
my $lvl =shift;

open(my $lvlfile,"<",$file) ||die;

my $lvlno=0;
while(<$lvlfile>){
$lvlno++ if ($_ =~ /^\[Level\]/);
last if ($lvlno == $lvl);
}

my($board,$title);
while (<$lvlfile>){
	chomp;
	s/\r$//; # DOS/Win-Lineends
	$board=$1 if /^board=(\S+)/;
	$title=$1 if /^title=(.*)/;
	last if /^\[/;
};
close($lvlfile);

print "Level $lvlno is \"$title\"\n";

$board=~s/(\d+)/"#"x$&/ge; # Expand compression
my $emptyboard;
($emptyboard=$board)=~y!~a-z! !;

my @eboard;
my @oblocks;
my $line=0;
for (split(m!/!,$board)){
	for my $col (0..length($_)-1){
		$eboard[$line][$col]=0;
		if(substr($_,$col,1) eq "#"){
			$eboard[$line][$col]=1 
		}elsif(substr($_,$col,1) eq "~"){
			;;
		}else{
			push @oblocks,[$line,$col,substr($_,$col,1)]
		};
#		print substr($_,$col,1);
	}
#	print "\n";
	$line++;
};

sub pboard{
	my $blocks=shift;
	for my $line (0..$#eboard){
		my $eline=$eboard[$line];
COL:		for my $col (0..$#{$eline}){
			if ($eline->[$col]){
				print "#" ;
				next;
			};
			for (@$blocks){
				if ($line == $_->[0] && $col == $_->[1]){
					print $_->[2];
					next COL;
				};
			};
			print " ";
		};
		print "\n";
	};
	print "---\n";
};

sub hashboard{
	my $hash;
	my $b=shift;
	return join(";",map {join(",",@$_)} grep {!$_->[3]} @$b);
};

sub unhashboard{
	my $hash=shift;
	return [map {[split(",",$_)]}split(";",$hash)];
};

sub isempty{
	return 0 if $eboard[$_[0]][$_[1]];
	for (@{$_[2]}){
		return 0 if ($_->[0] == $_[0] && $_->[1] == $_[1]);
	};
	return 1;
};

#sub isempty{
#	my ($l,$c,$b)=@_;
#	return 0 if $eboard[$l][$c];
#	for (@$b){
#		return 0 if ($_->[0] == $l && $_->[1] == $c);
#	};
#	return 1;
#};

my %btdt;

my $move=0;
my @cboards;
push @cboards,hashboard(\@oblocks);
$btdt{hashboard(\@oblocks)}=1;

pboard \@oblocks;

my $lastline=$#eboard+1;
my $isfull=1;
do{
	$lastline--;
	for (0..$#{$eboard[$lastline]}){
		$isfull=0 if ! $eboard[$lastline][$_];
	};
}while ($isfull);

my $lastpeg=0;
$isfull=1;
for (0..$#{$eboard[$lastline]}){
	if(!$eboard[$lastline][$_]){
		$isfull=0;
	};
	if($isfull==0 && $eboard[$lastline][$_]){
		$lastpeg=$_;
		last;
	};
};


my $blocks;
my @nboards;
my %sources;
my $searching=1;

while($searching){
	@nboards=();
	%sources=();
	$move++;
	print "\nMove: $move - boards=$#cboards, btdt=",scalar keys (%btdt),"\n";
	for my $pos (@cboards){
		$blocks=unhashboard $pos;
#		pboard $blocks;
		for (@$blocks){
			my $oc=$_->[1];
			my $l =$_->[0];
			my $c;

			$c = $_->[1]+1;
			if (isempty($l,$c,$blocks)){
				$_->[1]=$c;
				my $hb=hashboard($blocks);
				push @nboards,$hb ;
				$sources{$hb}=$pos;
#				print "-> ",$hb,"\n";
				$_->[1]=$oc;
			};

			$c = $_->[1]-1;
			if (isempty($l,$c,$blocks)){
				$_->[1]=$c;
				my $hb=hashboard($blocks);
				push @nboards,$hb ;
				$sources{$hb}=$pos;
#				print "-> ",$hb,"\n";
				$_->[1]=$oc;
			};

		};
	};

#	print Dumper \@nboards;

	@cboards=();
	my $changed;
MAIN: for my $pos (@nboards){
		print "proc: $pos" if (DEBUG);
		next if($btdt{$pos});
		$blocks=unhashboard $pos;

#Sanitize: prune tree on invalid situations
		my %bcnt=();
		my %ll=();
		for (@$blocks){
			$bcnt{$_->[2]}++;
			if($_->[0]==$lastline){
				push @{$ll{$_->[2]}},$_->[1];
			};
		};
# 	Check more than 1 block of each existing type
		for(keys%bcnt){
			if($bcnt{$_} == 1){
				print "-> broke it\n" if(DEBUG);
				next MAIN;
			}elsif($bcnt{$_} >3){
				delete $ll{$_};
			};
		};
#	Abort if stones are "abab" or "a#a" in the bottom row.
		for (keys %ll){
			if ($#{$ll{$_}}<1){
				delete $ll{$_};
				next;
			};
			my($a,$b)=@{$ll{$_}};
			if($a<$lastpeg && $b>$lastpeg){
				print "-> broke it by peg\n" if(DEBUG);
				next MAIN;
			};
			if($b<$lastpeg && $a>$lastpeg){
				print "-> broke it by peg\n" if(DEBUG);
				next MAIN;
			};
		};
		if(1){
		# >2 is imprecise, ignores the rest
		if (scalar keys %ll >=2){
			my($a,$b)=(values %ll);
			my ($as,$ab)=($a->[0],$a->[1]);
			($as,$ab)=($ab,$as) if ($ab<$as);
			my ($bs,$bb)=($b->[0],$b->[1]);
			($bs,$bb)=($bb,$bs) if ($bb<$bs);
			if( ($as < $bs && $bs < $ab && $bb > $ab) ||
				($bs < $as && $as < $bb && $ab > $bb) ){
#				pboard $blocks;
				print "-> broke it by transposition\n" if(DEBUG);
				next MAIN;
			};
		};
		};


#Falling down...
		do{
			$changed=0;
			for my $no (0..$#$blocks){
				while(isempty($blocks->[$no][0]+1,$blocks->[$no][1],$blocks)){
					$blocks->[$no][0]++;
					$changed=1;
				};
			};
		}while($changed);

#Touching blocks
		for my $no (0..$#$blocks){
			my($l,$c,$t)=($blocks->[$no][0],$blocks->[$no][1],$blocks->[$no][2]);
			for my $no2 (0..$#$blocks){
				next if $no==$no2;
				my $t2=$blocks->[$no2][2];
				if($t eq $t2){
					my($l2,$c2)=($blocks->[$no2][0],$blocks->[$no2][1]);
					if ($l==$l2 && $c+1==$c2){
						$blocks->[$no2][3]=1;
						$blocks->[$no][3]=1;
						$changed=1;
					};
					if ($c==$c2 && $l+1==$l2){
						$blocks->[$no2][3]=1;
						$blocks->[$no][3]=1;
						$changed=1;
					};
				};
			};
		};

		print "-> $changed\n" if(DEBUG);

		my $hb=hashboard $blocks;
		if($btdt{$hb}){ # Had this already.
			next MAIN;
		};

		if($changed){
			push @nboards,$hb;
			$sources{$hb}=$sources{$pos};
			next MAIN;
		};

		push @cboards,$hb;
		if ($hb eq ""){
			print ">>> SOLUTION found <<<\n";
			$searching=0;
		};

		$btdt{$hb}=$sources{$pos};
		if($hb eq $sources{$pos}){
			$btdt{$hb}=42;
			print "42!\n";
		};
	};

#	print Dumper \@cboards;

#	print "Output:\n";
#	for(@cboards){ pboard unhashboard $_ };

};

#print Dumper \%btdt;
print "Reverse solution:\n";

my $rev="";
while($btdt{$rev} ne 1){
	print "From: ",$btdt{$rev}," #",(scalar (()=($btdt{$rev}=~/;/g))),"\n";
	$rev=$btdt{$rev};
	pboard unhashboard $rev;
};
print "(moves=$move)\n";
