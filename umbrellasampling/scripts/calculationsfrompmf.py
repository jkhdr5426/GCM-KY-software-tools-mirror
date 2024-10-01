import numpy as np

k_B = 1.380649e-23
T = 298.15
kBT = k_B * T 
kBT_kcalmol = kBT * 6.02214076e23 / 4184 
file_path = '/mnt/data/pmf.txt'
data = np.loadtxt(file_path, comments="#", usecols=(0, 1))
coordinates = data[:, 0]
free_energy = data[:, 1]
delta_G_bound = np.min(free_energy)  
unbound_state_mask = free_energy > delta_G_bound
delta_G_unbound = np.max(free_energy[unbound_state_mask]) 
delta_G_standard = delta_G_unbound - delta_G_bound  
Kd = np.exp(delta_G_standard / kBT_kcalmol)
delta_G_standard, Kd 


