const express = require('express');
const router = express.Router();
const bulkController = require('../controllers/bulkOperationsController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');
const multer = require('multer');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

router.use(protect);
router.use(restrictTo('merchant'));

router.post('/products/bulk-upload', upload.single('file'), bulkController.bulkUploadProducts);
router.put('/products/bulk-update-price', bulkController.bulkUpdatePrice);
router.put('/products/bulk-update-stock', bulkController.bulkUpdateStock);
router.get('/products/export', bulkController.exportProducts);
router.get('/products/upload-history', bulkController.getUploadHistory);
router.get('/products/template', bulkController.getUploadTemplate);

module.exports = router;
