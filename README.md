
# MarkovNameGenerator

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.0+-blue?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-Ready-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen)

*Character-level Markov chain implementation for procedural name generation in GDScript*

</div>

## Overview

**MarkovNameGenerator** is a GDScript implementation of a character-level Markov chain designed for procedural name generation. The class analyzes character sequence patterns in training datasets to build probabilistic models for generating statistically similar output strings.

**Applications:**
- Procedural name generation for NPCs, locations, and entities
- Dynamic content creation for games and interactive applications
- Automated text generation following learned linguistic patterns
- Randomized content with controllable stylistic coherence

## Installation

1. Copy `MarkovNameGenerator.gd` to your project's script directory
2. The class is immediately available for instantiation
3. No external dependencies or additional configuration required

## Dataset Specification

Training datasets must be provided as JSON files containing arrays of strings:

```json
[
  "Alexander",
  "Katherine",
  "Sebastian",
  "Isabella"
]
```

**Requirements:**
- Valid JSON array format
- String elements only
- Minimum 50 samples recommended for statistical significance

## Implementation

### Basic Implementation

```gdscript
var generator = MarkovNameGenerator.new("res://datasets/")

if generator.load_dataset("sample_names"):
    generator.train(2)  # Configure n-gram order
    
    var generated_name = generator.generate_name(12,3)  # Max length parameter, Min length parameter
    print("Generated: ", generated_name)
else:
    push_error("Dataset loading failed")
```

### Deterministic Output

```gdscript
generator.set_seed(12345)
var name = generator.generate_name()  # Reproducible output
```

## N-gram Order Analysis

The n-gram order parameter controls the length of character sequences analyzed during training, directly affecting output characteristics:

| Order | Sequence Type | Coherence | Creativity | Computational Cost |
|-------|---------------|-----------|------------|-------------------|
| 1 | Unigram | Low | High | Minimal |
| 2 | Bigram | Balanced | Moderate | Low |
| 3 | Trigram | High | Low | Moderate |
| 4+ | Higher-order | Maximum | Minimal | High |

### Statistical Behavior

- **Order 1**: High entropy, minimal pattern constraints
- **Order 2**: Optimal balance for most applications, maintains phonetic coherence
- **Order 3+**: Increased pattern fidelity, potential for training data reproduction

```gdscript
# Low coherence, high variance
generator.train(1)

# Recommended: balanced statistical properties  
generator.train(2)

# High coherence, low variance
generator.train(3)
```

## Advanced Usage

### Multi-Dataset Implementation

```gdscript
	var people_name_generator = MarkovNameGenerator.new("res://datasets/")
	people_name_generator.load_dataset("people_names")
	people_name_generator.train()
	
	var stars_name_generator = MarkovNameGenerator.new("res://datasets/")
	stars_name_generator.load_dataset("star_names")
	stars_name_generator.train()
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
Initializes the generator with the specified dataset directory path.

**Parameters:**
- `dataset_path`: File system path to directory containing JSON datasets

### Methods

#### Core Functionality

```gdscript
load_dataset(dataset_name: String) -> bool
```
Loads and parses a JSON dataset file.

**Parameters:**
- `dataset_name`: Filename without extension

**Returns:** Boolean indicating load success

---

```gdscript
train(n_gram_len: int = 2) -> void
```
Constructs the Markov chain from loaded dataset.

**Parameters:**
- `n_gram_len`: N-gram sequence length (default: 2)

---

```gdscript
generate_name(max_length: int = 12) -> String
```
Generates a new name using the trained model.

**Parameters:**
- `max_length`: Maximum character length for output

**Returns:** Generated name string

#### Utility Functions

```gdscript
set_seed(seed: int) -> void
```
Configures deterministic seed for reproducible generation.

```gdscript
is_trained() -> bool
```
Validates that the model has been trained and is ready for generation.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | Dataset directory path |
| `chain` | `Dictionary` | N-gram to character transition mappings |
| `n_length` | `int` | Current n-gram sequence length |
| `starters` | `Array` | Valid sequence starters for generation initialization |
| `dataset` | `Array` | Loaded training data |
| `rng` | `RandomNumberGenerator` | Internal randomization instance |



## Performance Considerations

- **Memory Usage**: O(n*m) where n is dataset size and m is average name length
- **Training Time**: O(n*m*k) where k is n-gram order
- **Generation Time**: O(l) where l is output length
- **Recommended Dataset Size**: 50-1000 samples for optimal performance/quality balance

## Testing Example

### Unit Test Example

```gdscript
func test_generator_basic_functionality():
    var gen = MarkovNameGenerator.new("res://test_data/")
    assert(gen.load_dataset("test_names"))
    
    gen.train(2)
    assert(gen.is_trained())
    
    var name = gen.generate_name(10)
    assert(name.length() > 0 and name.length() <= 10)
```


## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Empty generation | Insufficient training data | Increase dataset size (>25 samples) |
| Identical outputs | Deterministic seed reuse | Randomize seed or call `rng.randomize()` |
| JSON parse errors | Malformed dataset files | Validate JSON syntax and array structure |
| Memory usage | Large datasets with high n_length | Reduce n-gram n_length or dataset size |

## License

This project is licensed under the MIT License. See LICENSE file for complete terms.
