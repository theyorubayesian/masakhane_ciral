#!/bin/bash
{
    set -x;
    set -e;
    # ------------------------------------------------------------------------
    # This script train and evaluates retrieval models (encode, search, score)
    # ------------------------------------------------------------------------
    export CUDA_VISIBLE_DEVICES=0

    PROJECT_PATH="."
    mapfile -t MODEL_LIST < <(dir -d experiments/retrieval/afriberta_base_1e4_ckpt_25k_pft_msmarco_sw_miracl_ft/* | grep checkpoint)
    MODEL_LIST+=("experiments/retrieval/afriberta_base_1e4_ckpt_25k_pft_msmarco_sw_miracl_ft")
    # TOKENIZER_LIST=("experiments/retrieval/afro_xlmr_base")
    TOKENIZER_NAME_OR_DIR="experiments/retrieval/afriberta_base_1e4"
    EVAL_DATASET_LIST=("miracl" "mr-tydi")
    _QREL_DIR="/home/aooladip/collections"
    REMOVE_ARTEFACTS=true

    for model_idx in "${!MODEL_LIST[@]}"
    do
        MODEL_NAME_OR_PATH=${MODEL_LIST[model_idx]}
        [[ -z $TOKENIZER_NAME_OR_DIR ]] && TOKENIZER_NAME_OR_DIR=${TOKENIZER_LIST[model_idx]}

        # Only used to name artifacts
        MODEL_NAME=${MODEL_NAME_OR_PATH//'/'/'_'}
        # ---------------------------------------
        for EVAL_DATASET_NAME in "${EVAL_DATASET_LIST[@]}"
        do
            case $EVAL_DATASET_NAME in
                miracl )                    LANGUAGES=("swahili" "yoruba")
                                            SPLITS=("dev")
                                            QREL_DIR=$_QREL_DIR/miracl
                                            _QUERY_DATASET="miracl/miracl:"
                                            _CORPUS="miracl/miracl-corpus:"
                                            ;;
                mr-tydi )                   LANGUAGES=("swahili")
                                            SPLITS=("dev" "test")
                                            QREL_DIR=$_QREL_DIR/mr-tydi
                                            QUERY_DATASET="castorini/mr-tydi:swahili"
                                            CORPUS="castorini/mr-tydi-corpus:swahili"
                                            ;;
                africlirmatrix )            LANGUAGES=()
                                            ;;
                ciral )                     LANGUAGES=("hausa" "swahili" "somali" "yoruba")
                                            ;;
            esac

            for LANGUAGE in "${LANGUAGES[@]}"
            do
                echo "--$LANGUAGE--"
                for SPLIT in "${SPLITS[@]}"
                do                 
                    LANGUAGE_CODE=${LANGUAGE:0:2}
                    EVAL_QREL=$(du -a $QREL_DIR/*$LANGUAGE_CODE*/qrels* | grep "$SPLIT" | cut -f 2)

                    [[ -z $CORPUS ]] && CORPUS=$_CORPUS$LANGUAGE_CODE
                    [[ -z $QUERY_DATASET ]] && QUERY_DATASET=$_QUERY_DATASET$LANGUAGE_CODE
                                       
                    OUTPUT_PATH="$PROJECT_PATH/outputs/$MODEL_NAME"
                    RUNS_PATH="runs/$MODEL_NAME/$LANGUAGE"
                    QUERY_EMBD_PATH="$OUTPUT_PATH/query_encoding/$LANGUAGE/${EVAL_DATASET_NAME}_${SPLIT}_query_emb.pkl"
                    CORPUS_EMBD_PATH="$OUTPUT_PATH/corpus_encoding/$LANGUAGE/${EVAL_DATASET_NAME}_corpus_emb.pkl"
                    mkdir -p {"$OUTPUT_PATH/corpus_encoding/$LANGUAGE","$OUTPUT_PATH/query_encoding/$LANGUAGE","$RUNS_PATH"}
                    
                    # --------------
                    # Query Encoding
                    # # --------------
                    if [[ ! -f $QUERY_EMBD_PATH ]]; then
                        python -m tevatron.driver.encode \
                        --output_dir "$OUTPUT_PATH/encoded_queries" \
                        --model_name_or_path "$MODEL_NAME_OR_PATH" \
                        ${TOKENIZER_NAME_OR_DIR:+"--tokenizer_name" "$TOKENIZER_NAME_OR_DIR"} \
                        --fp16 \
                        --use_default_processor \
                        --per_device_eval_batch_size 256 \
                        --dataset_name "$QUERY_DATASET/$SPLIT" \
                        --encoded_save_path "$QUERY_EMBD_PATH" \
                        --q_max_len 64 \
                        --encode_is_qry && enc_query=true
                    else
                        enc_query=true
                    fi

                    # ---------------
                    # Corpus Encoding
                    # ---------------
                    if [[ ! -f $CORPUS_EMBD_PATH ]]; then
                        python -m tevatron.driver.encode \
                        --output_dir "$OUTPUT_PATH/corpus_encoding" \
                        --model_name_or_path "$MODEL_NAME_OR_PATH" \
                        ${TOKENIZER_NAME_OR_DIR:+"--tokenizer_name" "$TOKENIZER_NAME_OR_DIR"} \
                        --fp16 \
                        --use_default_processor \
                        --per_device_eval_batch_size 256 \
                        --p_max_len 256 \
                        --dataset_name "$CORPUS" \
                        --encoded_save_path "$CORPUS_EMBD_PATH" \
                        --encode_num_shard 1 && enc_corpus=true
                    else
                        enc_corpus=true
                    fi

                    # ------
                    # Search
                    # ------
                    if [[ $enc_corpus = true && $enc_query = true ]]; then
                        python -m tevatron.faiss_retriever \
                        --query_reps "$QUERY_EMBD_PATH" \
                        --passage_reps "$CORPUS_EMBD_PATH" \
                        --depth 100 \
                        --batch_size -1 \
                        --save_text \
                        --save_ranking_to "$RUNS_PATH/$EVAL_DATASET_NAME.$SPLIT.txt" && \
                        python -m tevatron.utils.format.convert_result_to_trec \
                        --input "$RUNS_PATH/$EVAL_DATASET_NAME.$SPLIT.txt" \
                        --output "$RUNS_PATH/$EVAL_DATASET_NAME.$SPLIT.trec" && \
                        faiss_search=true
                    fi

                    # ----------
                    # Evaluation
                    # ----------
                    # wget https://git.uwaterloo.ca/jimmylin/mr.tydi/-/raw/master/data/mrtydi-v1.0-swahili.tar.gz \
                    # -O $QREL_DIR/mrtydi-v1.0-$LANGUAGE.tar.gz \
                    # -o $QREL_DIR/mrtydi-v1.0-$LANGUAGE.tar.gz.out
                    # tar -xvf $QREL_DIR/mrtydi-v1.0-$LANGUAGE.tar.gz -C $QREL_DIR && \
                    # rm $QREL_DIR/mrtydi-v1.0-$LANGUAGE.tar.gz $QREL_DIR/mrtydi-v1.0-$LANGUAGE.tar.gz.out

                    if [[ $faiss_search = true ]]; then
                        python -m pyserini.eval.trec_eval -c \
                        -m recip_rank \
                        -m recall.100 \
                        -m ndcg_cut.10 \
                        "$EVAL_QREL" \
                        "$RUNS_PATH/$EVAL_DATASET_NAME.$SPLIT.trec" \
                        > "$RUNS_PATH/$EVAL_DATASET_NAME.$SPLIT.results"
                    fi

                    [[ ! -z $_CORPUS ]] && unset CORPUS
                    [[ ! -z $_QUERY_DATASET ]] && unset QUERY_DATASET
                done

                # ----------------
                # Remove artifacts
                # ----------------
                if [[ $REMOVE_ARTEFACTS = true ]]; then
                    # rm -rf $OUTPUT_PATH
                    echo
                fi
            done
            unset _QUERY_DATASET _CORPUS
        done
    done
}