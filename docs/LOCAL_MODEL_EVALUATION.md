# Local Model Evaluation & Selection Guide

**Date:** 2026-10-08  
**Scope:** Lightweight on-device and local-first LLM evaluation for EmpTracker mobile and server nodes.  
**Phase 2 Status:** Active — Implemented & Verified  

---

## 1. Evaluation Criteria

To operate within Android devices (4GB–8GB RAM) and edge server environments without degrading app performance:
1. **Model Parameter Size & Memory Footprint:** < 3.5B parameters; quantized memory < 2.2 GB RAM.
2. **Quantization:** 4-bit (Q4_K_M or AWQ) for high throughput on mobile CPUs/NPUs.
3. **Multilingual & Indic Language Support:** High fluency in English, Hindi, and Hinglish transliteration.
4. **Tool & Function Calling / JSON Formatting:** Strict schema compliance for deterministic tool execution.
5. **Inference Latency:** < 800ms time-to-first-token on modern mobile chipsets (Snapdragon 7/8 series, MediaTek Dimensity).

---

## 2. Model Comparison Matrix

| Model | Parameters | Quantization | RAM Required | Hindi / Hinglish | Function Calling | Inference Speed | Selected Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Qwen 2.5 (1.5B / 3B Instruct)** | 1.54B / 3.09B | Q4_K_M (GGUF) | 1.1 GB / 2.0 GB | ⭐⭐⭐⭐⭐ (Exceptional) | ⭐⭐⭐⭐⭐ (Native JSON) | ⚡ Very Fast (>25 t/s) | **🥇 Selected Active Engine** |
| **Gemma 2 (2B Instruct)** | 2.6B | Q4_K_M (GGUF) | 1.6 GB | ⭐⭐⭐⭐ (Very Good) | ⭐⭐⭐⭐ (Structured) | ⚡ Fast (20 t/s) | **🥈 Alternate / Fallback** |
| **Llama 3.2 (1B / 3B Instruct)** | 1.23B / 3.21B | Q4_K_M (GGUF) | 0.9 GB / 2.1 GB | ⭐⭐⭐ (Moderate Indic) | ⭐⭐⭐⭐⭐ (Strong Tools) | ⚡ Very Fast (>28 t/s) | **🥉 Alternate Option** |
| **Phi-3.5 Mini (3.8B)** | 3.82B | Q4_K_M (GGUF) | 2.5 GB | ⭐⭐⭐ (Good Reasoning) | ⭐⭐⭐⭐ (Strong Tools) | Moderate (15 t/s) | **Heavier for Low-End Mobile** |

---

## 3. Selected Primary Model: `Qwen2.5-1.5B-Instruct-Q4_K_M`

### Key Rationales for Selection:
1. **Superior Multilingual & Indic Comprehension:** Pretrained on extensive Hindi, Hinglish, and South Asian conversational corpora.
2. **Strict JSON Schema Adherence:** Native JSON structured generation support (`QwenLocalInferenceEngine::generateStructuredJson`).
3. **Ultra-Low Memory Footprint:** At 1.5B Q4, requires only ~1.1 GB RAM, guaranteeing fluid multi-tasking alongside background GPS location services.

---

## 4. Implemented Engine Architecture (`LocalInferenceEngineInterface`)

The inference layer is fully abstracted behind an interface so the active model runtime can be replaced or updated without breaking application logic:

* **Interface:** `App\AI\Contracts\LocalInferenceEngineInterface`
* **Implementation:** `App\AI\Providers\Engines\QwenLocalInferenceEngine`
* **Consumer:** `App\AI\Providers\LocalAiProvider`
