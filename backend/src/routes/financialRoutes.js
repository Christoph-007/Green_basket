const express = require('express');
const router = express.Router();
const financialController = require('../controllers/financialController');
const adminReportController = require('../controllers/adminReportController');
const { protect, restrictTo, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// Merchant routes
router.get('/merchants/summary', restrictTo('merchant'), financialController.getMerchantFinancialSummary);
router.get('/merchants/transactions', restrictTo('merchant'), financialController.getMerchantTransactions);
router.get('/merchants/earnings', restrictTo('merchant'), financialController.getMerchantEarnings);
router.get('/merchants/payouts', restrictTo('merchant'), financialController.getMerchantPayouts);
router.post('/merchants/request-payout', restrictTo('merchant'), financialController.requestPayout);
router.get('/payouts/:id', financialController.getPayoutById);

// Admin routes
router.get('/admin/payouts', isAdmin, financialController.getAllPayouts);
router.get('/admin/payouts/export', isAdmin, adminReportController.exportPayouts);
router.post('/admin/payouts/generate', isAdmin, financialController.generatePayouts);
router.post('/admin/payouts/:id/process', isAdmin, financialController.processPayout);
router.patch('/admin/payouts/:id/hold', isAdmin, financialController.holdReleasePayout);
router.get('/admin/reports/financial', isAdmin, financialController.getFinancialReports);
router.get('/admin/reports/statement', isAdmin, financialController.getMonthlyFinancials);
router.get('/admin/reports/gst', isAdmin, financialController.getGSTReport);
router.get('/admin/reports/revenue-orders', isAdmin, financialController.getRevenueOrders);
router.get('/admin/settings/commission', isAdmin, financialController.getCommissionSettings);
router.put('/admin/settings/commission', isAdmin, financialController.updateCommissionSettings);

module.exports = router;
