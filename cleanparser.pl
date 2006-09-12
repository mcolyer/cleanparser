#!/usr/bin/perl

#Print Info
print "HTML Parser V1.0\n";
print "Written by: Matthew Colyer\n";

#Read Input
my $BaseDir = @ARGV[0];

#Validate Input
# BaseDir ends with a /
$chipedChar = chop($BaseDir);
if ($chipedChar eq "/"){ # makes sure that the ending character is a /
	$BaseDir = $BaseDir . '/';
}else{
	$BaseDir = join('',$BaseDir,$chipedChar, '/');
}

#Find the Files to be parsed
print $BaseDir."\n";
foreach $file (GetFileList($BaseDir)){
	ParseFile($file,$BaseDir);
}


#GetFile Sub -- Recursively generates a list of files 
# based on the postfixes passed in the second parameter

sub GetFileList {
	my $BaseDir = shift(@_);
	#my $FilePostFixes = shift(@_);
	my @FilesToParse;
	
	#Read in the list of Files
	opendir(dirOpened,$BaseDir) or die "No such Directory!";
	my @ListOfFiles = readdir(dirOpened);
	
	#remove . and ..	
	shift(@ListOfFiles); 
	shift(@ListOfFiles);
	
	#loop through the list and verify and build new list
	foreach $file (@ListOfFiles) {
		# First Case Dirs
		if (-d $BaseDir.$file){
			push(@FilesToParse,GetFileList($BaseDir.$file."/"));
		}
		# Second Case Suitable File
		if (substr($file,-4) eq "html" || substr($file, -3) eq "htm" || substr($file, -3) eq "php"){
			push(@FilesToParse, $BaseDir.$file);	
		}
	}
	return @FilesToParse;
}

# GetSNPFileList -- checks to see if there is a snp dir under the base dir
# if so the program continues and finds all .snp files located in it
# NOt RECURSIVE, only one dir
sub GetSNPFileList {
	my $BaseDir = shift(@_);
	my @SNPFiles;
	
	opendir(dirOpened,$BaseDir."snp") or die "No SNP Directory!";
	my @ListOfFiles = readdir(dirOpened);
	
	#remove . and ..	
	shift(@ListOfFiles); 
	shift(@ListOfFiles);

	#loop through, verify and build new list
	foreach $file (@ListOfFiles) {
		#first case suitable file
		if (substr($file,-3) eq "snp"){
			push(@SNPFiles, substr($file,0,length($file)-4));	
		}
	}
	return @SNPFiles;
}
# GetSNP returns the contents of the SNP Name given, the second parameter is the base dir
sub GetSNP {
	my $SNPName = shift(@_);
	my $BaseDir = shift(@_);
	
	open(SNPfile, $BaseDir."snp/".$SNPName.".snp") or die "No such file";
	#print $BaseDir."snp/".$file.".snp";
	my @openedFile = <SNPfile>;
	close SNPFile;
	my $total;
	foreach $line (@openedFile){
			$total = $total.$line;
	}
	return $total;
}

#ParseString -- parsers through the string and replaces the data between the snp tags
sub ParseString {
	my $DataString = shift(@_);
	my $BaseDir = shift(@_);
	my $FileName = shift(@_);
	
	#Get a list of SNPFiles
	my @listOfSnpFiles = GetSNPFileList($BaseDir);

	#Set state to 0
	my $isSnp =0;
	
	#Set search String
	$_ = $DataString;
	
	#regexp
	if ( /(<!--SNP:)(.*?)(-->)/ ) {
		foreach $snp (@listOfSnpFiles){
			#check to see if it's valid
			if ($snp eq $2){
				$isSnp = 1;
			}
		}
		#make more understandable...
		my $BeforeTagString = $`;
		my $SNPName = $2;
		
		if ($isSnp == 1){
			if ( (/(<!--\/SNP:)(.*)(-->)/)){
				my $AfterTagString = $';
				return join('',$BeforeTagString,"<!--SNP:",$SNPName,"-->\n",GetSNP($SNPName,$BaseDir),"\n<!--/SNP:",$SNPName,"-->",ParseString($AfterTagString,$BaseDir,$FileName));
			}else{
				die "No Close Tag in ".$FileName;
			}
		}else{
			die "No such ".$2." SNP in ".$FileName;
		}
	}else{
		#if there are no tags return it
		return $DataString;
	}
}
sub ParseFile{
	my $FileName = shift(@_);
	my $BaseDir = shift(@_);
	
	my $file;
	
	open (openedFile,$FileName) or die "Failed to open file";
	my @TempLines = <openedFile>;
	close openedFile;
	foreach $line (@TempLines){
			$file = $file.$line;
	}
	$file = ParseString($file,$BaseDir,$FileName);
	open (outFile,"> ".$FileName) or die "Failed to open file";
	print outFile $file;
	close outFile;
	print $FileName."\n";
}
