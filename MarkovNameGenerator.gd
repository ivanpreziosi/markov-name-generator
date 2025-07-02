# MarkovNameGenerator
# A GDScript class that implements a Markov chain-based
# name generator by analyzing existing name datasets
# to learn transition probabilities between character 
# sequences (n-grams). Once trained, the class can generate 
# new, plausible names that reflect statistical patterns found 
# in the input dataset.
extends RefCounted

# Class should be instantiated from other scripts.
# Alternatively, can be made a Global Singleton if only one instance is required.
class_name MarkovNameGenerator

# Current version of the class (for tracking changes and compatibility)
static var version := "0.1.1"

# Path to the directory where the dataset files (JSON format) are stored.
# This path is prepended when loading datasets by name.
# If left empty, full paths must be used in `load_dataset`.
var path := ""

# The Markov chain structure:
# Key: an n-gram string (sequence of `n_length` characters)
# Value: Array of characters that have historically followed that n-gram
# Example: {"th": ["e", "a", "e"], "he": ["r", "n"]}
var chain := {}

# Length of the character n-grams used in training and generation.
# Increasing this leads to more coherent but less varied names.
var n_length := 2

# Array of starting n-grams, typically the first `n_length` characters
# of each training name. Used to initiate name generation.
var starters := []

# Raw dataset of names, as loaded from a JSON file.
# Used as the source for training the Markov chain.
var dataset := []

# Dedicated random number generator for consistent and seedable randomness.
# Allows reproducible name generation across runs when needed.
var rng := RandomNumberGenerator.new()

# Initializes the random number generator with a randomized seed.
# Called on object creation to ensure different output per session.
func _init():
	rng.randomize()

# Sets the path used to load dataset files.
# @param data_path: Path to the folder containing datasets.
func set_dataset_path(data_path: String):
	path = data_path

# Sets a fixed seed for the random number generator.
# Useful for generating deterministic and reproducible results.
# @param seed: Integer seed value.
func set_seed(seed: int) -> void:
	rng.seed = seed

# Checks whether the generator has been trained and is ready to generate names.
# @return: true if both `starters` and `chain` are populated.
func is_trained() -> bool:
	return not starters.is_empty() and not chain.is_empty()

# Loads a dataset from a JSON file.
# @param dataset_name: Name of the file (without `.json` extension).
# @return: true if successful, false otherwise.
func load_dataset(dataset_name: String) -> bool:
	if dataset_name.is_empty():
		push_error("Dataset name cannot be empty")
		return false

	var full_path = path + dataset_name + ".json"
	if not FileAccess.file_exists(full_path):
		push_error("Dataset file not found: " + full_path)
		return false

	var file = FileAccess.open(full_path, FileAccess.READ)
	if file != null:
		var file_content: String = file.get_as_text()
		file.close()

		var parsed: Array = JSON.parse_string(file_content)
		if parsed == null:
			push_error("Invalid JSON or empty dataset")
			return false
		else:
			dataset = parsed
			return true
	else:
		push_error("Can't open file: " + full_path)
		return false

# Trains the Markov chain using the loaded dataset.
# @param n_gram_len: Length of the n-grams to use in training (min 1).
func train(n_gram_len: int = 2) -> void:
	if n_gram_len < 1:
		push_error("n_gram_len must be at least 1")
		return

	if dataset.is_empty():
		push_error("Empty dataset!")
		return

	n_length = n_gram_len
	chain.clear()
	starters.clear()

	for raw_name in dataset:
		var name = raw_name.strip_edges().to_lower()
		if name.length() < 2:
			continue

		var padded = "^" + name + "$"
		for i in range(padded.length() - n_length):
			var key = padded.substr(i, n_length)
			var next_char = padded[i + n_length]

			if i == 0:
				starters.append(key)

			if not chain.has(key):
				chain[key] = []

			chain[key].append(next_char)

# Generates a valid name using the trained Markov chain.
# Attempts up to 100 times to generate a name above `min_length`.
# @param max_length: Maximum length of the name.
# @param min_length: Minimum acceptable name length.
# @return: A name string, or a fallback if constraints are not met.
func generate_name(max_length: int = 12, min_length: int = 3) -> String:
	var attempts = 0
	var max_attempts = 100
	while attempts < max_attempts:
		var name = _generate_single_name(max_length)
		if name.length() >= min_length:
			return name
		attempts += 1

	push_warning("Could not generate valid name after " + str(max_attempts) + " attempts")
	return _generate_single_name(max_length)

# Internal method that builds a name from the trained model.
# @param max_length: Maximum length of generated name.
# @return: A name string generated via the Markov process.
func _generate_single_name(max_length: int = 12) -> String:
	if not is_trained():
		push_error("Markov chain not trained.")
		return ""

	var current = starters[rng.randi_range(0, starters.size() - 1)]
	var result = current

	while true:
		var key = result.substr(result.length() - n_length, n_length)

		if not chain.has(key):
			break

		var options = chain[key]
		var next_char = options[rng.randi_range(0, options.size() - 1)]

		if next_char == "$" or result.length() >= max_length:
			break

		result += next_char

	return result.trim_prefix("^").capitalize()

# Saves the trained model (chain, starters, and metadata) to a JSON file.
# @param filepath: Full path where the model will be saved.
# @return: true if the operation succeeded, false otherwise.
func save_trained_model(filepath: String) -> bool:
	if not is_trained():
		push_error("Cannot save untrained model. Train the model first.")
		return false

	if filepath.is_empty():
		push_error("Filepath cannot be empty")
		return false

	var save_data = {
		"n_length": n_length,
		"starters": starters,
		"chain": chain,
		"meta": {
			"dataset_size": dataset.size(),
			"total_ngrams": chain.size(),
			"version": version,
			"timestamp": Time.get_unix_time_from_system(),
		}
	}

	var json_string = JSON.stringify(save_data)
	if json_string.is_empty():
		push_error("Failed to serialize model data to JSON")
		return false

	var dir_path = filepath.get_base_dir()
	if not dir_path.is_empty():
		if not DirAccess.dir_exists_absolute(dir_path):
			var dir_access = DirAccess.open("res://")
			if dir_access == null:
				push_error("Cannot access file system")
				return false

			var error = dir_access.make_dir_recursive(dir_path)
			if error != OK:
				push_error("Failed to create directory: " + dir_path + " (Error: " + str(error) + ")")
				return false

	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open file for writing: " + filepath + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return false

	file.store_string(json_string)
	file.close()

	print("Model saved successfully to: " + filepath)
	return true

# Loads a trained Markov model from a JSON file and restores its state.
# @param filepath: Full path to the saved JSON model file.
# @return: true if the model was loaded successfully.
func load_trained_model(filepath: String) -> bool:
	if filepath.is_empty():
		push_error("Filepath cannot be empty")
		return false

	if not FileAccess.file_exists(filepath):
		push_error("Model file not found: " + filepath)
		return false

	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("Cannot open model file: " + filepath)
		return false

	var content = file.get_as_text()
	file.close()

	var parsed: Dictionary = JSON.parse_string(content)
	if parsed == null:
		push_error("Failed to parse JSON from file: " + filepath)
		return false

	if not parsed.has("chain") or not parsed.has("starters") or not parsed.has("n_length"):
		push_error("Invalid model file structure: missing required keys.")
		return false

	chain = parsed["chain"]
	starters = parsed["starters"]
	n_length = parsed["n_length"]
	return true
