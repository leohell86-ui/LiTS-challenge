# LiTS-challenge

# LiTS Liver/Tumor Segmentation 


This repo contains notebooks, scripts, and models for liver and tumor segmentation on LiTS challenge. 
It is possible to obtain the full dataset on CodaLab at this link: https://competitions.codalab.org/competitions/17094#learn_the_details-overview
First of all, you have to sign in and take part to the LiTS challenge and look for the .nii files in the Training Data.

Pay attention to place correctly the the folder in the right location.
Afterwards, the notebook DataManagement.ipynb will re-order your files.

Run NNTraining.ipynb to obtain the models for the UNet training and then apply it using ApplyModels.ipynb. 

## Setup (Windows)
Choose Conda or Python venv. The use of GPU is advised.

### Option A: Conda (recommended)
See details in [Test files/README_KERNEL.md](Test%20files/README_KERNEL.md).

```powershell
# From repo root
conda env create -f ".\Test files\environment.yml" -n lits
# CPU PyTorch example (adjust for GPU/CUDA if desired)
conda install -n lits -c pytorch pytorch=2.2.2 torchvision=0.17.2 torchaudio=2.2.2 cpuonly -y
# Register kernel
conda run -n lits python -m ipykernel install --user --name conda_lits --display-name "LiTS (conda_lits)"
```
Or use helper script:
```powershell
# Creates env, installs PyTorch, registers kernel
.\Test files\create_conda_env.ps1
# With GPU attempt (example)
.\Test files\create_conda_env.ps1 -UseGpu -CudaVersion 121
```

### Option B: Python venv
```powershell
# Creates venv, installs packages, registers kernel
.\Test files\create_kernel.ps1
# With GPU attempt
.\Test files\create_kernel.ps1 -UseGpu
```

## Verify Installation
```powershell
# Print torch version + CUDA availability
python .\Test files\check_torch_gpu.py

# Smoke test of core imports + GPU check
python .\Test files\run_smoke.py
```

## Data
- Place LiTS-style NIfTI volumes and segmentations under `data/`.
- Filenames expected by evaluator: `volume-<id>.nii` and `segmentation-<id>.nii`.
- The evaluator auto-discovers pairs recursively under `data/`.

## Notebooks
- Open [NNtraining.ipynb](NNtraining.ipynb), [DataManagement.ipynb](DataManagement.ipynb), or [ApplyModels.ipynb](ApplyModels.ipynb) in Jupyter.
- Select the kernel you registered (e.g., `LiTS (conda_lits)` or venv name).

To run a notebook programmatically:
```powershell
# Edit kernel name in the script if needed
python .\Test files\execute_notebook.py
```

## Quick Evaluation
A minimal UNet evaluator for sanity checks:
```powershell
python .\Test files\evaluate_model.py
```
- Looks for pairs under `data/`, evaluates a small slice range, and writes samples to [eval_outputs](eval_outputs).
- If `best_model.pth` exists in repo root, it will attempt to load compatible weights.

## Tips
- GPU installs depend on matching CUDA/toolkit; if unsure, use CPU wheels.
- For larger experiments, use the notebooks and your preferred kernels.
- See [Test files/README_KERNEL.md](Test%20files/README_KERNEL.md) for environment notes and troubleshooting.
