import sys
import numpy as np
import networkx
import networkx as nx
from networkx.algorithms.components.connected import connected_components

### this is a little older code, but I am proud of it
### sets up the argument (file to be target)
### forces a file be referenced to run the script
### example of blast command to run to generate approprate file : blast -query query.faa -db genome.faa -outfmt "6 qseqid sseqid pident length" -out result_file.tab

if len(sys.argv) < 4:
    print( "Usage: python " + sys.argv[0] + "fasta file, blastn_format_6.tab file, percent identity threshold, and length threshold needed")
    sys.exit(0)

### identifies file name, strips extension

fasta_file = sys.argv[1]
fasta_file_no_ext = fasta_file.rsplit('.', 1)[0]

blast_results = sys.argv[2]
blast_results_no_ext = blast_results.rsplit('.', 1)[0]

pident_threshold = (sys.argv[3])
pident_float_threshold = float(pident_threshold)

length_threshold = (sys.argv[4])
length_float_threshold = float(length_threshold)

### create fasta dictionary
fasta_dict = {}


f=open(fasta_file,'r')
lines=f.readlines()
f.close()

number_of_reads = 0

for line in lines:
    if line.startswith(">"):
        read_id = line.strip().split(" ")[0]
        fasta_dict[read_id] = ''
        number_of_reads = number_of_reads + 1
    else:
        sequence = fasta_dict[read_id] + line.strip()
        fasta_dict[read_id] = sequence

print "Number of initial contigs: " + str(number_of_reads)

#print fasta_dict


### reads through blast results file
### makes a dictionary with the key as the query_id and the value as the subject_id
### if a key blasts to multilpe reads, those subject_ids will be appended to the values of the dictionary
### filters the blast results based on a pident and length threshold

query_reads_dict= {}

f=open(blast_results,'r')
lines=f.readlines()
f.close()

for line in lines:
    query_read_id = line.strip().split("\t")[0]
    subject_read_id = line.strip().split("\t")[1]
    fields = line.strip().split("\t")[2]
    length = int(line.strip().split("\t")[3])
    if float(fields) >= pident_float_threshold and float(length) >= length_float_threshold:
        try:
            query_reads_dict[query_read_id].append(subject_read_id)
        except KeyError:
            query_reads_dict[query_read_id] = [subject_read_id]


### this gives the number of query_ids before getting rid of clusters
print "Number of contigs after threshold filtering: " + str(len(query_reads_dict))


### this step is the cluster reduction
### numpy unique returns only the unique elements of a list, so the reads that map to each other will be greatly reduced

complete_list = []



for y in query_reads_dict.keys():
    v= query_reads_dict[y]
    v.sort()
    complete_list.append(v)


#Ppython program to check if two
# to get unique values from list
# using numpy.unique

import numpy as np


new_list = []

new_list = np.unique(complete_list)



print "Number of unique contig clusters: " + str(len(new_list))


### graph - node algorithm
def to_graph(a):
    G = networkx.Graph()
    for part in a:
        # each sublist is a bunch of nodes
        G.add_nodes_from(part)
        # it also imlies a number of edges:
        G.add_edges_from(to_edges(part))
    return G

def to_edges(a):
    """
        treat `l` as a Graph and returns it's edges
        to_edges(['a','b','c','d']) -> [(a,b), (b,c),(c,d)]
        """
    it = iter(a)
    last = next(it)
    
    for current in it:
        yield last, current
        last = current



G = to_graph(new_list)
'''
fileOut = open("Graph_cluster.txt", 'w')
print >>fileOut, list(connected_components(G))
fileOut.close()
'''

print "Number of unique cluster nodes: " + str(len(list(connected_components(G))))



gene_number = 0

j=open(fasta_file_no_ext + "_" + pident_threshold + "_" + length_threshold + "_collapsed_reads.fa", 'w')


for cluster in list(connected_components(G)):
    gene_number = gene_number + 1
    longest_length = 0
    longest_id = ''
    for x in cluster:
        y = ">" + x.strip()
        if  int(longest_length) < int(len(fasta_dict[y])):
            longest_length = len(fasta_dict[y])
            longest_id = y
    try:
        j.write( y + ("\n"))
        j.write(fasta_dict[y] + ("\n"))
    except KeyError:
        pass

j.close()






'''
for cluster in new_list:
    gene_number = gene_number + 1
    for x in cluster:
        y = ">" + x.strip()
        try:
            j.write(">gene_" + str(gene_number) + "\t" + str(len(fasta_dict[y]))+ "\t" + x + ("\n"))
        #j.write(fasta_dict[y] + ("\n"))
        except KeyError:
            pass

j.close()

test = 0

for cluster in new_list:
    test = test + 1
    longest_length = 0
    longest_id = ''
    for x in cluster:
        y = ">" + x.strip()
        if  int(longest_length) < int(len(fasta_dict[y])):
            longest_length = len(fasta_dict[y])
            longest_id = y
    print test, longest_id, longest_length

'''
