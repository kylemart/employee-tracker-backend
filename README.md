# employee-tracker-backend

COP4331C-17Fall 0001
Group 19

### Usage
  1. install [Docker](https://store.docker.com/editions/community/docker-ce-desktop-windows)
  2. download Project folders
  3. create `bin/secret.lua` with the following contents:
```Lua
return "CHANGE_ME"
```
  4. run `docker volume create postgres-data`
  5. run `docker-compose -f ./docker-compose.development.yml up --build`
  6. navigate to `http://localhost/EmployeeTracker`

### Routes

##### System

**POST** /login

**POST** /signup

##### Users

**GET** /user
```JSON
{
	"success": true,
	"result": [
		{
			"first_name": "",
			"email": "talbotwhite@gmail.com",
			"last_name": "",
			"id": 1
		},
		{
			"first_name": "",
			"email": "test@example.com",
			"last_name": "",
			"id": 2
		},
		{
			"first_name": "John",
			"email": "test2@example.com",
			"last_name": "Doe",
			"id": 3
		}
	]
}
```

**GET** /user/{USER_ID}
```JSON
{
	"success": true,
	"result": {
		"first_name": "John",
		"email": "test2@example.com",
		"last_name": "Doe",
		"id": 3
	}
}
```

##### Groups

**GET** /group

**GET** /group/{GROUP_ID}

##### Locations

**GET** /location/{USER_ID}

**POST** /location/report (Double x, Double y)
