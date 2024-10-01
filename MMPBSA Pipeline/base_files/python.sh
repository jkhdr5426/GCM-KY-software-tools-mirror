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


# Move into the directory
cd $name

echo "Starting."

# Extract last frame from MDCRD and save as PDB
cpptraj_script="last_frame.in"
cat <<EOL > $cpptraj_script
parm ${name}_solvated.prmtop
trajin prod.mdcrd
trajout last_frame.pdb onlyframes 2000
EOL

cpptraj -i last_frame.in && \

# Python script to format MMPBSA results
python_script="format_mmpbsa_results.py"
cat <<EOL > $python_script
import matplotlib.pyplot as plt

input_file = 'FINAL_RESULTS_MMPBSA.dat'
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
