#!/usr/bin/env python3
# coding: utf-8

# In[1]:


import os


# In[2]:


with open('MOL_GMX.gro') as file1:
    lines = [x for x in file1]
#title = lines[0]
latoms = lines[1]

linestart = []
for i,j in enumerate(lines):
    if i >= 2 and i <= (int(latoms)+1):
        linestart.append(j.split()[0:4])


# In[3]:


with open('pdbid.xyz') as file2:
    lines = [x for x in file2]
len(lines)

xyz = []
for i,j in enumerate(lines):
    if i >= 2 and i <= (int(latoms)+1):
        xyz.append(j.split()[1:4])


# In[4]:


newlines = list(zip(linestart,xyz))

newfile = 'tmp.gro'
fp0 = open(newfile,"w")
for line in newlines:
    a = str(line).replace("[","").replace("]","").replace("(","").replace(")","").replace("'","").replace(",","  ")
    fp0.write(a)
    fp0.write('\n')
fp0.close()


# In[5]:


# read protein file: prot.gro
protfile = 'prot.gro'
with open(protfile) as file3:
    lines = [x for x in file3]

title = lines[0]
patoms = lines[1]
boxsize = lines[len(lines)-1]
allatoms = int(patoms) + int(latoms)


# In[6]:


fp3 = open(protfile,"r")
newfile3 = 'com.gro'
fp4 = open(newfile3,"w")
fp4.write(title)
fp4.write('%5s' %str(allatoms))
fp4.write('\n')

for i,line in enumerate(fp3.readlines()):
    if i >=2 and i <= (len(lines)-2):
        fp4.write(line)

# format outputing for the ligand MOL.gro 
fp1 = open(newfile,"r")
for line in fp1.readlines():
    g1 = line.split()[0]
    g2 = line.split()[1]
    g3 = line.split()[2]
    g4 = line.split()[3]
    g5 = float(line.split()[4])/10
    g6 = float(line.split()[5])/10
    g7 = float(line.split()[6])/10
    fp4.write('%5s%3s%7s%5s%8.3f%8.3f%8.3f' %(g1,g2,g3,g4,g5,g6,g7))
    fp4.write('\n')

fp4.write(boxsize)
fp4.close()
fp1.close()
os.remove(newfile)

