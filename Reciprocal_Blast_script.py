import sys
import re

file1 = sys.argv[1]
file1_no_ext = re.sub(r"_vs_.*", "", file1)
file2 = sys.argv[2]
file2_no_ext = re.sub(r"_vs_.*", "", file2)

f = open(file1, "r")
evk = f.readlines()
f.close()

j = open(file2, "r")
kve = j.readlines()
j.close()

outfile = file1_no_ext + "_" + file2_no_ext + "_Reciprocal_results.txt"
fileOut = open(outfile, "w")

kelp_list = []
for line in kve:
     line = line.strip()
     line = line.split("\t")
     query = line[0]
     subject = line[1]
     kall = line[1],"\t", line[0]
     kelp_list.append(kall)

counter = 0
for cline in evk:
    line = cline.strip()
    line = line.split("\t")
    query = line[0]
    subject = line[1]
    all = line[0],"\t", line[1]
    if all in kelp_list:
        print(cline, file= fileOut, end="")
