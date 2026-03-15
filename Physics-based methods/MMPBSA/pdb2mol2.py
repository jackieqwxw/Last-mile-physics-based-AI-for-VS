#!/usr/bin/env python3
# coding: utf-8

# # This script was used for replace the 3D cooridinates from lig.mol2 file by the ones from lig.pdb file 

# In[1]:


import os


# In[2]:


with open('lig.mol2') as file1:
    lines = [x for x in file1]
    
atoms = lines[2].split()[0]
bonds = lines[2].split()[1]

natom = []
name = []
atom_type = []
nr = []
mol = []
charge = []
for i in range(0,int(atoms)+8):
    if i>=8:
        natom.append(lines[i].split()[0])
        name.append(lines[i].split()[1])
        atom_type.append(lines[i].split()[5])
        nr.append(lines[i].split()[6])
        mol.append(lines[i].split()[7])
        charge.append(lines[i].split()[8])


# In[3]:


with open('lig.pdb') as file2:
    lines0 = [x for x in file2]

x_pdb = []
y_pdb = []
z_pdb = []
for i,j in enumerate(lines0):
    x_pdb.append(j.split()[5])
    y_pdb.append(j.split()[6])
    z_pdb.append(j.split()[7])


# In[4]:


coor_upd = list(zip(natom,name,x_pdb,y_pdb,z_pdb,atom_type,nr,mol,charge))


# In[5]:


fp = open('ligand.mol2',"w")
for i in range(0,8):
    fp.write(lines[i])
for i in coor_upd:
    a = str(i).replace(","," ").replace("(","").replace(")","").replace("'","").replace(",","  ")
    a1 = int(a.split()[0])
    a2 = a.split()[1]
    a3 = float(a.split()[2])
    a4 = float(a.split()[3])
    a5 = float(a.split()[4])
    a6 = a.split()[5]
    a7 = int(a.split()[6])
    a8 = a.split()[7]
    a9 = float(a.split()[8])
    fp.write('%7d %-10s%8.3f%8.3f%8.3f %-2s%10d%4s%15.6f' %(a1,a2,a3,a4,a5,a6,a7,a8,a9))
    fp.write('\n')
for i in range(int(atoms)+8,int(atoms)+8+int(bonds)+3):
    fp.write(lines[i])
fp.close()

