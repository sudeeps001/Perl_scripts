#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Carp;
use IO::File;
use Getopt::Long;

#########################################################
# perl script to run mcl for a given file for inflation values
# assuming that mcl is installed and available in $PATH
#########################################################

my $input;
my $start;
my $end;
my $loop;
# some inputs 
GetOptions('f=s'=>\$input,'b=f'=>\$start,'e=f'=>\$end,'l=i'=>\$loop);
unless(defined($input)){
	help_message();
}
unless(defined($start)){
	$start=1;
	warn "\t parameter -b was not defined, start inflation used: 1 (default)\n"
}
unless(defined($end)){
	$end = 3;
	warn "\t parameter -e was not defined, end inflation used: 3 (default)\n"
}
unless(defined($loop)){
	$loop = 10000;
	warn "\t parameter -l was not defined, number of loops 10000 (default)\n"
}

# run mcl for a given file for inflation values

my %printHash;

my $workDir = &Cwd::cwd();

my $mciFile="";

my $mclOut = $workDir.'/'.$input;
$mclOut=~s/\..*$/\.mcl\.out/gi;

if($input=~/^.*\.mci/gi){
	runMCL_mci();
}else{
	runMCL_abc();
}

getMCLstat();

################## SUB ROUTINES ###########################################

sub help_message{
	warn "\n\nError! run file mci/abc format not given!\n";
	warn "Call runMCL.pl -f input mci/abc -b begin inflation (optional, default 1) -e end inflation (optional, default 3) -l loop number (optional, default 10000)\n\n";
	die();
}

sub runMCL_mci{
	for(my $i=$start;$i<=$end;$i=$i+0.1){	
		system("mcl","$input","-I","$i");
	}
	$mciFile= $input;
}

sub runMCL_abc{
	my $mciFile= $input;
	my $tabFile = $input;
	$mciFile=~s/\..*$/\.mci/gi;
	$tabFile=~s/\..*$/\.tab/gi;
	system("mcxload","-abc","$input","--stream-mirror",
	"-write-tab","$tabFile","-o","$mciFile");
	warn "\t files $mciFile and $tabFile genrated in current working directory\n\n";
	$input=$mciFile;
	for(my $i=$start;$i<=$end;$i=$i+0.1){	
		system("mcl","$input","-I","$i","-l","$loop");
	}
#	if running mcl with abc file clm needs .mci for generating statistics
	
	
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
			my $input=`clm info $input $file`;
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





