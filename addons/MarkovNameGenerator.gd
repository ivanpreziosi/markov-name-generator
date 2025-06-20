# MarkovNameGenerator
# A GDScript class that implements a Markov chain-based
# name generator by analyzing existing name datasets
# to learn transition probabilities between character 
# sequences (n-grams). Once trained, the class can generate 
# new realistic names that follow statistical patterns in the 
# training dataset, using a probabilistic approach to create 
# believable variations of the original names.
extends RefCounted

# Should be instantiated from other scripts.
# You can also use it as a Global Singleton if you need only one instance
class_name MarkovNameGenerator

static var version := "0.0.1"

# String variable to store the file system path where dataset files are located
# This path will be used to construct full file paths when loading JSON datasets
# if left empty you can still load files by providing full path in load_dataset (no extension!!)
var path := ""

# Dictionary that stores the Markov chain relationships
# Key: n-gram string (sequence of characters of length 'n_length')
# Value: Array of possible characters that can follow this n-gram
# Example: {"th": ["e", "a", "i","e","$","e"], "he": ["r", " ", "n", "y"]}
var chain := {}

# Integer defining the length of character sequences (n-grams) used in the chain
# n_length = 2 means we will use 2-character sequences like "th", "he", "ar"
# Higher values create more coherent but less varied names
var n_length := 2

# Array containing n-grams that can start a name generation
# These are typically the first 'n_length' characters of training names
# Used to randomly select a starting point for name generation
var starters := []

# Array storing the original list of names loaded from the dataset
# Used during training to build the Markov chain relationships
var dataset := []

# Instance of Godot's random number generator for consistent randomization
# Using a dedicated RNG instance allows for seed control and reproducible results
var rng := RandomNumberGenerator.new()

# Constructor function that initializes the generator with a dataset directory path
# @param dataset_path: String path to the folder containing JSON dataset files
func _init():
	# Initialize the random number generator with a time-based seed
	# This ensures different random sequences each time the program runs
	rng.randomize()

# Store the provided path for later use when loading dataset files
func set_dataset_path(data_path:String):
	path = data_path
	
# Sets a specific seed for the random number generator
# @param seed: Integer seed value for deterministic random number generation
# Useful for testing, debugging, or when reproducible results are needed
func set_seed(seed: int) -> void:
	rng.seed = seed

# Checks if the Markov chain has been trained and is ready for name generation
# @return: Boolean indicating whether both starters and chain contain data
# A trained generator must have at least one starter n-gram and chain relationships
func is_trained() -> bool:
	return not starters.is_empty() and not chain.is_empty()

# Loads a JSON dataset file and parses it into the dataset array
# @param dataset_name: String name of the JSON file (without .json extension)
# @return: Boolean indicating success or failure of the loading operation
func load_dataset(dataset_name) -> bool:
	# check dataset_name
	if dataset_name.is_empty():
		push_error("Dataset name cannot be empty")
		return false
	
	var full_path = path + dataset_name + ".json"
	if not FileAccess.file_exists(full_path):
		push_error("Dataset file not found: " + full_path)
		return false
	
	# Attempt to open the JSON file in read mode using the stored path
	var file = FileAccess.open(path + dataset_name + ".json", FileAccess.READ)
	
	# Check if file was successfully opened
	if file != null:
		# Read the entire file content as a string
		var file_content: String = file.get_as_text()
		# Close the file handle to free system resources
		file.close()
		
		# Parse the JSON string into a Godot Array
		var parsed: Array = JSON.parse_string(file_content)
		
		# Check if JSON parsing was successful
		if parsed == null:
			# Return false if JSON was malformed or empty
			return false
		else:
			# Store the parsed array as our training dataset
			dataset = parsed
			return true
	else:
		# Return false if file couldn't be opened (doesn't exist, no permissions, etc.)
		push_error("Can't open file: " + full_path)
		return false

# Trains the Markov chain using the loaded dataset
# @param n_gram_len: Integer length of n-grams to use (default: 2)
# This function analyzes the dataset and builds probability chains for name generation
func train(n_gram_len: int = 2) -> void:
	# n_gram_len must be at least 1
	if n_gram_len < 1:
		push_error("n_gram_len must be at least 1")
		return
	
	# check if dataset has data in it!
	if dataset.is_empty():
		push_error("Empty dataset!")
		return
		
	# Set the n-gram length for this training session
	n_length = n_gram_len
	
	# Clear any existing training data to start fresh
	chain.clear()
	starters.clear()
	
	# Process each name in the dataset
	for raw_name in dataset:
		var name = raw_name.strip_edges().to_lower() # normalize name
		if name.length() < 2:  # Skip names too short
			continue
		
		# Add start (^) and end ($) markers, convert to lowercase for consistency
		# Example: "John" becomes "^john$"
		var padded = "^" + name.to_lower() + "$"
		
		# Extract all possible n-grams from the padded name
		# Loop through each position where an n-gram can start
		for i in range(padded.length() - n_length):
			# Extract the current n-gram (substring of length 'n_length')
			var key = padded.substr(i, n_length)
			# Get the character that follows this n-gram
			var next_char = padded[i + n_length]
			
			# If this is the first n-gram in the name, add it to starters
			# Starters are used to begin name generation
			if i == 0:
				starters.append(key)
			
			# Initialize the chain entry for this n-gram if it doesn't exist
			if not chain.has(key):
				chain[key] = []
			
			# Add the following character to the list of possibilities for this n-gram
			# This builds the probability distribution for character transitions
			chain[key].append(next_char)


func generate_name(max_length: int = 12, min_length: int = 3) -> String:
	var attempts = 0
	var max_attempts = 100
	while attempts < max_attempts:
		var name = _generate_single_name(max_length)
		if name.length() >= min_length:
			return name
		attempts += 1
	
	push_warning("Could not generate valid name after " + str(max_attempts) + " attempts")
	return _generate_single_name(max_length)  # fallback

# Generates a new name using the trained Markov chain
# @param max_length: Integer maximum length of generated name (default: 12)
# @return: String containing the generated name, properly capitalized
func _generate_single_name(max_length: int = 12) -> String:
	# Ensure the chain has been trained before attempting generation
	if not is_trained():
		push_error("Markov chain not trained.")
		return ""
	
	# Randomly select a starting n-gram from the available starters
	var current = starters[rng.randi_range(0, starters.size() - 1)]
	# Initialize the result with the starting n-gram
	var result = current
	
	# Continue generating characters until we hit a stopping condition
	while true:
		# Extract the last 'n_length' characters as the key for the next lookup
		# This sliding window approach maintains the n-gram sequence
		var key = result.substr(result.length() - n_length, n_length)
		
		# If no transitions exist for this n-gram, stop generation
		if not chain.has(key):
			break
		
		# Get all possible next characters for the current n-gram
		var options = chain[key]
		# Randomly select one of the possible next characters
		var next_char = options[rng.randi_range(0, options.size() - 1)]
		
		# Stop if reach maximum length
		if next_char == "$" or result.length() >= max_length:
			break
		
		
		# Append the selected character to continue building the name
		result += next_char
	
	# Remove the start marker (^) and capitalize the first letter
	# This produces a properly formatted name ready for use
	return result.trim_prefix("^").capitalize()

func get_statistics() -> Dictionary:
	return {
		"is_trained": is_trained(),
		"total_ngrams": chain.size(),
		"starters_count": starters.size(),
		"n_length": n_length,
		"dataset_size": dataset.size()
	}

# Save a trained model as a JSON text file
# @param filepath: String path of the saved file
# @return: Boolean indicating success or failure of the save operation
func save_trained_model(filepath: String) -> bool:
	# Check if model is trained
	if not is_trained():
		push_error("Cannot save untrained model. Train the model first.")
		return false
	
	# check filepath 
	if filepath.is_empty():
		push_error("Filepath cannot be empty")
		return false
	
	# Create data structure to save
	var save_data = {
		"n_length": n_length,
		"starters": starters,
		"chain": chain,
		"meta": {
			"dataset_size": dataset.size(),  # meta data
			"total_ngrams": chain.size(),  # meta data
			"version": version, #class version
			"timestamp": Time.get_unix_time_from_system(),  # creation timestamp
		}
	}
	
	# convert save_data to JSON
	var json_string = JSON.stringify(save_data)
	if json_string.is_empty():
		push_error("Failed to serialize model data to JSON")
		return false
	
	# check destination directory
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
	
	# write file
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open file for writing: " + filepath + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("Model saved successfully to: " + filepath)
	return true

# Load a pretrained model from JSON
# @param filepath: String full path from where to load the file
# @return: Boolean indicating success or failure of the load operation
func load_trained_model(filepath: String) -> bool:
	# Check file path 
	if filepath.is_empty():
		push_error("Filepath cannot be empty")
		return false
	
	# check file 
	if not FileAccess.file_exists(filepath):
		push_error("Model file not found: " + filepath)
		return false
	
	# Open and read file
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("Cannot open model file: " + filepath + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return false
	
	var file_content = file.get_as_text()
	file.close()
	
	if file_content.is_empty():
		push_error("Model file is empty: " + filepath)
		return false
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	if parse_result != OK:
		push_error("Failed to parse model file JSON: " + filepath + " (Error at line " + str(json.error_line) + ": " + json.error_string + ")")
		return false
	
	var loaded_data = json.data
	
	# check parsed data to be a Dictionary
	if not loaded_data is Dictionary:
		push_error("Invalid model file format: expected Dictionary")
		return false
	
	# check base structure
	var required_fields = ["n_length", "starters", "chain", "meta"]
	for field in required_fields:
		if not loaded_data.has(field):
			push_error("Missing required field in model file: " + field)
			return false
	
	# check for version
	if loaded_data.meta.has("version"):
		var file_version = loaded_data.meta["version"]
		if file_version != version:
			push_warning("Loading model with different version. Model version: {1} Library version: {0}".format([version,file_version]))
	
	# Validate data
	loaded_data["n_length"] = int(loaded_data["n_length"])
	if not loaded_data["n_length"] is int or loaded_data["n_length"] < 1:
		push_error("Invalid n_length in model file")
		return false
	
	if not loaded_data["starters"] is Array:
		push_error("Invalid starters data in model file")
		return false
	
	if not loaded_data["chain"] is Dictionary:
		push_error("Invalid chain data in model file")
		return false
	
	# load model data
	
	n_length = loaded_data["n_length"]
	starters = loaded_data["starters"].duplicate()  # prevent reference issues
	chain = loaded_data["chain"].duplicate(true)    # Deep copy Dictionary
		
	# Clear dataset to load a pre-trained model
	dataset.clear()
		
	# check loaded model
	if not is_trained():
		push_error("Loaded model appears to be invalid (empty starters or chain)")
		return false
		
	# Log info aggiuntive se disponibili
	if loaded_data.meta.has("timestamp"):
		var timestamp = loaded_data.meta["timestamp"]
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		print("Model loaded successfully from: " + filepath)
		print("Model created: " + str(datetime["year"]) + "-" + str(datetime["month"]) + "-" + str(datetime["day"]) + " " + str(datetime["hour"]) + ":" + str(datetime["minute"]))
	else:
		print("Model loaded successfully from: " + filepath)
	
	if loaded_data.meta.has("total_ngrams"):
		print("Total n-grams: " + str(loaded_data.meta["total_ngrams"]))
	
	if loaded_data.meta.has("dataset_size"):
		print("Original dataset size: " + str(loaded_data.meta["dataset_size"]))
		
	return true
		
	
		

# Helper method to get statistics of the current model
func get_model_statistics() -> Dictionary:
	return {
		"is_trained": is_trained(),
		"n_length": n_length,
		"total_ngrams": chain.size(),
		"starters_count": starters.size(),
		"dataset_size": dataset.size(),
		"average_transitions_per_ngram": _calculate_average_transitions()
	}

# Private helper method to calculate the average number of transitions for n-gram
func _calculate_average_transitions() -> float:
	if chain.is_empty():
		return 0.0
	
	var total_transitions = 0
	for key in chain:
		total_transitions += chain[key].size()
	
	return float(total_transitions) / float(chain.size())
