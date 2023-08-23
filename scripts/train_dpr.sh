#!/bin/bash
set -x;

export CUDA_VISIBLE_DEVICES=0,2,3,4
export WANDB_RUN_GROUP="retrieval"
export WANDB_PROJECT="ciral"
export WANDB_LOG_MODEL=false

readarray -d , -t GPUS <<< "$CUDA_VISIBLE_DEVICES"
N_GPU=${#GPUS[@]}
# -------------- #

MULTILINGUAL=false                          # If True, LR is 1e-5. Else 4e-5.
DATASET_NAME="castorini/mr-tydi:swahili"
# DATASET_DIR="data/latin_mrtydi/train"     # If training on local data, pass this instead.
OUTPUT_DIR=
MODEL_NAME_OR_DIR=
TOKENIZER_NAME_OR_DIR=
BATCH_SIZE=32
SAVE_STEPS=100
NUM_EPOCHS=40
GRADIENT_ACCUMULATION_STEPS=1
TRAIN_N_PASSAGES=8

if [[ "$MULTILINGUAL" = "true" ]]; then
    LEARNING_RATE=1e-5
    SET_LANGUAGE_PER_BATCH=true
else
    LEARNING_RATE=4e-5
fi

LOGDIR=${OUTPUT_DIR//'/'/'_'}
mkdir -p $OUTPUT_DIR

python -m torch.distributed.launch \
--nproc_per_node "$N_GPU" --master_port 29900 \
-m tevatron.driver.train \
--output_dir $OUTPUT_DIR \
${SET_LANGUAGE_PER_BATCH:+ "--set_language_per_batch" "--dataloader_num_workers" "2"} \
--model_name_or_path $MODEL_NAME_OR_DIR \
--tokenizer_name $TOKENIZER_NAME_OR_DIR \
--save_steps $SAVE_STEPS \
${DATASET_NAME:+ "--dataset_name" $DATASET_NAME} \
${DATASET_DIR:+ "--train_dir" $DATASET_DIR} \
--per_device_train_batch_size $BATCH_SIZE \
--train_n_passages $TRAIN_N_PASSAGES \
--gradient_accumulation_steps $GRADIENT_ACCUMULATION_STEPS \
--use_default_processor \
--learning_rate $LEARNING_RATE \
--q_max_len 64 \
--p_max_len 256 \
--num_train_epochs $NUM_EPOCHS \
--logging_steps 100 \
--overwrite_output_dir \
--fp16 \
--report_to "wandb" > "logs/$LOGDIR.log" 2>&1 &