# MS-Marco Pre-Finetuning Experiment

This example demonstrates how we can train a Dense Retriever on the MS Marco Passage Ranking Dataset starting from an LM and then evaluate on the [Mr.Tydi](https://github.com/castorini/mr.tydi) Swahili test set.

## Training

```bash
CUDA_VISIBLE_DEVICES=0,1,2,3 WANDB_PROJECT=ciral WANDB_ENTITY=masakhane-miracl \
python -m torch.distributed.launch \
--nproc_per_node 4 \
-m tevatron.driver.train \
--output_dir models/swahili-bert-msmarco/ \
--model_name_or_path Davlan/bert-base-multilingual-cased-finetuned-swahili \
--save_steps 20000 \
--dataset_name Tevatron/msmarco-passage \
--fp16 \
--per_device_train_batch_size 32 \
--train_n_passages 8 \
--learning_rate 4e-5 \
--q_max_len 64 \
--p_max_len 256 \
--num_train_epochs 40 \
--logging_steps 500 \
--overwrite_output_dir \
--report_to wandb
```

## Encode Corpus

```bash
python -m tevatron.driver.encode \
--output_dir outputs/swahili-bert-msmarco/encoded_queries \
--model_name_or_path models/swahili-bert-msmarco \
--fp16 \
--per_device_eval_batch_size 256 \
--dataset_name castorini/mr-tydi:swahili/test \
--encoded_save_path outputs/swahili-bert-msmarco/query_encoding/swahili/query_emb.pkl \
--q_max_len 64 \
--encode_is_qry
```

## Encode Query

```bash
python -m tevatron.driver.encode \
--output_dir outputs/swahili-bert-msmarco/encoded_corpus \
--model_name_or_path models/swahili-bert-msmarco \
--fp16 \
--per_device_eval_batch_size 256 \
--p_max_len 256 \
--dataset_name castorini/mr-tydi-corpus:swahili \
--encoded_save_path outputs/swahili-bert-msmarco/corpus_encoding/swahili/corpus_emb.pkl \
--encode_num_shard 1
```

## Search

```bash
python -m tevatron.faiss_retriever \
--query_reps outputs/swahili-bert-msmarco/query_encoding/swahili/query_emb.pkl \
--passage_reps outputs/swahili-bert-msmarco/corpus_encoding/swahili/corpus_emb.pkl \
--depth 100 \
--batch_size -1 \
--save_text \
--save_ranking_to runs/swahili-bert-msmarco/swahili/mrtydi.test.txt && \
python -m tevatron.utils.format.convert_result_to_trec \
--input runs/swahili-bert-msmarco/swahili/mrtydi.test.txt \
--output runs/swahili-bert-msmarco/swahili/mrtydi.test.trec
```

## Evaluate

* Download qrels from [Mr.TyDi](https://github.com/castorini/mr.tydi) repo

```bash
wget https://git.uwaterloo.ca/jimmylin/mr.tydi/-/raw/master/data/mrtydi-v1.0-swahili.tar.gz
tar -xvf mrtydi-v1.0-swahili.tar.gz
```

* Run evaluation

```bash
python -m pyserini.eval.trec_eval -c \
-m recip_rank \
-m recall.100 \
-m ndcg_cut.10 \
mrtydi-v1.0-swahili/qrels.test.txt \
runs/swahili-bert-msmarco/swahili/mrtydi.test.trec > \
runs/swahili-bert-msmarco/swahili/mrtydi.test.results
```
