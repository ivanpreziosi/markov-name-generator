
# MarkovNameGenerator
![MarkovNameGenerator Logo](https://github.com/ivanpreziosi/markov-name-generator/blob/main/markov_name_generator_logo.png?raw=true)
A robust GDScript implementation of a Markov chain-based name generator for Godot 4.x. This class analyzes existing name datasets to learn statistical patterns and generates new, realistic names that follow the same linguistic characteristics as the training data.

## Features

- **Markov Chain Analysis**: Implements n-gram based character sequence analysis
- **Flexible N-gram Length**: Configurable sequence length for varying coherence vs. variety
- **JSON Dataset Support**: Easy loading and processing of name datasets
- **Model Persistence**: Save and load trained models for reuse
- **Deterministic Generation**: Seed-based random number generation for reproducible results
- **Quality Control**: Configurable minimum/maximum name lengths with retry logic
- **Comprehensive Statistics**: Detailed model metrics and training information
- **Error Handling**: Robust validation and error reporting throughout

## Installation

1. Copy `MarkovNameGenerator.gd` to your Godot project
2. The class extends `RefCounted` and uses `class_name`, making it available globally
3. Prepare your name datasets as JSON arrays (see Dataset Format below)

## Quick Start

```gdscript
# Create and configure generator
var generator = MarkovNameGenerator.new()
generator.set_dataset_path("res://data/names/")

# Load dataset and train model
if generator.load_dataset("fantasy_names"):
	generator.train(2)  # Use 2-character n-grams
	
	# Generate names
	for i in range(10):
		print(generator.generate_name())
```

## Dataset Format

Datasets should be JSON files containing arrays of strings:

```json
[
	"Gandalf",
	"Aragorn",
	"Legolas",
	"Gimli",
	"Boromir",
	"Frodo"
]
```

## API Reference

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | String | Base path for dataset files |
| `chain` | Dictionary | Markov chain transition probabilities |
| `n_length` | int | Length of n-grams (default: 2) |
| `starters` | Array | Valid n-grams for starting name generation |
| `dataset` | Array | Currently loaded dataset |
| `rng` | RandomNumberGenerator | Internal RNG instance |

## Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `version` | String | Library version ("0.1.0") |

### Methods

### *Constructor and Configuration*

#### new()
```gdscript
MarkovNameGenerator.new() -> MarkovNameGenerator
```
Creates a new generator instance with randomized seed.

---
#### set_dataset_path(data_path: String)
```gdscript
set_dataset_path(data_path: String) -> void
```
Sets the base path for dataset files.

---
#### set_seed(seed: int) 
```gdscript
set_seed(seed: int) -> void
```
Sets a specific seed for deterministic generation.

### *Dataset Management*

---
#### load_dataset(dataset_name: String)
```gdscript
load_dataset(dataset_name: String) -> bool
```
Loads a JSON dataset file. Returns `true` on success.

**Parameters:**
- `dataset_name`: Filename without .json extension

**Example:**
```gdscript
if generator.load_dataset("elvish_names"):
	print("Dataset loaded successfully")
else:
	print("Failed to load dataset")
```

### *Training*

---
#### train(n_gram_len: int = 2)
```gdscript
train(n_gram_len: int = 2) -> void
```
Trains the Markov chain on the loaded dataset.

**Parameters:**
- `n_gram_len`: Length of character sequences to analyze (1-5 recommended)

**N-gram Length Effects:**
- **1**: Maximum variety, less coherent
- **2**: Good balance (recommended)
- **3**: More coherent, less variety
- **4+**: High coherence, limited variety

### *Generation*
---

#### generate_name(max_length: int = 12, min_length: int = 3)
```gdscript
generate_name(max_length: int = 12, min_length: int = 3) -> String
```
Generates a new name using the trained model.

**Parameters:**
- `max_length`: Maximum characters in generated name
- `min_length`: Minimum characters (triggers retry logic)

**Returns:** Properly capitalized name string

---

#### _generate_single_name(max_length: int = 12)
```gdscript
_generate_single_name(max_length: int = 12) -> String
```
Internal method for single generation attempt without retry logic.

### Model Persistence
---

#### save_trained_model(filepath: String)
```gdscript
save_trained_model(filepath: String) -> bool
```
Saves the trained model to a JSON file.

**Parameters:**
- `filepath`: Full path including filename and extension

**Example:**
```gdscript
if generator.save_trained_model("user://models/fantasy_model.json"):
	print("Model saved successfully")
```
---

#### load_trained_model(filepath: String)
```gdscript
load_trained_model(filepath: String) -> bool
```
Loads a pre-trained model from a JSON file.

**Parameters:**
- `filepath`: Full path to the model file

**Example:**
```gdscript
var generator = MarkovNameGenerator.new()
if generator.load_trained_model("user://models/fantasy_model.json"):
	var name = generator.generate_name()
	print("Generated: " + name)
```

### Utility Methods
---

#### is_trained()
```gdscript
is_trained() -> bool
```
Checks if the model has been trained and is ready for generation.

---

#### get_model_statistics()
```gdscript
get_model_statistics() -> Dictionary
```
Returns detailed model statistics including transition averages.

**Returns:**
```gdscript
{
	"is_trained": bool,
	"n_length": int,
	"total_ngrams": int,
	"starters_count": int,
	"dataset_size": int,
	"average_transitions_per_ngram": float
}
```

## Advanced Usage

### Multiple Datasets

```gdscript
var generator = MarkovNameGenerator.new()
generator.set_dataset_path("res://data/")

# Load and combine multiple datasets
var datasets = ["human_names", "elvish_names", "dwarvish_names"]
var combined_data = []

for dataset_name in datasets:
	generator.load_dataset(dataset_name)
	combined_data.append_array(generator.dataset)

generator.dataset = combined_data
generator.train(2)
```

### Deterministic Generation

```gdscript
var generator = MarkovNameGenerator.new()
generator.set_seed(12345)  # Reproducible results

generator.load_dataset("names")
generator.train(2)

# These will always generate the same sequence
for i in range(5):
	print(generator.generate_name())
```

### Model Reuse

```gdscript
# Train once, save model
var trainer = MarkovNameGenerator.new()
trainer.set_dataset_path("res://data/")
trainer.load_dataset("large_dataset")
trainer.train(3)
trainer.save_trained_model("user://models/trained_model.json")

# Later, load pre-trained model
var generator = MarkovNameGenerator.new()
generator.load_trained_model("user://models/trained_model.json")

# Ready to generate immediately
var name = generator.generate_name()
```

### Custom Generation Parameters

```gdscript
# Generate longer names
var long_name = generator.generate_name(20, 8)

# Generate shorter names
var short_name = generator.generate_name(8, 2)

# Get statistics to tune parameters
var stats = generator.get_model_statistics()
print("Average transitions per n-gram: ", stats.average_transitions_per_ngram)
```

## Error Handling

The class provides comprehensive error handling with descriptive messages:

```gdscript
var generator = MarkovNameGenerator.new()

# This will trigger error messages
if not generator.load_dataset("nonexistent_file"):
	print("Dataset loading failed")

if not generator.save_trained_model(""):
	print("Invalid filepath")

# Check training status
if not generator.is_trained():
	print("Model not trained - call train() first")
```

## Performance Considerations

- **Dataset Size**: Larger datasets improve quality but increase training time
- **N-gram Length**: Higher values require more memory but may improve coherence
- **Model Size**: Trained models scale with dataset size and n-gram length
- **Generation Speed**: Typically very fast (< 1ms per name)

## File Structure

```
your_project/
├── MarkovNameGenerator.gd
├── data/
│   ├── fantasy_names.json
│   ├── modern_names.json
│   └── historical_names.json
└── models/
    ├── fantasy_trained.json
    └── modern_trained.json
```

## Requirements

- Godot 4.x
- JSON dataset files
- File system access for model persistence

## License

MIT License (see LICENCE.txt for full licence text)

