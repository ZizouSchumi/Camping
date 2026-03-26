extends GutTest

# Tests unitaires pour CampeurData et IDGenerator
# AC8 : création CampeurData, génération 3 IDs distincts, campeur_id non vide
# AC9 : zéro régression (tests existants non modifiés)

const IDGeneratorScript := preload("res://scripts/utils/id_generator.gd")
const CampeurDataScript := preload("res://scripts/data/campeur_data.gd")


func test_campeur_data_valide() -> void:
	var data := CampeurDataScript.new()
	data.campeur_id = "c_001"
	data.prenom = "Marcel"
	data.age = 45
	data.genre = "homme"
	data.date_arrivee = 0.0
	data.date_depart_prevue = 7.0
	assert_true(data.is_valid(), "CampeurData avec id et prenom doit être valide")


func test_campeur_data_invalide_si_vide() -> void:
	var data := CampeurDataScript.new()
	assert_false(data.is_valid(), "CampeurData vide doit être invalide")


func test_campeur_data_invalide_sans_prenom() -> void:
	var data := CampeurDataScript.new()
	data.campeur_id = "c_001"
	assert_false(data.is_valid(), "CampeurData sans prenom doit être invalide")


func test_campeur_data_invalide_sans_id() -> void:
	var data := CampeurDataScript.new()
	data.prenom = "Marcel"
	assert_false(data.is_valid(), "CampeurData sans campeur_id doit être invalide")


func test_id_generator_ids_distincts() -> void:
	var id1 := IDGeneratorScript.generate_campeur_id()
	var id2 := IDGeneratorScript.generate_campeur_id()
	var id3 := IDGeneratorScript.generate_campeur_id()
	assert_ne(id1, id2, "IDs distincts : id1 ≠ id2")
	assert_ne(id2, id3, "IDs distincts : id2 ≠ id3")
	assert_ne(id1, id3, "IDs distincts : id1 ≠ id3")


func test_id_generator_format_c_prefix() -> void:
	var id := IDGeneratorScript.generate_campeur_id()
	assert_true(id.begins_with("c_"), "L'ID doit commencer par 'c_'")


func test_id_generator_format_longueur() -> void:
	var id := IDGeneratorScript.generate_campeur_id()
	# Format "c_NNN" = 5 caractères minimum
	assert_true(id.length() >= 5, "L'ID doit faire au moins 5 caractères (c_001)")


func test_id_generator_non_vide() -> void:
	var id := IDGeneratorScript.generate_campeur_id()
	assert_ne(id, "", "L'ID généré ne doit pas être vide")


func test_id_generator_incremental() -> void:
	var id1 := IDGeneratorScript.generate_campeur_id()
	var id2 := IDGeneratorScript.generate_campeur_id()
	var id3 := IDGeneratorScript.generate_campeur_id()
	var num1 := id1.substr(2).to_int()
	var num2 := id2.substr(2).to_int()
	var num3 := id3.substr(2).to_int()
	assert_eq(num2 - num1, 1, "IDs consécutifs : id2 = id1 + 1")
	assert_eq(num3 - num2, 1, "IDs consécutifs : id3 = id2 + 1")
