extends Control
class_name SpendingGraph

# Graph data
var spending_points: Array[Vector2] = [] # (day, cumulative_spending)
var cash_points: Array[Vector2] = [] # (day, current_cash_balance)

# Graph dimensions
var margin_left: int = 80
var margin_right: int = 40
var margin_top: int = 40
var margin_bottom: int = 60
var graph_width: float
var graph_height: float

# Axis scaling
var max_day: int = 0
var max_amount: float = 0.0
var day_increment: int = 3
var amount_increment: float = 10.0

# Tooltip
var tooltip_label: Label
var hovered_point: Vector2 = Vector2(-1, -1)

func _ready():
	# Find tooltip label (parent's sibling)
	var parent = get_parent()
	if parent and parent.has_node("TooltipLabel"):
		tooltip_label = parent.get_node("TooltipLabel")
		tooltip_label.visible = false

func build_graph_data(transaction_history: Array):
	# Reset data
	spending_points.clear()
	cash_points.clear()
	
	# Sort by day (oldest first for graph)
	var sorted_transactions = transaction_history.duplicate()
	sorted_transactions.sort_custom(func(a, b): return a["day"] < b["day"])
	
	var cumulative_spending: float = 0.0
	var current_balance: float = 150.0 # Starting Cash
	max_day = 0
	max_amount = 150.0 # Start with at least $150 for scaling
	
	# Initial point at Day 0
	cash_points.append(Vector2(0, current_balance))
	
	# Build cumulative points
	for entry in sorted_transactions:
		var day = entry["day"]
		var amount = float(entry["amount"])
		
		if day > max_day:
			max_day = day
		
		# Update Cash Balance for every transaction
		current_balance += amount
		cash_points.append(Vector2(day, current_balance))
		if current_balance > max_amount:
			max_amount = current_balance
		
		if amount < 0:
			# Spending (negative)
			cumulative_spending += abs(amount)
			spending_points.append(Vector2(day, cumulative_spending))
			if cumulative_spending > max_amount:
				max_amount = cumulative_spending
	
	# Calculate increments based on max values
	if max_day > 0:
		if max_day <= 7:
			day_increment = 1
		elif max_day <= 21:
			day_increment = 3
		elif max_day <= 49:
			day_increment = 7
		else:
			day_increment = 14
	
	if max_amount > 0:
		if max_amount <= 50:
			amount_increment = 10.0
		elif max_amount <= 200:
			amount_increment = 25.0
		elif max_amount <= 500:
			amount_increment = 50.0
		else:
			amount_increment = 100.0
	
	queue_redraw()

func _draw():
	if spending_points.is_empty() and cash_points.is_empty():
		# Draw "No data" message
		draw_string(
			get_theme_default_font(),
			Vector2(size.x / 2 - 100, size.y / 2),
			"No transaction data yet",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			24,
			Color(0.7, 0.7, 0.7)
		)
		return
	
	# Calculate graph area
	graph_width = size.x - margin_left - margin_right
	graph_height = size.y - margin_top - margin_bottom
	
	if graph_width <= 0 or graph_height <= 0:
		return
	
	# Draw axes
	draw_axes()
	
	# Draw grid lines
	draw_grid()
	
	# Draw lines
	if spending_points.size() > 0:
		draw_spending_line()
	if cash_points.size() > 0:
		draw_cash_line()
	
	# Draw legend
	draw_legend()
	
	# Draw hovered point
	if hovered_point.x >= 0:
		draw_point(hovered_point)

func draw_axes():
	# Y-axis (left)
	draw_line(
		Vector2(margin_left, margin_top),
		Vector2(margin_left, size.y - margin_bottom),
		Color.WHITE,
		2.0
	)
	
	# X-axis (bottom)
	draw_line(
		Vector2(margin_left, size.y - margin_bottom),
		Vector2(size.x - margin_right, size.y - margin_bottom),
		Color.WHITE,
		2.0
	)
	
	# Axis labels
	draw_string(
		get_theme_default_font(),
		Vector2(size.x / 2 - 20, size.y - 10),
		"Days",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		18,
		Color.WHITE
	)

func draw_grid():
	# Prevent division by zero
	if max_day <= 0 or max_amount <= 0:
		return
	
	# Vertical grid lines (days)
	var day = 0
	while day <= max_day:
		var x = margin_left + (float(day) / float(max_day)) * graph_width
		draw_line(
			Vector2(x, margin_top),
			Vector2(x, size.y - margin_bottom),
			Color(0.3, 0.3, 0.3),
			1.0
		)
		
		# Day label
		var label_pos = Vector2(x - 10, size.y - margin_bottom + 25)
		draw_string(
			get_theme_default_font(),
			label_pos,
			str(day),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			18,
			Color.WHITE
		)
		
		day += day_increment
		if day_increment == 0:
			break # Safety
	
	# Horizontal grid lines (amounts)
	var amount = 0.0
	while amount <= max_amount:
		var y = size.y - margin_bottom - (amount / max_amount) * graph_height
		draw_line(
			Vector2(margin_left, y),
			Vector2(size.x - margin_right, y),
			Color(0.3, 0.3, 0.3),
			1.0
		)
		
		# Amount label
		var label_pos = Vector2(5, y + 5)
		draw_string(
			get_theme_default_font(),
			label_pos,
			"$" + str(int(amount)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)
		
		amount += amount_increment
		if amount_increment == 0:
			break # Safety

func draw_spending_line():
	# Prevent division by zero
	if max_day <= 0 or max_amount <= 0:
		return
	
	var points = PackedVector2Array()
	for point in spending_points:
		var x = margin_left + (point.x / float(max_day)) * graph_width
		var y = size.y - margin_bottom - (point.y / max_amount) * graph_height
		points.append(Vector2(x, y))
	
	if points.size() >= 2:
		draw_polyline(points, Color(1.0, 0.4, 0.4), 3.0)
	
	# Draw points
	for point in points:
		draw_circle(point, 5.0, Color(1.0, 0.4, 0.4))

func draw_cash_line():
	# Prevent division by zero
	if max_day <= 0 or max_amount <= 0:
		# Special case for Day 0 starting point if no transactions yet
		if cash_points.size() > 0:
			var x = margin_left
			var y = size.y - margin_bottom - (cash_points[0].y / 150.0 if max_amount == 0 else cash_points[0].y / max_amount) * graph_height
			draw_circle(Vector2(x, y), 5.0, Color(0.4, 1.0, 0.4))
		return
	
	var points = PackedVector2Array()
	for point in cash_points:
		var x = margin_left + (point.x / float(max_day)) * graph_width
		var y = size.y - margin_bottom - (point.y / max_amount) * graph_height
		points.append(Vector2(x, y))
	
	if points.size() >= 2:
		draw_polyline(points, Color(0.4, 1.0, 0.4), 3.0)
	
	# Draw points
	for point in points:
		draw_circle(point, 5.0, Color(0.4, 1.0, 0.4))

func draw_legend():
	# Legend background
	var legend_x = size.x - margin_right - 150
	var legend_y = margin_top + 10
	
	# Spending legend
	draw_circle(Vector2(legend_x, legend_y + 10), 6.0, Color(1.0, 0.4, 0.4))
	draw_string(
		get_theme_default_font(),
		Vector2(legend_x + 15, legend_y + 15),
		"Spending",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(1.0, 0.4, 0.4)
	)
	
	# Cash legend
	draw_circle(Vector2(legend_x, legend_y + 35), 6.0, Color(0.4, 1.0, 0.4))
	draw_string(
		get_theme_default_font(),
		Vector2(legend_x + 15, legend_y + 40),
		"Current Cash",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.4, 1.0, 0.4)
	)

func draw_point(pos: Vector2):
	draw_circle(pos, 8.0, Color.YELLOW)
	draw_circle(pos, 8.0, Color.WHITE, false, 2.0)

func _input(event):
	if not visible or not is_visible_in_tree():
		return
	if event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		check_hover(mouse_pos)

func check_hover(mouse_pos: Vector2):
	# Prevent division by zero
	if max_day <= 0 or max_amount <= 0:
		hovered_point = Vector2(-1, -1)
		if tooltip_label:
			tooltip_label.visible = false
		return
	
	# Calculate graph dimensions if not set
	graph_width = size.x - margin_left - margin_right
	graph_height = size.y - margin_top - margin_bottom
	
	if graph_width <= 0 or graph_height <= 0:
		hovered_point = Vector2(-1, -1)
		if tooltip_label:
			tooltip_label.visible = false
		return
	
	# Check if mouse is over graph area
	if mouse_pos.x < margin_left or mouse_pos.x > size.x - margin_right:
		hovered_point = Vector2(-1, -1)
		if tooltip_label:
			tooltip_label.visible = false
		return
	
	if mouse_pos.y < margin_top or mouse_pos.y > size.y - margin_bottom:
		hovered_point = Vector2(-1, -1)
		if tooltip_label:
			tooltip_label.visible = false
		return
	
	# Find nearest point
	var nearest_point = Vector2(-1, -1)
	var nearest_dist = 999999.0
	var nearest_data: Vector2 = Vector2(-1, -1)
	var is_spending: bool = false
	
	# Check spending points
	for point_data in spending_points:
		var x = margin_left + (point_data.x / float(max_day)) * graph_width
		var y = size.y - margin_bottom - (point_data.y / max_amount) * graph_height
		var point = Vector2(x, y)
		var dist = mouse_pos.distance_to(point)
		
		if dist < 25.0 and dist < nearest_dist:
			nearest_dist = dist
			nearest_point = point
			nearest_data = point_data
			is_spending = true
	
	# Check cash points
	for point_data in cash_points:
		var x = margin_left + (point_data.x / (float(max_day) if max_day > 0 else 1.0)) * graph_width
		var y = size.y - margin_bottom - (point_data.y / (max_amount if max_amount > 0 else 1.0)) * graph_height
		var point = Vector2(x, y)
		var dist = mouse_pos.distance_to(point)
		
		if dist < 25.0 and dist < nearest_dist:
			nearest_dist = dist
			nearest_point = point
			nearest_data = point_data
			is_spending = false
	
	if nearest_point.x >= 0 and tooltip_label:
		hovered_point = nearest_point
		var type_str = "Spent" if is_spending else "Cash"
		tooltip_label.text = "Day %d\n%s: $%.0f" % [int(nearest_data.x), type_str, nearest_data.y]
		tooltip_label.position = nearest_point + Vector2(15, -50)
		tooltip_label.visible = true
	else:
		hovered_point = Vector2(-1, -1)
		if tooltip_label:
			tooltip_label.visible = false
	
	queue_redraw()
