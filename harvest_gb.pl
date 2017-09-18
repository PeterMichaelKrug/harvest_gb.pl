#!/usr/bin/perl -w
use strict;
use Bio::DB::EUtilities;
############time
my $time=time;
print $time,"\a\n";
#exit;
####get @ARGV
my $ACCfile;                            		#inputfile for Accessions
                          				#string with the genename
my $fasout="genesout.fas"; unlink $fasout;              #string with outfilename from get_genes...
my $namefile="taxon.txt"; unlink $namefile;
if (@ARGV) {
    $ACCfile=$ARGV[0];
    
}else{say $!}
########## to do: get other parameters for EUtilities via command line or template

open(ACC,"<","$ACCfile") or die $!;

my ($genereq,@rest)=(<ACC>);
chomp $genereq;
$genereq=~s/gene\s//,;
print "\n**********",$genereq,"**********\n";
close ACC;
my $outfile=$genereq.".fas"; #unlink $outfile;

open(OUT,">>","$outfile") or die $!;
#get ids from accessions

 
open(ACC,"<","$ACCfile") or die $!;
my $accession;
while (<ACC>) {
    
    if (/gene\s.+/i) {
       next;
    }

        my $id = $_;
        my $factory = Bio::DB::EUtilities->new(-eutil   => 'efetch',
                                               -db      => 'nucleotide',
                                               -id      => $id,
                                               -email   => 'mkrug@uni-bonn.de',
                                               -rettype => 'gi');
 
        my $gid = $factory->get_Response->content;
        print $gid, "\n";
AGAIN:
    print "getting $_.....\n";
    $accession=$_;
    chomp $accession;
    my $syscall="perl get_genes_by_geneID.pl $_";
    
    my $syscall2="perl get_names_by_geneID.pl $_";
    my $syssucc=`$syscall`;     #system $syscall;
    print "\n****$syssucc****\n";
    if ($syssucc=~/Service Temporarily Unavailable/is) {
        goto AGAIN;
    }elsif($syssucc=~/ALERT/is){
        goto AGAIN;
    }
    
sleep 2;
    
    my $syssucc2=`$syscall2`;     #system $syscall2;
    print "\n****$syssucc2****\n";
    if ($syssucc=~/Service Temporarily Unavailable/is) {
        goto AGAIN;
    }elsif($syssucc=~/ALERT/is){
        goto AGAIN;
    }
sleep 2;
    open(NAME,"<",$namefile) or die $!;
    my $lineage;
    my $taxname;
    while (<NAME>) {
        #print"\n**********",$_,"*************\n";
        #<GBSeq_organism>Herbertus sakurai</GBSeq_organism>
        if (/\<GBSeq_organism\>(.+)\<\/GBSeq_organism\>/i) {
            $taxname=$1;
            chomp $taxname;
            print "Taxon is \t\t\t",$taxname;
        }  
        if (/\<GBSeq_taxonomy\>(.+)\<\/GBSeq_taxonomy\>/i) {
            $lineage=$1;
            chomp $lineage;
            $lineage =~ s/\;//g;
            print "\ntaxonomic lineage:\t\t\t",$lineage;
        }
        
    }
    close NAME;
    
    print OUT ">gi|123456|gb|$accession| ",$taxname," $lineage\n";
    print "\nopening $fasout \n";
    open(FAS, "<", "$fasout") or die $!;
        my $switch=0;
    while (<FAS>) {
        if ($switch) {
                if (/^[ATCG]/i) {
                 print OUT;
                 print;
                }
            }
        if (/^\>/) {
            if (/$genereq/i) {
                $switch=1;
                
            }else{
                $switch=0;
            }#print $switch;
        }
    }
    close FAS;
}
close ACC;
my $duration=time-$time;
print "\n\nI am ready, time in seconds: $duration\n
        printed to $outfile\n
        Have a nice day!\a";
