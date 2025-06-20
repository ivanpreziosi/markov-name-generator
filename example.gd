extends Node


func _ready()->void:

	# Instantiate 
	var stars_name_generator = MarkovNameGenerator.new()
	
	# set path where datasets are located
	stars_name_generator.set_dataset_path("res://addons/markov-name-generator/datasets")
	
	# stars_name_generator.set_seed(1) # you can fix the seed 
	stars_name_generator.load_dataset("star_names") # load dataset from specified folder. OMIT EXTENSION
	
	# train the model
	stars_name_generator.train()
	
	# print cool statistics
	print(stars_name_generator.get_statistics())
	
	#generate a batch of 20 names to test it out
	for _ii in 20:
		print(stars_name_generator.generate_name(12))
	
	# now save the pre-trained model
	if stars_name_generator.save_trained_model("res://addons/markov-name-generator/models/new_star_names_model.json"):
		print("Model saved successfully!")	
	
	# load back the pre-trained model in a new generator
	var another_stars_name_generator = MarkovNameGenerator.new()
	another_stars_name_generator.load_trained_model("res://addons/markov-name-generator/models/new_star_names_model.json")
	
	#generate a batch of 20 names to test the loaded model
	for _ii in 20:
		print(another_stars_name_generator.generate_name(12))