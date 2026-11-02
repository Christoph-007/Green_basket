const mongoose = require('mongoose');

// One record per merchant CSV bulk upload, shown as "upload history" in the app
const bulkUploadLogSchema = new mongoose.Schema({
    merchant: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', required: true, index: true },
    fileName: String,
    totalRows: { type: Number, default: 0 },
    successCount: { type: Number, default: 0 },
    errorCount: { type: Number, default: 0 },
    // First few row errors, so the merchant can fix the CSV
    errors: [{ row: Number, error: String }],
    status: { type: String, enum: ['completed', 'partial', 'failed'], default: 'completed' }
}, { timestamps: true, suppressReservedKeysWarning: true });

module.exports = mongoose.model('BulkUploadLog', bulkUploadLogSchema);
