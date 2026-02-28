from transformers import AutoModelForSequenceClassification, AutoTokenizer
import json
from tqdm import tqdm
import numpy as np
import torch

def load_reward_model(hf_cache_dir=None):
    reward_name = "OpenAssistant/reward-model-deberta-v3-large-v2"
    reward_model = AutoModelForSequenceClassification.from_pretrained(
        reward_name, cache_dir=hf_cache_dir, device_map="auto"
    ).eval()
    tokenizer = AutoTokenizer.from_pretrained(reward_name, cache_dir=hf_cache_dir)
    return reward_model, tokenizer


@torch.no_grad()
def score_response(reward_model, tokenizer, question, answer):
    inputs = tokenizer(question, answer, return_tensors="pt", truncation=True, max_length=512)
    inputs = {k: v.to(reward_model.device) for k, v in inputs.items()}
    score = reward_model(**inputs).logits[0].item()
    return score


def evaluate_file(file_path, reward_model, tokenizer, key="att_result"):
    scores = []
    with open(file_path, "r") as f:
        for line in tqdm(f, desc="Scoring"):
            data = json.loads(line.strip())
            prompt = data.get("prompt", "")
            response = data.get(key)
            if response is None:
                continue
            s = score_response(reward_model, tokenizer, prompt, response)
            scores.append(s)
    return scores


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Evaluate harm scores using a reward model")
    parser.add_argument("--input_file", type=str, required=True, help="Path to the JSONL result file")
    parser.add_argument("--hf_cache_dir", type=str, default=None, help="HuggingFace cache directory")
    parser.add_argument("--key", type=str, default="att_result",
                        choices=["att_result", "ref_result", "tgt_result"],
                        help="Which response field to evaluate")
    args = parser.parse_args()

    reward_model, tokenizer = load_reward_model(args.hf_cache_dir)
    scores = evaluate_file(args.input_file, reward_model, tokenizer, key=args.key)

    print(f"File: {args.input_file}")
    print(f"Key:  {args.key}")
    print(f"Samples scored: {len(scores)}")
    print(f"Mean harm score: {np.mean(scores):.4f}")
    print(f"Std  harm score: {np.std(scores):.4f}")
