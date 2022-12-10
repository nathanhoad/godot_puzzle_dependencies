@tool
extends Node


static func create_color_icon(color: Color, size: Vector2) -> Texture:
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	image.fill_rect(Rect2(0, 0, size.x, size.y), color)
	return ImageTexture.create_from_image(image)
