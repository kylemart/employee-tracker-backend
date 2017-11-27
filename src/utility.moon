import yield_error from require("lapis.application")

utility = {}

utility.existsIn = (arr, elem) ->
	for v in *arr
		return true if v == elem
	return false

utility.insertIfNotExistsIn = (arr, elem) ->
	unless existsIn(arr, elem)
		arr[#arr + 1] = elem

utility.APIResult = (data, success) ->
	dataType = type(data)
	if dataType == "table"
		data.success = success
		yield_error(data)
	elseif dataType == "string"
		bin = {
			success: success
			message: data
		}
		yield_error(bin)
	else
		utility.APIFailure("Invalid result type of #{type data}")

utility.APISuccess = (data) -> utility.APIResult(data, true)
utility.APIFailure = (data) -> utility.APIResult(data, false)

return utility