extends Node

@export var base_url:String = "http://127.0.0.1:8090"

signal request_completed(err:Error, method:String, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray)

var _http_req:HTTPRequest:
	get:
		if _http_req == null:
			_http_req = HTTPRequest.new()
			add_child(_http_req)
			_http_req.set_tls_options(TLSOptions.client(null, ""))
		return _http_req

const names := ["Barton", "Glubeck", "Riftsmore", "flager", "tee-pee", "Totem pole", "ramshackle", "buskmuster"]
func _ready():
	var score := randi_range(15, 347)
	var name := names.pick_random()
	print ("POST: Name=%s Score=%d" % [name, score])
	request_completed.connect(
		func(err,m,r,rc,h,b):
			if err != OK:
				print(err)
			else:
				var response_string = b.get_string_from_utf8()
				print(response_string)
	, CONNECT_ONE_SHOT
	)
	await post_request("/api/collections/scores/records", {"score": score, "name": name}).request_completed
	
	request_completed.connect(
		func(err,m,r,rc,h,b):
			if err != OK:
				print("Error in GET request: ", err)
				print_stack()
			else:
				print("GET completed successfully!")
				var response_string = b.get_string_from_utf8()
				print(response_string)
			, CONNECT_ONE_SHOT
		)
	await get_request("/api/collections/scores/records?sort=-score").request_completed
	#await get_request("/api/collections/scores/records").request_completed
	get_tree().quit()

# when calling this, you can await get_request().request_completed
func get_request(endpoint:String):
	var error = _http_req.request(base_url + endpoint)
	if error != OK:
		_on_request_error.call_deferred(error)
	else:
		_http_req.request_completed.connect(_on_get_req_complete, CONNECT_ONE_SHOT)
	return self

# when calling this, you can await post_request().request_completed
func post_request(endpoint: String, data: Dictionary):
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var error = _http_req.request(base_url + endpoint, headers, HTTPClient.METHOD_POST, json_data)

	if error != OK:
		_on_request_error.call_deferred(error)
	else:
		_http_req.request_completed.connect(_on_post_req_complete, CONNECT_ONE_SHOT)
	return self

func _on_get_req_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	request_completed.emit(OK, "GET", result, response_code, headers, body)
	
func _on_post_req_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	request_completed.emit(OK, "POST", result, response_code, headers, body)

func _on_request_error(err:Error): request_completed.emit(err, "", 0, 0, null, null)
	
func _on_request_complete(result:int, response_code:int, headers:PackedStringArray, body: PackedByteArray, method: String):
	if result == HTTPRequest.RESULT_SUCCESS:
		var response_string = body.get_string_from_utf8()
		print("Request " + method + " completed. Response code: ", response_code)
		print("Response body: ", response_string)

		# Optionally, parse JSON if the response is JSON
		if "application/json" in headers[0]: #Check header for json
			var json_result = JSON.parse_string(response_string)
			if json_result:
				print("Parsed JSON: ", json_result	)
			else:
				print("Invalid JSON response.")
	else:
		print("Request " + method + " failed. Result: ", result)
