const express = require('express');
const router = express.Router();
const homeController = require('../controllers/homeController');
const { optionalAuthenticate } = require('../middlewares/authMiddleware');

router.get('/customer-init', optionalAuthenticate, homeController.getInitialData);

module.exports = router;
