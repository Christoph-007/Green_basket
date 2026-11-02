const jwt = require('jsonwebtoken');
console.log(jwt.sign({ id: "66bba7b30cd0db1d418bc012", role: "admin" }, "your_jwt_secret"));
