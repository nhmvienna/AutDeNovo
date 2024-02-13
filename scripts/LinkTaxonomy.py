import sys
from optparse import OptionParser, OptionGroup

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, '< put description here >')

#########################################################   CODE   #########################################################################

parser.add_option("--Tax", dest="Tax", help="NCBI node dmp file")
parser.add_option("--Names", dest="Names", help="NCBI names dmp file")
parser.add_option("--BLAST", dest="BLAST",
                  help="BLAST output file with SeqID in column1 and TaxID in column2")
parser.add_option("--output", dest="OUT", help="Output file")

(options, args) = parser.parse_args()
parser.add_option_group(group)


def load_data(x):
    ''' import data either from a gzipped or or uncrompessed file or from STDIN'''
    import gzip
    if x == "-":
        y = sys.stdin
    elif x.endswith(".gz"):
        y = gzip.open(x, "rt", encoding="latin-1")
    else:
        y = open(x, "r", encoding="latin-1")
    return y


def taxon_trace(node):
    rank = []
    name_path = []

    while True:
        rank.append(rank_dict[node])
        name_path.append(names.get(node, ""))

        if node == '1':
            break

        if node in parents:
            node = parents[node]
        else:
            sys.exit(f"{node}\tSomething may be wrong!")

    return "|".join(reversed(rank)), "|".join(reversed(name_path))


parents = {}
rank_dict = {}
names = {}

with load_data(options.Tax) as node:
    for line in node:
        its = [x.replace("\t", "") for x in line.rstrip().split("|")]
        parents[its[0]] = its[1]
        rank_dict[its[0]] = its[2]

with load_data(options.Names) as name:
    for line in name:
        its = [x.replace("\t", "") for x in line.rstrip().split("|")]
        if "scientific name" in line:
            names[its[0]] = its[1]

with load_data(options.BLAST) as taxid, open(options.OUT, 'wt') as export:
    for line in taxid:
        seqId, taxId = line.rstrip().split("\t")[:2]

        if taxId not in names:
            export.write("no taxonomy found\n")
            continue

        node_path, name_path = taxon_trace(taxId)
        export.write(f"{seqId}\t{names[taxId]}\t{name_path}\t{node_path}\n")

sys.exit()
