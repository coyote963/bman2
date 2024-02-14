extends Node
class_name NameGen

var adjectives = [
	"Funny",
	"Boring",
	"Stinky",
	"Goofy",
	"Suspicious",
	"Gothic",
	"Scary"
]

var nouns = [
	"Coyote",
	"Man",
	"Computer",
	"Tree",
	"Guy",
	"Program",
	"Game",
	"Box",
	"Key",
	"Flag"
]

func generate_name():
	var a = adjectives.pick_random()
	var n = nouns.pick_random()
	var finalname = a+n
	return finalname
