# Team GCM-KY 2024 Software Tool

If your team competes in the [**Software & AI** village](https://competition.igem.org/participation/villages) or wants to
apply for the [**Best Software Tool** prize](https://competition.igem.org/judging/awards), you **MUST** host all the
code of your team's software tool in this repository, `main` branch. By the **Wiki Freeze**, a
[release](https://docs.gitlab.com/ee/user/project/releases/) will be automatically created as the judging artifact of
this software tool. You will be able to keep working on your software after the Grand Jamboree.

> If your team does not have any software tool, you can totally ignore this repository. If left unchanged, this
repository will be automatically deleted by the end of the season.

## Prerequisite
It is vital to have Amber installed on your machine, ideally this is set up with CUDA, but if you do not have an NVIDIA Graphics card, you can simply alter the pipeline file to use Sander instead of PMEMD.

You may install AmberMD from their website:
https://ambermd.org/index.php

## Description
Included in this repository are ALL the input and output files used and created with Amber, along with the code for the Umbrella Sampling pipeline using OpenMM.

## Installation
For Amber, follow their guide which can be found on the team wiki. For the OpenMM pipeline installation, find the ReadMe file inside the folder.

Download the "base_files" folder and the "simulation.sh" file from the repository. Now, move them into your Amber directory, and use this command:

chmod +x simulation.sh

On a fresh install, you might need to install python, use the following commands:
sudo apt update
sudo apt install python3 -y
pip3  install matplotlib

Before proceding, ensure that the "amber.sh" file is sourced in your bashrc, you can verify it with the echo command.

Now, you are ready to run the pipeline.

## Usage
Instructions for useage of OpenMM are available on the team wiki, as well as the Umbrella Sampling folder. Useage of the MMPBSA pipeline will be provided here.

Example command for MMPBSA pipeline:
./simulation.sh -r receptor.pdb -l ligand.pdb -c complex.pdb -n THR351_ARG -j 15
  
-r receptor PDB
-l ligand PDB
-c complex PDB
-n name of directory
-j number of cores

## Contributing
We are accepting contributions via emailing "igemlouisville@gmail.com"

## Authors and acknowledgment
ALL work done in Amber was performed by Vishwaa Kannan, Molecular Dynamics Lead.
OpenMM Pipeline for Umbrella Sampling was created by Edward Kim.
