# employee-tracker-backend

COP4331C-17Fall 0001
Group 19

# Usage
  1. install [Docker](https://store.docker.com/editions/community/docker-ce-desktop-windows)
  2. download Project folders
  3. create `bin/secret.lua` with the following contents:
```Lua
return "YOUR_SECRET_HERE"
```
  4. run `docker volume create postgres-data`
  5. run `docker-compose up`
  6. navigate to `http://localhost/EmployeeTracker`
