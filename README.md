# masakhane_ciral

This repository guides our submission to the [Cross-lingual Information Retrieval for African Languages](https://ciralproject.github.io/) track hosted at [Forum for Information Retrieval Evaluation '23](http://fire.irsi.res.in/fire/2023/call_for_tracks)

## Setup & Installation

* Create an environment using either Conda or Venv

```bash
conda create -n ciral python=3.9 openjdk=11
conda activate ciral
```

* Clone the repo

```bash
git clone --recurse-submodules https://github.com/theyorubayesian/masakhane_miracl.git 
```

* Install `Pytorch>=1.10` suitable for your CUDA version. See [Pytorch](https://pytorch.org/get-started/previous-versions/#v1101)

* Install other requirements

```bash
pip install -r requirements.txt
```

* Login to [Weights & Biases](https://wandb.ai/masakhane-miracl/masakhane-miracl) where we are logging our experiments.

```bash
wandb login
```

* Hack away 🔨🔨

## Experiments

1. [Training on MS Marco & Reporting Zero-Shot Results on Mr.TyDi Swahili](docs/msmarco_pft.md)
2. [Zero-Shot Evaluation of the Dense Retriever on Miracl Dev Set](docs/evaluating_on_miracl_dev_set.md)
3. [Finetuning the Dense Retriever on the Miracl Train Set & Generating Rankings for the `testA` set](docs/miracl_finetuning_experiment.md)