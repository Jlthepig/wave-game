extends Button

func set_item(icon_tex: Texture2D, count: int):
	icon = icon_tex
	text = str(count)
	visible = true

func clear():
	icon = null
	text = ""
	visible = false
