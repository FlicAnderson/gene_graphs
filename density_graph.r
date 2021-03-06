###Plotting ribosome density to individual gene transcripts 

##This script will  generate plots representing ribosome density on individual transcripts with the aim of representing AUG and non-AUG translation initiation events in eukaryotic genes. It will include bits of code from generate_stats_figs.R and read_count_functions.R.

##loading libraries 
suppressMessages(library(Rsamtools))
suppressMessages(library(rtracklayer))
suppressMessages(library(rhdf5))
suppressMessages(library(parallel)) #not sure if required
suppressMessages(library(optparse)) #not sure if required 
suppressMessages(library(RcppRoll))
suppressMessages(library(ggplot2))
suppressMessages(library(tidyr))
suppressMessages(library(dplyr))
suppressMessages(library(magrittr))
suppressMessages(library(purrr))

##input 
 
#use either GFF or H5 data containing ribosome footprint  mapped to differnet positions on the transcript

##output

#The code is expected to output a figure (using ggplot) with NT position on the x-axis and ribosome footprint density on the y-axis. The canonical and alternative start codons should be clearly identified on the figure. This script will only include code required to plot ribosome footprints without identifying translation initiation sites. It's the first step towards the final goal.

##steps

#1.read the data file
#2.find and plot position specific distribution of reads on transcripts.

###script

##
test_orfs<- c("YCR012W","YEL009C","YOR303W","YOL130W","YGR094W")
#test_genes <- c("PGK1","GCN4","CPA1","ALR1","VAS1") 
min_read_length <- 10
max_read_length <- 50
orf_gff_file <- "Input/yeast_CDS_w_250utrs.gff3"
orf_fasta_file <- "Input/yeast_CDS_w_250utrs.fa"
setwd("/Users/Ania/Desktop/Szkoła/4th\ year/Dissertation/gene_graphs/")  
hd_file <- "Input/WTnone.h5"
source("read_count_functions.R")
asite_disp_length_file <-"Input/asite_disp_length_yeast_standard.txt"
dataset <- "G-Sc_2014"

## functions
GetCDS5start <- function(name, gffdf, ftype="CDS", fstrand="+") {
  gffdf %>% 
    dplyr::filter(type==ftype, Name == name, strand == fstrand) %>% 
    dplyr::pull(start) %>%  # pull() pulls out single variable
    min 
}

##

hdf5file <- rhdf5::H5Fopen(hd_file)

gene_names <- rhdf5::h5ls(hdf5file, recursive = 1)$name

coding_seqs <- readDNAStringSet(orf_fasta_file)

read_range <- min_read_length:max_read_length

gff_df <- readGFFAsDf(orf_gff_file)

##
asite_disp_length <- readr::read_tsv(asite_disp_length_file,
                                     comment = "#"
)


reads_per_codon_etc <- tibble(gene=gene_names) %>%
  filter( gene_names %in% test_orfs) %>%
  mutate(CountPerCodon = map(gene, ~GetGeneCodonPosReads1dsnap(
    .,
    dataset,
    hdf5file,
    left = GetCDS5start(., gff_df),
    right = GetCDS3end(., gff_df),
    min_read_length = min_read_length,
    asite_disp_length = asite_disp_length,
  ) ),
  NormCtperCodon = map(CountPerCodon, ~NormByMean(.) ),
  SumAsiteCt = map(CountPerCodon,~sum(.)) %>% unlist,
  LengthCodons = map(CountPerCodon,~length(.)) %>% unlist
  )
