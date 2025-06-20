# MarkovNameGenerator

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.0+-blue?logo=godot-engine\&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-Ready-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen)

*Character-level Markov chain implementation for procedural name generation in GDScript*

</div>

## Overview

**MarkovNameGenerator** is a GDScript class that implements a character-level Markov chain for procedural name and string generation. It supports training from JSON datasets, saving/loading pretrained models, and provides detailed statistics.

**Use cases:**

* Procedural name generation for NPCs, places, items
* Dynamic content generation in games
* Automatic generation of linguistically consistent strings
* Reusable model creation from datasets

## Installation

1. Copy `MarkovNameGenerator.gd` to your Godot project directory
2. The class is immediately usable
3. No external dependencies required

## Dataset Format

Datasets must be JSON files containing an array of strings:

```json
[
  "Alexander",
  "Katherine",
  "Sebastian",
  "Isabella"
]
```

**Requirements:**

* Valid JSON array
* String values only
* At least 50 entries recommended for decent results

## Usage Example

### Training and generation

```gdscript
var gen = MarkovNameGenerator.new("res://datasets/")
if gen.load_dataset("sample_names"):
	gen.train(2)
	var name = gen.generate_name(12, 3)
	print("Generated:", name)
```

### Deterministic output

```gdscript
gen.set_seed(12345)
var name = gen.generate_name()
```

### Save and load model

```gdscript
gen.save_model("res://models/names.model")
# ...later
var gen2 = MarkovNameGenerator.new("res://datasets/")
gen2.load_model("res://models/names.model")
print(gen2.generate_name())
```

### Model statistics

```gdscript
var stats = gen.get_statistics()
print(stats)
# Output: { "n_gram_len": 2, "entries": 500, "unique_ngrams": 2187, ... }
```

## API Reference

### Class Definition

```gdscript
class_name MarkovNameGenerator
extends RefCounted
```

### Constructor

```gdscript
MarkovNameGenerator.new(dataset_path: String)
```

### Methods

#### Core

```gdscript
load_dataset(dataset_name: String) -> bool
```

Loads a JSON dataset from the given directory (omit `.json` extension).

```gdscript
train(n_gram_len: int = 2) -> void
```

Trains the Markov chain model.

```gdscript
generate_name(max_length: int = 12, min_length: int = 3) -> String
```

Generates a name based on the trained model.

```gdscript
is_trained() -> bool
```

Returns true if the model is trained or a model is loaded.

#### Model Persistence

```gdscript
save_model(file_path: String) -> bool
```

Saves the trained model to a `.model` file.

```gdscript
load_model(file_path: String) -> bool
```

Loads a previously saved model from file.

#### Utilities

```gdscript
set_seed(seed: int) -> void
```

Sets the random seed for deterministic output.

```gdscript
reset() -> void
```

Clears internal state, dataset, and model.

```gdscript
get_statistics() -> Dictionary
```

Returns model statistics such as dataset size, n-gram count, average entry length, etc.

### Properties

| Property   | Type                    | Description                        |
| ---------- | ----------------------- | ---------------------------------- |
| `path`     | `String`                | Dataset directory path             |
| `chain`    | `Dictionary`            | N-gram transition dictionary       |
| `n_length` | `int`                   | Current n-gram order               |
| `starters` | `Array`                 | Valid sequence starters            |
| `dataset`  | `Array`                 | Loaded dataset                     |
| `rng`      | `RandomNumberGenerator` | Internal random generator instance |

## N-gram Order Effects

| Order | Coherence | Creativity | Complexity |
| ----- | --------- | ---------- | ---------- |
| 1     | Low       | High       | Minimal    |
| 2     | Good      | Moderate   | Low        |
| 3     | High      | Low        | Medium     |
| 4+    | Very High | Very Low   | High       |

## Performance

### Complexity

* **Memory:** O(n × m × k)
* **Training:** O(n × m × k)
* **Generation:** O(l)

### Average timings

```
Small (100 names, n=2):     ~1ms
Medium (500 names, n=2):    ~5ms
Large (2000 names, n=3):    ~50ms
generate_name(12):          ~0.2ms
```

## Troubleshooting

| Issue             | Cause                          | Solution                             |
| ----------------- | ------------------------------ | ------------------------------------ |
| Empty output      | Insufficient training data     | Add more entries to the dataset      |
| Identical output  | Fixed seed used                | Use `rng.randomize()` or change seed |
| JSON parse error  | Malformed dataset              | Validate JSON syntax                 |
| High memory usage | Large dataset or high n-gram   | Reduce n-gram size or dataset        |
| Load failed       | File not found or incompatible | Check file path and format           |

## License

MIT License — free use and modification with attribution.

---

> Last updated: v1.1.0 — added support for persistent models, internal statistics, and advanced n-grams
