# AI Topic Builder

An Idiomind add-on that creates topics using artificial intelligence.

## What it does

AI Topic Builder lets you create complete Idiomind topics from a short
description. You provide a topic name, a category, a content type, and
optional instructions. The add-on sends a prompt to an AI provider,
receives a structured JSON response, validates it, and then creates a
normal Idiomind topic with real sentences and words.

From Idiomind's point of view, the resulting topic is indistinguishable
from one created manually. It uses the same data model, the same
functions, and the same export mechanism.

## How to use

1. Open Idiomind.
2. Click **New Topic**.
3. In the name field, type exactly:
/auto

text

4. Click **OK**.
5. Fill in the form:
- **Topic**: the name of the topic to create.
- **Category**: one of Idiomind's built-in categories.
- **Type**: 1 (words only), 2 (sentences only), or 3 (hybrid).
- **Instructions**: free-text description of what you want.
6. Click **Generate**.
7. Wait for the AI provider to respond.
8. The topic is created automatically.

## Content types

- **Type 1 — Words / expressions only.**
The AI generates only words and expressions. No sentences.
Each word has a translation and a usage example.

- **Type 2 — Sentences only.**
The AI generates only sentences. No words.
Each sentence has a target-language text and a source-language translation.

- **Type 3 — Hybrid.**
The AI generates sentences first, then words.
Every word appears literally in at least one of the generated sentences,
and its example field is one of those sentences.

## Configuration

Open the add-on preferences from the Idiomind add-ons menu.

Available settings:

- **Provider**: OpenAI, Groq, DeepSeek, Ollama, or Custom.
- **API key**: your provider's API key.
- **Endpoint (optional)**: override the default endpoint.
- **Model (optional)**: override the default model.

If you leave Endpoint or Model empty, the defaults for the selected
provider are used.

The configuration is stored in:
$HOME/.config/idiomind/addons/ai_topic_builder.cfg

text

## Supported providers

| Provider | Default model | Notes |
|---|---|---|
| OpenAI | `gpt-4o-mini` | Requires paid credit |
| Groq | `openai/gpt-oss-120b` | Free tier available |
| DeepSeek | `deepseek-chat` | Very low cost |
| Ollama | `llama3.1:8b` | Local, no API key needed |
| Custom | (user-provided) | Any OpenAI-compatible endpoint |

## Requirements

- Idiomind (any recent version with `ifs/extensions/add_processors/`).
- `curl`.
- `python3`.
- Network access to the chosen provider (except Ollama).

## Audio and images

If your Idiomind configuration has audio download enabled (`dlaud=TRUE`),
audio for sentences and words is generated automatically through
Idiomind's existing TTS subsystem.

If you have image download scripts configured in Idiomind, images for
words are downloaded automatically through Idiomind's existing image
subsystem.

The add-on does not implement its own audio or image generation. It
relies entirely on Idiomind's existing mechanisms.

## Export

The add-on does not export automatically. To export a generated topic,
use Idiomind's normal export flow (**Export topic** → choose format).

## Error handling

If the AI provider returns an error (invalid API key, quota exhausted,
rate limit, invalid model), the add-on shows a dialog with the HTTP
status code and the first part of the response body. This makes it easy
to diagnose the problem.

## Limitations

- Type 3 depends on the AI following the "every word appears in a
  sentence" rule. The add-on validates structure and length, but does
  not currently re-check that every word appears in a sentence.
- The number of items generated is determined by the prompt
  (8-15 sentences, 5-10 words). It is not configurable from the UI.
- The languages used are the ones configured globally in Idiomind
  (`tlng` and `slng`). They cannot be overridden per topic.

## Files
addons/AI Topic Builder/
├── README.md
├── cnfg.sh
├── ai_topic_builder.sh
├── icon.png
└── prompts/
├── base.txt
├── type1.txt
├── type2.txt
└── type3.txt

ifs/extensions/add_processors/
└── topic_auto.sh

