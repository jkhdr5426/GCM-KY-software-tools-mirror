#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -r <receptor_pdb> -l <ligand_pdb> -c <complex_pdb> -n <name_dir> -j <num_cores>"
    exit 1
}

# Parse command line arguments
while getopts ":r:l:c:n:j:" opt; do
    case $opt in
        r) receptor="$OPTARG"
        ;;
        l) ligand="$OPTARG"
        ;;
        c) complex="$OPTARG"
        ;;
        n) name="$OPTARG"
        ;;
        j) cores="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            usage
        ;;
        :) echo "Option -$OPTARG requires an argument." >&2
            usage
        ;;
    esac
done

# Check if all arguments are provided
if [ -z "$receptor" ] || [ -z "$ligand" ] || [ -z "$complex" ] || [ -z "$name" ] || [ -z "$cores" ]; then
    usage
fi

# Create the output directory
mkdir -p $name

# Move into the directory
cd $name

echo "Starting."

# Define paths to necessary input files
mol2_file="$HOME/amber/FABmutagenisis/base_files/pfoa.mol2"
frcmod_file="$HOME/amber/FABmutagenisis/base_files/pfoa.frcmod"
min_in_file="$HOME/amber/FABmutagenisis/base_files/min.in"
heat_in_file="$HOME/amber/FABmutagenisis/base_files/heat.in"
density_in_file="$HOME/amber/FABmutagenisis/base_files/density.in"
equil_in_file="$HOME/amber/FABmutagenisis/base_files/equil.in"
prod_in_file="$HOME/amber/FABmutagenisis/base_files/prod.in"
mmpbsa_in_file="$HOME/amber/FABmutagenisis/base_files/mmpbsa.in"

# Leap script
leap_script="leap.in"
cat <<EOL > $leap_script
source leaprc.protein.ff19SB
source leaprc.gaff2
source leaprc.water.opc
UNL = loadMol2 $mol2_file
loadamberparams $frcmod_file
com = loadpdb $complex
rec = loadpdb $receptor
lig = loadpdb $ligand
set default PBRadii mbondi2
saveamberparm com $name.prmtop $name.inpcrd
saveamberparm rec ${name}_rec.prmtop ${name}_rec.inpcrd
saveamberparm lig ${name}_lig.prmtop ${name}_lig.inpcrd
charge com
addions com Na+ 0
solvatebox com TIP3PBOX 12.0
saveamberparm com ${name}_solvated.prmtop ${name}_solvated.inpcrd
quit
EOL

# Run tleap
tleap -f $leap_script && \

echo "LEaP completed."

# Run minimization
pmemd.cuda -O -i $min_in_file -o min.out -p ${name}_solvated.prmtop -c ${name}_solvated.inpcrd -r min.rst -ref ${name}_solvated.inpcrd && \

echo "Min completed."

# Run heating
pmemd.cuda -O -i $heat_in_file -o heat.out -p ${name}_solvated.prmtop -c min.rst -r heat.rst -x heat.mdcrd -ref min.rst && \

echo "Heat completed."

# Run density
pmemd.cuda -O -i $density_in_file -o density.out -p ${name}_solvated.prmtop -c heat.rst -r density.rst -x density.mdcrd -ref heat.rst && \

echo "Dens completed."

# Run equilibration
pmemd.cuda -O -i $equil_in_file -o equil.out -p ${name}_solvated.prmtop -c density.rst -r equil.rst -x equil.mdcrd && \

echo "Equil completed."

# Run production
pmemd.cuda -O -i $prod_in_file -o prod.out -p ${name}_solvated.prmtop -c equil.rst -r prod.rst -x prod.mdcrd && \

echo "Prod completed."

# Process MDOUT
process_mdout.perl prod.out && \

# Run MMPBSA
mpirun -np $cores MMPBSA.py.MPI -O -i $mmpbsa_in_file -o FINAL_RESULTS_MMPBSA.dat -sp ${name}_solvated.prmtop -cp $name.prmtop -rp ${name}_rec.prmtop -lp ${name}_lig.prmtop -y prod.mdcrd && \

echo "MMPBSA completed."

# Extract last frame from MDCRD and save as PDB
cpptraj_script="last_frame.in"
cat <<EOL > $cpptraj_script
parm ${name}_solvated.prmtop
trajin prod.mdcrd
trajout last_frame.pdb onlyframes 2000
EOL

cpptraj -i last_frame.in && \

echo "Last frame extracted (#2000)."

# Python script to format MMPBSA results
python_script="format_mmpbsa_results.py"
cat <<EOL > $python_script
import matplotlib.pyplot as plt

input_file = 'FINAL_DECOMP_MMPBSA.dat'
output_file = 'formatted_$name.txt'

# Define the headers
headers = [
    "Residue", "Location",
    "Internal Avg.", "Internal Std. Dev.", "Internal Std. Err. of Mean",
    "van der Waals Avg.", "van der Waals Std. Dev.", "van der Waals Std. Err. of Mean",
    "Electrostatic Avg.", "Electrostatic Std. Dev.", "Electrostatic Std. Err. of Mean",
    "Polar Solvation Avg.", "Polar Solvation Std. Dev.", "Polar Solvation Std. Err. of Mean",
    "Non-Polar Solv. Avg.", "Non-Polar Solv. Std. Dev.", "Non-Polar Solv. Err. of Mean",
    "TOTAL Avg.", "TOTAL Std. Dev.", "TOTAL Std. Err. of Mean"
]

# Read the input file and extract the relevant data
with open(input_file, 'r') as file, open(output_file, 'w') as out_file:
    lines = file.readlines()
    data_start = False
    for line in lines:
        if "TOTAL" in line:
            data_start = True
            # Write headers to the output file
            out_file.write("\t".join(headers) + "\n")
            continue
        if data_start and line.strip():
            parts = line.split(',')
            residue_data = parts[:2] + parts[2:17] + parts[17:20]
            residue_data = [item.strip() for item in residue_data]
            out_file.write("\t".join(residue_data) + "\n")
EOL

# Run the Python script
python3 $python_script && \

echo "All steps completed."
