import sys
from collections import defaultdict as d
from optparse import OptionParser, OptionGroup
import gzip
import os

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, "< put description here >")

#########################################################   CODE   #########################################################################

parser.add_option("--BLAST", dest="BL", help="Input file")
parser.add_option("--FASTA", dest="FA", help="Input file")
parser.add_option("--Folder", dest="FO",
                  help="Taxonomic level for folder name")
parser.add_option("--Filename", dest="FI",
                  help="Taxonomic level for file name")
parser.add_option(
    "--Remove", dest="RE", help="List of Taxa to remove, separated by a comma"
)
parser.add_option("--output", dest="OUT", help="Output file")

(options, args) = parser.parse_args()
parser.add_option_group(group)


def load_data(x):
    """ import data either from a gzipped or or uncrompessed file or from STDIN"""
    import gzip

    if x == "-":
        y = sys.stdin
    elif x.endswith(".gz"):
        y = gzip.open(x, "rt", encoding="latin-1")
    else:
        y = open(x, "r", encoding="latin-1")
    return y


RemList = options.RE.split(",")
BL = d(list)
OutH = d(str)
for l in load_data(options.BL):
    a = l.rstrip().split("\t")
    if "no taxonomy found" in l:
        continue
    if a[0] in BL:
        continue
    # get positions for Hierachies
    Tax = a[-1].split("|")
    NewTax = []
    for i in range(len(Tax)):
        if Tax[i] == "clade":
            NewTax.append("clade"+str(i))
        else:
            NewTax.append(Tax[i])
    TaxID = dict(zip(*[NewTax, range(len(Tax))]))

    if options.FO not in TaxID or options.FI not in TaxID:
        continue

    FO = a[-2].split("|")[TaxID[options.FO]]
    FI = a[-2].split("|")[TaxID[options.FI]]
    # print(FO, FI)
    Test = False
    for i in RemList:
        if i in l:
            Test = True
            break
    if Test:
        BL[a[0]] = "_".join(["remove", FO, FI])
        if "_".join(["remove", FO, FI]) not in OutH:
            if not os.path.exists(options.OUT+"/remove/"+FO):
                # Create a new directory because it does not exist
                os.makedirs(options.OUT+"/remove/"+FO)
            OutH["_".join(["remove", FO, FI])] = gzip.open(
                options.OUT+"/remove/"+FO+"/"+FI.replace(" ", "_")+".fa.gz", "wt")
    else:
        BL[a[0]] = "_".join(["keep", FO, FI])
        if "_".join(["keep", FO, FI]) not in OutH:
            if not os.path.exists(options.OUT+"/keep/"+FO):
                # Create a new directory because it does not exist
                os.makedirs(options.OUT+"/keep/"+FO)
            OutH["_".join(["keep", FO, FI])] = gzip.open(
                options.OUT+"/keep/"+FO+"/"+FI.replace(" ", "_")+".fa.gz", "wt")
if not os.path.exists(options.OUT+"/NoHit/"):
    os.makedirs(options.OUT+"/NoHit/")
OutH["NoHit"] = gzip.open(
    options.OUT+"/NoHit/NoHit.fa.gz", "wt")

for l in load_data(options.FA):
    if l.startswith(">"):
        ID = l.rstrip()[1:].split()[0]
        if ID not in BL:
            Type = "NoHit"
        else:
            Type = BL[ID]
        OutH[Type].write(l)
        continue
    OutH[Type].write(l)
