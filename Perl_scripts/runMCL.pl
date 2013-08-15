#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Carp;
use IO::File;

#########################################################
# perl script to run mcl for a given file for inflation values
# assuming that mcl is installed and available in $PATH
#########################################################

my %printHash;
my $input=$ARGV[0] or croak( "need *.mci as input!\n");
my $start= $ARGV[1] or croak( "need a starting value (usuallay 1.2)!\n");
my $end= $ARGV[2] or croak( "need an end value!\n");
my $workDir = &Cwd::cwd();

my $mclOut = $workDir.'/mcl.out';

runMCL();
getMCLstat();

sub runMCL{
	for(my $i=$start;$i<=$end;$i=$i+0.1){	
		system("mcl","$input","-I","$i");
	}
}

sub getMCLstat{
	
	opendir(MCIDIR,$workDir);
	my @allFiles=readdir(MCIDIR);
	closedir(MCIDIR);
	my @data;
	my $mciInfoInput="";
	my $out = IO::File->new($mclOut,"w") or croak ("cannot open $mclOut for writing !\n");
	foreach my $file(@allFiles){
		if($file=~/.*\.$input\.I\d+/){
			$mciInfoInput= $mciInfoInput.' '.$file;	
			my $input=`/home/sahadeva/bin/mcl-cluster/bin/clm info $input $file`;
#			print $input,"\n";
			push(@data,$input);
		}
	}
	foreach my $input(@data){
#		print $input;
		my @params = split(/\s{1,}/,$input);
		my $efficiency = $params[0];
		$efficiency=~s/efficiency\=//gi;
		my $massFrac = $params[1];
		$massFrac=~s/massfrac\=//gi;
		my $areaFrac = $params[2];
		$areaFrac=~s/areafrac\=//gi;
		my $source = $params[3];
		my $inflation= $params[3];
		my $cluster= $params[4];
		my $max= $params[5];
		$max=~s/max\=//gi;
		my $avg= $params[7];
		$avg=~s/avg\=//gi;
		my $min = $params[8];
		$min=~s/min\=//gi;
		$cluster=~s/clusters\=//gi;
		$inflation=~s/^.*I//gi;
		$printHash{$inflation}= "$massFrac\t$areaFrac\t$efficiency\t$cluster\t$max\t$avg\t$min\t$source";
	}
	$out->print("inflation\tmassFract\tareaFrac\tefficiency\tclusterNr.\tmaxSize\tavgSize\tminSize\tsource\n");
	foreach my $inflation(sort{$a<=>$b}keys %printHash ){
		my $trueInflation = $inflation/10;
		$out->print($trueInflation,"\t",$printHash{$inflation},"\n");
		$out->flush();
	}
	$out->close();
}





