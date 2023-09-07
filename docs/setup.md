## Downloading Qrels

In order to evaluate our systems on [Mr. TyDi](https://github.com/castorini/mr.tydi) and [Miracl](https://github.com/project-miracl), we'll need to download the relevant qrel files.

### Mr. TyDi

Swahili is the only African language covered by Mr. TyDi. We can download its qrels by running the following commands in terminal.

```bash
wget https://git.uwaterloo.ca/jimmylin/mr.tydi/-/raw/master/data/mrtydi-v1.0-swahili.tar.gz -O "data/qrels/mrtydi-v1.0-swahili.tar.gz" -o "data/qrels/mrtydi-v1.0-swahili.tar.gz.out"

tar -xvf "data/qrels/mrtydi-v1.0-swahili.tar.gz" -C "data/qrels/mr-tydi"

rm "data/qrels/mrtydi-v1.0-swahili.tar.gz" "data/qrels/mrtydi-v1.0-swahili.tar.gz.out"
```

## MIRACL

Miracl covers Swahili and Yoruba. However, qrels for Yoruba test set is not public. You have to manually download the qrels from Huggingface Hub by following links below:

* [Swahili](https://huggingface.co/datasets/miracl/miracl/tree/main/miracl-v1.0-sw/qrels)
* [Yoruba](https://huggingface.co/datasets/miracl/miracl/tree/main/miracl-v1.0-yo/qrels)

After downloading the qrel files, please copy them into the relevant language folders for Swahili - [data/qrels/miracl/miracl-v1.0-sw](../data/qrels/miracl/miracl-v1.0-sw) and Yoruba - [data/qrels/miracl/miracl-v1.0-yo](../data/qrels/miracl/miracl-v1.0-yo).


## CIRAL

You also have to download the dev qrels manually. Refer to the relevant links below: 

* [Hausa](https://huggingface.co/datasets/CIRAL/ciral/tree/main/ciral-hausa/qrels)
- [Somali](https://huggingface.co/datasets/CIRAL/ciral/tree/main/ciral-somali/qrels)
- [Swahili](https://huggingface.co/datasets/CIRAL/ciral/tree/main/ciral-swahili/qrels)
- [Yoruba](https://huggingface.co/datasets/CIRAL/ciral/tree/main/ciral-yoruba/qrels)

After downloading the qrel files, please copy them into the relevant language folders for Hausa - [data/qrels/ciral/ciral-hausa], Somali - [data/qrels/ciral/ciral-somali], Swahili - [data/qrels/ciral/ciral-swahili](../data/qrels/miracl/miracl-v1.0-sw) and Yoruba - [data/qrels/ciral/ciral-yoruba](../data/qrels/ciral/ciral-yoruba).
