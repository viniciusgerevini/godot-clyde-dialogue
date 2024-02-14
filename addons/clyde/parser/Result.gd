extends RefCounted

func ok(value):
	return {
		"is_ok": true,
		"is_err": false,
		"value": value,
		"error": null,
	}

func err(error):
	return {
		"is_ok": false,
		"is_err": true,
		"value": null,
		"error": error,
	}
